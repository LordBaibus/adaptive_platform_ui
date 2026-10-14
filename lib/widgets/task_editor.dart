import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/ph_time.dart';
import '../models/task.dart';
import '../services/task_controller.dart';
import 'dialogs.dart';
import 'month_calendar.dart';

/// "Create a Task" / edit form. Used full-screen on phones and inside the
/// detail pane on tablets and unfolded foldables.
class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    required this.controller,
    required this.onDone,
    this.task,
    this.embedded = false,
    this.onSaved,
  });

  final TaskController controller;

  /// Null when creating a new task.
  final Task? task;

  /// True inside a side pane (shows its own heading and stays open after save).
  final bool embedded;

  /// Called to close the editor (after delete, or after save when not embedded).
  final VoidCallback onDone;

  /// Called after a successful save when embedded.
  final ValueChanged<Task>? onSaved;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.task?.description ?? '');
  late DateTime _due = widget.task?.dueDate ?? phToday();
  // A category that is not one of the presets is a custom one.
  late bool _customCategory = _isCustom(widget.task?.category);
  late String _category = widget.task?.category ?? kDefaultCategory;
  late final TextEditingController _customController = TextEditingController(
    text: _isCustom(widget.task?.category) ? widget.task!.category : '',
  );

  static bool _isCustom(String? category) =>
      category != null && !kCategories.contains(category);
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;
  late int _progress = widget.task?.progress ?? 0;
  late int _hours = widget.task?.estimatedHours ?? 8;
  late bool _urgent = widget.task?.isUrgent ?? false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _setStatus(TaskStatus status) {
    setState(() {
      _status = status;
      if (status == TaskStatus.completed) _progress = 100;
      if (status == TaskStatus.todo) _progress = 0;
      if (status == TaskStatus.inProcess && (_progress == 0 || _progress == 100)) {
        _progress = 25;
      }
    });
  }

  bool _askedComplete = false;

  Future<void> _offerComplete() async {
    final name = _title.text.trim().isEmpty ? 'This task' : _title.text.trim();
    final yes = await confirmComplete(context, name);
    if (!mounted || !yes) return;
    setState(() {
      _status = TaskStatus.completed;
      _progress = 100;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      AdaptiveSnackBar.show(
        context,
        message: 'Please enter a title.',
        type: AdaptiveSnackBarType.warning,
      );
      return;
    }
    // No past dates (Philippine time). An existing task may keep its old date.
    final unchangedDate = widget.task != null && _due == widget.task!.dueDate;
    if (_due.isBefore(phToday()) && !unchangedDate) {
      AdaptiveSnackBar.show(
        context,
        message: 'Pick today or a later date.',
        type: AdaptiveSnackBarType.warning,
      );
      return;
    }
    final category = _customCategory ? _customController.text.trim() : _category;
    if (category.isEmpty) {
      AdaptiveSnackBar.show(
        context,
        message: 'Type a name for your custom category.',
        type: AdaptiveSnackBarType.warning,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final existing = widget.task;
      final Task saved;
      if (existing == null) {
        saved = await widget.controller.create(
          Task(
            id: '',
            title: title,
            description: _description.text.trim(),
            status: _status,
            progress: _progress,
            estimatedHours: _hours,
            dueDate: _due,
            category: category,
            isUrgent: _urgent,
            createdAt: phNow(),
          ),
        );
      } else {
        saved = await widget.controller.update(
          existing.copyWith(
            title: title,
            description: _description.text.trim(),
            status: _status,
            progress: _progress,
            estimatedHours: _hours,
            dueDate: _due,
            category: category,
            isUrgent: _urgent,
          ),
        );
      }
      if (!mounted) return;
      if (widget.embedded) {
        widget.onSaved?.call(saved);
        AdaptiveSnackBar.show(
          context,
          message: 'Saved',
          type: AdaptiveSnackBarType.success,
          duration: const Duration(seconds: 2),
        );
      } else {
        widget.onDone();
      }
    } catch (e) {
      if (mounted) showError(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;
    final confirmed = await confirmDelete(context, task.title);
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.controller.remove(task.id);
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, errorMessage(e));
      }
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.task == null;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (widget.embedded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    isNew ? 'Create a Task' : 'Edit Task',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              AdaptiveTextField(
                controller: _title,
                placeholder: 'Task title',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofocus: isNew && !widget.embedded,
              ),
              const SizedBox(height: 12),
              AdaptiveTextField(
                controller: _description,
                placeholder: 'Description (optional)',
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              _label('Due date  ·  ${formatDay(_due)}'),
              MonthCalendar(
                selected: _due,
                firstDate: phToday(),
                onSelected: (date) => setState(() => _due = date),
              ),
              _label('Category'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in kCategories)
                          _CategoryChip(
                            label: c,
                            selected: !_customCategory && c == _category,
                            onTap: () => setState(() {
                              _customCategory = false;
                              _category = c;
                            }),
                          ),
                        _CategoryChip(
                          label: 'Custom',
                          selected: _customCategory,
                          onTap: () => setState(() => _customCategory = true),
                        ),
                      ],
                    ),
                    if (_customCategory) ...[
                      const SizedBox(height: 12),
                      AdaptiveTextField(
                        controller: _customController,
                        placeholder: 'Type your own category',
                        maxLength: 24,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ],
                ),
              ),
              _label('Status'),
              AdaptiveSegmentedControl(
                labels: [for (final s in TaskStatus.values) s.label],
                selectedIndex: TaskStatus.values.indexOf(_status),
                onValueChanged: (i) => _setStatus(TaskStatus.values[i]),
                color: AppColors.orange,
                textColor: CupertinoColors.label.resolveFrom(context),
                selectedTextColor: CupertinoColors.white,
              ),
              if (_status == TaskStatus.inProcess) ...[
                _label('Progress  ·  $_progress%'),
                AdaptiveSlider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.orange,
                  onChanged: (v) {
                    final value = v.round();
                    setState(() => _progress = value);
                    if (value < 100) {
                      _askedComplete = false;
                    } else if (!_askedComplete) {
                      _askedComplete = true;
                      _offerComplete();
                    }
                  },
                ),
              ],
              _label('Estimated time  ·  $_hours Hrs'),
              AdaptiveSlider(
                value: _hours.toDouble(),
                min: 1,
                max: 200,
                divisions: 199,
                activeColor: AppColors.orange,
                onChanged: (v) => setState(() => _hours = v.round()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Mark as urgent', style: TextStyle(fontSize: 16)),
                  ),
                  AdaptiveSwitch(
                    value: _urgent,
                    onChanged: (value) => setState(() => _urgent = value == true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AdaptiveButton(
                label: _busy ? 'Saving…' : (isNew ? 'Create Task' : 'Save changes'),
                color: AppColors.orange,
                textColor: CupertinoColors.white,
                onPressed: _busy ? null : _save,
              ),
              if (!isNew) ...[
                const SizedBox(height: 12),
                AdaptiveButton(
                  label: 'Delete task',
                  style: AdaptiveButtonStyle.tinted,
                  color: CupertinoColors.destructiveRed,
                  textColor: CupertinoColors.destructiveRed,
                  onPressed: _busy ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected ? AppColors.orangeGradient : null,
          color: selected ? null : AppColors.track.resolveFrom(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? CupertinoColors.white : null,
          ),
        ),
      ),
    );
  }
}
