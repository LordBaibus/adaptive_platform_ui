import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

import '../core/app_icons.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/task.dart';
import '../services/task_controller.dart';
import '../widgets/progress_ring.dart';

/// Home tab: progress ring, status legend, "Create Daily Task" and the most
/// urgent unfinished task.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onOpen,
  });

  final TaskController controller;
  final VoidCallback onCreate;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context) {
    final urgent = controller.nextUrgent;
    final secondary = AppColors.secondaryText(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: controller.load),
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ProgressRing(
                        todo: controller.count(TaskStatus.todo),
                        inProcess: controller.count(TaskStatus.inProcess),
                        completed: controller.count(TaskStatus.completed),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LegendItem(
                            label: 'To Do',
                            count: controller.count(TaskStatus.todo),
                            color: CupertinoColors.systemGrey,
                          ),
                          _LegendItem(
                            label: 'In Process',
                            count: controller.count(TaskStatus.inProcess),
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          _LegendItem(
                            label: 'Completed',
                            count: controller.count(TaskStatus.completed),
                            color: AppColors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create Daily Task',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Plan your day, set a due date and track progress.',
                                style: TextStyle(fontSize: 13, color: secondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        AdaptiveButton.icon(
                          onPressed: onCreate,
                          icon: AppIcons.add,
                          color: AppColors.orange,
                          size: AdaptiveButtonSize.large,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _UrgentCard(task: urgent, onOpen: onOpen),
                    if (controller.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        controller.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $count',
          style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context)),
        ),
      ],
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.task, required this.onOpen});

  final Task? task;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final secondary = AppColors.secondaryText(context);

    if (t == null) {
      return GlassCard(
        child: Text(
          'Nothing urgent right now.',
          style: TextStyle(fontSize: 15, color: secondary),
        ),
      );
    }

    return GlassCard(
      onTap: () => onOpen(t),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Urgent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 6),
          Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(AppIcons.clock, size: 18, color: secondary),
              const SizedBox(width: 6),
              Text('${t.estimatedHours} Hrs', style: TextStyle(color: secondary)),
              const Spacer(),
              Text('Due ${formatDay(t.dueDate)}', style: TextStyle(color: secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
