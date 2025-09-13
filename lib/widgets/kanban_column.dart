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
      ..sort((a, b) => b.priority.compareTo(a.priority));

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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.grey.shade900.withOpacity(0.7),
                      ],
                    ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getColumnGradient(widget.title),
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11.0)),
                        ),
                        child: Row(
                          children: [
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
                              onEnter: (_) => setState(() => _isHovered = true),
                              onExit: (_) => setState(() => _isHovered = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isHovered
                                      ? _getButtonColor(widget.title, true)
                                      : _getButtonColor(widget.title, false),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showAddTaskForm(context),
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
                      Expanded(
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
                                padding: const EdgeInsets.all(8.0),
                                itemCount: sortedTasks.length,
                                itemBuilder: (context, index) {
                                  return TaskCard(
                                    key: ValueKey(sortedTasks[index].id),
                                    task: sortedTasks[index],
                                  );
                                },
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

  List<Color> _getColumnGradient(String title) {
    switch (title) {
      case 'Backlog':
        return [
          Colors.purple.shade800,
          Colors.purple.shade900,
        ];
      case 'Ready':
        return [
          Colors.blue.shade800,
          Colors.blue.shade900,
        ];
      case 'Focus':
        return [
          Colors.red.shade800,
          Colors.red.shade900,
        ];
      case 'Done':
        return [
          Colors.green.shade800,
          Colors.green.shade900,
        ];
      default:
        return [
          Colors.grey.shade800,
          Colors.grey.shade900,
        ];
    }
  }

  Color _getButtonColor(String title, bool isHovered) {
    switch (title) {
      case 'Backlog':
        return isHovered ? Colors.purple.shade600 : Colors.purple.shade700;
      case 'Ready':
        return isHovered ? Colors.blue.shade600 : Colors.blue.shade700;
      case 'Focus':
        return isHovered ? Colors.red.shade600 : Colors.red.shade700;
      case 'Done':
        return isHovered ? Colors.green.shade600 : Colors.green.shade700;
      default:
        return isHovered ? Colors.grey.shade600 : Colors.grey.shade700;
    }
  }

  Color _getColumnBorderColor(String title) {
    switch (title) {
      case 'Backlog':
        return Colors.purple.shade700.withOpacity(0.5);
      case 'Ready':
        return Colors.blue.shade700.withOpacity(0.5);
      case 'Focus':
        return Colors.red.shade700.withOpacity(0.5);
      case 'Done':
        return Colors.green.shade700.withOpacity(0.5);
      default:
        return Colors.grey.shade700.withOpacity(0.5);
    }
  }

  void _showAddTaskForm(BuildContext context) {
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
      builder: (context) => AddTaskForm(
        addTaskHandler: (String title, String description, int priority,
            DateTime? dueDate) {
          final notifier = ref.read(taskListProvider.notifier);
          notifier.addTask(title, description, priority, widget.title, dueDate);
        },
      ),
    );
  }
}
