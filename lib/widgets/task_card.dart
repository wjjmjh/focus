import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'add_task_form.dart';
import 'kanban_board.dart';

final ValueNotifier<Set<String>> _dragStateNotifier =
    ValueNotifier<Set<String>>({});

class TaskCard extends ConsumerStatefulWidget {
  final Task task;

  TaskCard({required this.task, Key? key})
      : super(key: key ?? ValueKey(task.id));

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  Timer? _timer;
  ValueNotifier<Duration>? _elapsedVN;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _elapsedVN = ValueNotifier<Duration>(_computeElapsed());
    if (_isFocused(widget.task)) _startTimer();
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasFocused = _isFocused(oldWidget.task);
    final isFocusedNow = _isFocused(widget.task);

    if (!wasFocused && isFocusedNow) {
      _elapsedVN?.value = _computeElapsed();
      _startTimer();
    } else if (wasFocused && !isFocusedNow) {
      _stopTimer();
      _elapsedVN?.value = _computeElapsed();
    } else if (isFocusedNow &&
        oldWidget.task.focusStartTime != widget.task.focusStartTime) {
      _elapsedVN?.value = _computeElapsed();
    } else if (oldWidget.task.timeSpent != widget.task.timeSpent) {
      _elapsedVN?.value = _computeElapsed();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _elapsedVN?.dispose();
    super.dispose();
  }

  static bool _isFocused(Task t) => t.status == 'Focus';

  Duration _computeElapsed() {
    final base = widget.task.timeSpent;
    final start = widget.task.focusStartTime;

    if (start == null || !_isFocused(widget.task)) return base;

    final now = DateTime.now();
    final extra = now.isAfter(start) ? now.difference(start) : Duration.zero;
    return base + extra;
  }

