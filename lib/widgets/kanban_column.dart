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
            notifier.moveTask(task, widget.title);

            if (widget.title == 'Done') {
              _confettiController.play();
            }
          },
          builder: (BuildContext context, List<dynamic> accepted,
              List<dynamic> rejected) {
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(8.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            _showAddTaskForm(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sortedTasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks',
                              style: TextStyle(color: Colors.grey),
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
            );
          },
        ),
        if (widget.title == 'Done')
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // towards the bottom of the screen
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

  void _showAddTaskForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      builder: (context) => AddTaskForm(
        addTaskHandler: (String title, String description, int priority) {
          final notifier = ref.read(taskListProvider.notifier);
          notifier.addTask(title, description, priority, widget.title);
        },
      ),
    );
  }
}
