import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import 'task_card.dart';
import 'add_task_form.dart';
import '../providers/task_provider.dart';

class KanbanColumn extends ConsumerStatefulWidget {
  final String title;
  final List<Task> tasks;

  const KanbanColumn({super.key, required this.title, required this.tasks});

  @override
  _KanbanColumnState createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn> {
  late ConfettiController _confettiController;
  bool _isHovered = false;

  static const double _headerHeight = 55.0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) {
        // sort Done tasks by completion time
        if (widget.title == 'Done') {
          final aTime = a.completedAt;
          final bTime = b.completedAt;

          // if both have completedAt, sort by most recent first
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
          // tasks with completedAt come before those without
          if (aTime != null) return -1;
          if (bTime != null) return 1;

          // if neither has completedAt, fall back to priority
          return b.priority.compareTo(a.priority);
        }

        // for other columns, sort by priority
        return b.priority.compareTo(a.priority);
      });

    return Stack(
      children: [
        DragTarget<Task>(
          onAccept: (Task task) {
            final notifier = ref.read(taskListProvider.notifier);

            bool shouldShowConfetti =
                widget.title == 'Done' && task.status != 'Done';

            notifier.moveTask(task, widget.title);

            if (shouldShowConfetti) {
              _confettiController.play();
            }
          },
          builder: (BuildContext context, List<dynamic> accepted,
              List<dynamic> rejected) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: _getColumnBorderColor(widget.title),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: sortedTasks.isEmpty
                            ? Center(
                                child: Text(
                                  'No tasks',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    8.0, _headerHeight + 8.0, 8.0, 8.0),
                                itemCount: sortedTasks.length,
                                itemBuilder: (context, index) {
                                  return TaskCard(
                                    key: ValueKey(sortedTasks[index].id),
                                    task: sortedTasks[index],
                                  );
                                },
                              ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11.0)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.04),
                                  ],
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.18),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (widget.title == 'Done' &&
                                      widget.tasks.isNotEmpty)
                                    _ArchiveButtonWidget(isHovered: _isHovered)
                                  else
                                    const SizedBox(width: 48),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        widget.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _isHovered = true),
                                    onExit: (_) =>
                                        setState(() => _isHovered = false),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: _isHovered
                                            ? _getButtonColor(
                                                widget.title, true)
                                            : _getButtonColor(
                                                widget.title, false),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          onTap: () =>
                                              _showAddTaskForm(context),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.title == 'Done')
          Positioned(
            left: 150,
            top: 200,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 10,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
      ],
    );
  }

  Color _getButtonColor(String title, bool isHovered) {
    return isHovered
        ? Colors.white.withOpacity(0.22)
        : Colors.white.withOpacity(0.12);
  }

  Color _getColumnBorderColor(String title) {
    return title == 'Focus'
        ? Colors.white.withOpacity(0.55)
        : Colors.white.withOpacity(0.18);
  }

  void _showAddTaskForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        final currentFilter = ref.read(taskFilterProvider);
        final defaultCategory =
            currentFilter == TaskFilter.work ? 'work' : 'life';

        return AddTaskForm(
          addTaskHandler: (String title, String description, int priority,
              DateTime? dueDate, String category) {
            final notifier = ref.read(taskListProvider.notifier);
            notifier.addTask(
                title, description, priority, widget.title, dueDate, category);
          },
          initialCategory: defaultCategory,
        );
      },
    );
  }
}

class _ArchiveButtonWidget extends ConsumerStatefulWidget {
  final bool isHovered;

  const _ArchiveButtonWidget({required this.isHovered});

  @override
  _ArchiveButtonWidgetState createState() => _ArchiveButtonWidgetState();
}

class _ArchiveButtonWidgetState extends ConsumerState<_ArchiveButtonWidget> {
  bool _isArchiveHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(taskFilterProvider);
    final category = currentFilter == TaskFilter.work ? 'work' : 'life';

    return MouseRegion(
      onEnter: (_) => setState(() => _isArchiveHovered = true),
      onExit: (_) => setState(() => _isArchiveHovered = false),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: _isArchiveHovered
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _confirmArchive(context, category),
            child: const Tooltip(
              message: 'Archive all done tasks',
              child: Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.archive,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Archive Done Tasks',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Archive all completed $category tasks?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final notifier = ref.read(taskListProvider.notifier);
              notifier.archiveAllDoneTasks(category);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