  void _tick() {
    _elapsedVN?.value = _computeElapsed();
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDone = task.status == 'Done';
    final priority = int.tryParse(task.priority) ?? 3;
    final isHighPriority = priority >= 4;
    final priorityColor = _priorityColor(priority, isDone);
    final dueColor = _dueDateColor(task.dueDate, isDone);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: _dragStateNotifier,
      builder: (context, draggingIds, _) {
        if (draggingIds.contains(task.id)) return const SizedBox.shrink();

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => _showEditTaskForm(context),
            child: LongPressDraggable<Task>(
              data: task,
              feedback: Material(
                color: Colors.transparent,
                child: _buildCard(
                    context, isDone, isHighPriority, priorityColor, dueColor),
              ),
              childWhenDragging: const SizedBox.shrink(),
              onDragStarted: () {
                _dragStateNotifier.value = {
                  ..._dragStateNotifier.value,
                  task.id
                };
                isDraggingGlobally.value = true;
                if (_isFocused(task)) {
                  _stopTimer();
                  ref
                      .read(taskListProvider.notifier)
                      .saveFocusTimeBeforeDrag(task);
                }
              },
              onDragEnd: (_) {
                isDraggingGlobally.value = false;
                dragPositionGlobally.value = null;
              },
              onDragCompleted: () {
                final newSet = Set<String>.from(_dragStateNotifier.value);
                newSet.remove(task.id);
                _dragStateNotifier.value = newSet;
                if (newSet.isEmpty) {
                  isDraggingGlobally.value = false;
                  dragPositionGlobally.value = null;
                }
              },
              onDraggableCanceled: (_, __) {
                final newSet = Set<String>.from(_dragStateNotifier.value);
                newSet.remove(task.id);
                _dragStateNotifier.value = newSet;
                if (newSet.isEmpty) {
                  isDraggingGlobally.value = false;
                  dragPositionGlobally.value = null;
                }
                if (_isFocused(task)) _startTimer();
              },
              child: _buildCard(
                  context, isDone, isHighPriority, priorityColor, dueColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDone,
    bool isHighPriority,
    Color priorityColor,
    Color dueColor,
  ) {
    final task = widget.task;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _isFocused(task)
                    ? Colors.green.shade400
                    : priorityColor.withOpacity(0.3),
                width: _isFocused(task) ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20.0,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 1.0,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isHighPriority)
                  Container(
                    width: 4.0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [priorityColor, priorityColor.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        bottomLeft: Radius.circular(12.0),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isHighPriority ? 12.0 : 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade100,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PriorityChip(
                                  priorityText: 'P${task.priority}',
                                  color: priorityColor,
                                ),
                                const SizedBox(width: 8.0),
                                GestureDetector(
                                  onTap: () => _confirmDelete(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.red.shade900.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade300,
                                      size: 16.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey.shade400,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            if (task.dueDate != null) ...[
                              _DueChip(dueDate: task.dueDate!, color: dueColor),
                              const Spacer(),
                            ],
                            if (task.focusStartTime != null ||
                                (_elapsedVN?.value ?? Duration.zero) >
                                    Duration.zero) ...[
                              if (task.dueDate == null) const Spacer(),
                              if (_elapsedVN != null) ...[
                                _TimerChip(
                                  isRunning: _isFocused(task),
                                  elapsedVN: _elapsedVN!,
                                  isDone: isDone,
                                ),
                                if (!isDone &&
                                    (_elapsedVN?.value ?? Duration.zero) >
                                        Duration.zero) ...[
                                  const SizedBox(width: 8.0),
                                  _ResetButton(
                                    onPressed: () =>
                                        _showResetConfirmation(context),
                                  ),
                                ],
                              ],
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _priorityColor(int p, bool isDone) {
    if (isDone) return Colors.grey.shade600;

    switch (p) {
      case 5:
        return Colors.redAccent.shade200;
      case 4:
        return Colors.orange.shade500;
      case 3:
        return Colors.blue.shade500;
      case 2:
        return Colors.green.shade500;
      case 1:
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade500;
    }
  }

  static Color _dueDateColor(DateTime? due, bool isDone) {
    if (due == null) return Colors.grey.shade400;
    if (isDone) return Colors.grey.shade400;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    final diff = d.difference(today).inDays;

    if (diff < 0) return Colors.red.shade400;
    if (diff == 0) return Colors.orange.shade400;
    if (diff == 1) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
        title: const Text(
          'Delete Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.white, width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
            onPressed: () async {
              await ref.read(taskListProvider.notifier).deleteTask(widget.task);
              if (mounted) Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
        title: const Text(
          'Reset Focus Time',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to reset the focus time for this task to zero?',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.white, width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset'),
            onPressed: () async {
              await ref
                  .read(taskListProvider.notifier)
                  .resetFocusTime(widget.task);
              if (mounted) Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  void _showEditTaskForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: AddTaskForm(
            addTaskHandler: (String title, String description, int priority,
                DateTime? dueDate) {
              final updatedTask = widget.task.copyWith(
                title: title,
                description: description,
                priority: priority.toString(),
                dueDate: dueDate,
                isDateDetected: dueDate != null,
              );
              ref.read(taskListProvider.notifier).updateTask(updatedTask);
            },
            initialTitle: widget.task.title,
            initialDescription: widget.task.description,
            initialPriority: int.tryParse(widget.task.priority) ?? 3,
            initialDueDate: widget.task.dueDate,
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priorityText;
  final Color color;
  const _PriorityChip({required this.priorityText, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1.0,
        ),
      ),
      child: Text(
        priorityText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  final DateTime dueDate;
  final Color color;
  const _DueChip({required this.dueDate, required this.color});

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: color, size: 12.0),
          const SizedBox(width: 4.0),
          Text(
            _fmt(dueDate),
            style: TextStyle(
                fontSize: 12.0, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final bool isRunning;
  final ValueNotifier<Duration> elapsedVN;
  final bool isDone;

  const _TimerChip({
    required this.isRunning,
    required this.elapsedVN,
    this.isDone = false,
  });

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = isDone ? Colors.grey.shade600 : Colors.green.shade400;
    final backgroundColor = isDone
        ? Colors.grey.shade800.withOpacity(0.15)
        : Colors.green.shade900.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: chipColor.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.play_circle_filled : Icons.timer,
            color: chipColor,
            size: 12.0,
          ),
          const SizedBox(width: 4.0),
          ValueListenableBuilder<Duration>(
            valueListenable: elapsedVN,
            builder: (_, d, __) => Text(
              _fmt(d),
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Colors.orange.shade400.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        child: Icon(
          Icons.refresh,
          color: Colors.orange.shade400,
          size: 12.0,
        ),
      ),
    );
  }
}
