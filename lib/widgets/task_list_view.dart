import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

import '../core/app_icons.dart';
import '../core/app_theme.dart';
import '../models/task.dart';
import '../services/task_controller.dart';
import 'dialogs.dart';

/// "My Task": segmented filter plus a card per task with a progress bar.
class TaskListView extends StatefulWidget {
  const TaskListView({
    super.key,
    required this.controller,
    required this.onOpen,
    this.selectedId,
  });

  final TaskController controller;
  final ValueChanged<Task> onOpen;
  final String? selectedId;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  TaskStatus _filter = TaskStatus.inProcess;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.loading && controller.tasks.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }
    if (controller.error != null && controller.tasks.isEmpty) {
      return _Message(
        text: controller.error!,
        action: AdaptiveButton(
          label: 'Try again',
          color: AppColors.orange,
          onPressed: controller.load,
        ),
      );
    }

    final tasks = controller.byStatus(_filter);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: controller.load),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AdaptiveSegmentedControl(
              labels: [for (final s in TaskStatus.values) s.label],
              selectedIndex: TaskStatus.values.indexOf(_filter),
              onValueChanged: (i) => setState(() => _filter = TaskStatus.values[i]),
            ),
          ),
        ),
        if (tasks.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(text: 'No ${_filter.label.toLowerCase()} tasks.'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverList.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _TaskCard(
                task: tasks[index],
                selected: tasks[index].id == widget.selectedId,
                controller: controller,
                onOpen: widget.onOpen,
                parentContext: context,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.selected,
    required this.controller,
    required this.onOpen,
    required this.parentContext,
  });

  final Task task;
  final bool selected;
  final TaskController controller;
  final ValueChanged<Task> onOpen;

  /// Stays mounted while the card's popup menu closes, so dialogs and
  /// snack bars can still be shown after a menu choice.
  final BuildContext parentContext;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (parentContext.mounted) showError(parentContext, errorMessage(e));
    }
  }

  Future<void> _delete() async {
    if (!await confirmDelete(parentContext, task.title)) return;
    await _run(() => controller.remove(task.id));
  }

  @override
  Widget build(BuildContext context) {
    final completed = task.status == TaskStatus.completed;

    // Menu entries: label, icons, destructive flag and what they do.
    final entries = <({String label, String sf, IconData icon, bool danger, VoidCallback run})>[
      (
        label: 'Edit',
        sf: AppIcons.editSymbol,
        icon: AppIcons.edit,
        danger: false,
        run: () => onOpen(task),
      ),
      (
        label: completed ? 'Reopen' : 'Mark as completed',
        sf: AppIcons.doneSymbol,
        icon: AppIcons.done,
        danger: false,
        run: () => _run(() => controller.setStatus(
              task,
              completed ? TaskStatus.inProcess : TaskStatus.completed,
            )),
      ),
      (
        label: 'Delete',
        sf: AppIcons.deleteSymbol,
        icon: AppIcons.delete,
        danger: true,
        run: _delete,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.orange : Color(0x00000000),
          width: 1.5,
        ),
      ),
      child: GlassCard(
        onTap: () => onOpen(task),
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(AppIcons.clock, size: 16, color: AppColors.secondaryText(context)),
                        const SizedBox(width: 6),
                        Text(
                          '${task.estimatedHours} Hrs / ${task.spentHours} Hrs',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText(context),
                          ),
                        ),
                        if (task.isUrgent) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Urgent',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: AppProgressBar(value: task.progress / 100)),
                        const SizedBox(width: 12),
                        Text(
                          '${task.progress}%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AdaptivePopupMenuButton.icon<String>(
              icon: AppIcons.pick(AppIcons.kebabSymbol, AppIcons.kebab),
              size: 36,
              buttonStyle: PopupButtonStyle.plain,
              items: [
                for (final e in entries)
                  AdaptivePopupMenuItem<String>(
                    label: e.label,
                    icon: AppIcons.pick(e.sf, e.icon),
                    value: e.label,
                    isDestructive: e.danger,
                  ),
              ],
              onSelected: (index, item) => entries[index].run(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context)),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
