import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'add_task_form.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;

  TaskCard({required this.task, Key? key})
      : super(key: key ?? ValueKey(task.id));

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  Timer? _timer;
  late Duration _elapsedTime;

  @override
  void initState() {
    super.initState();
    _elapsedTime = widget.task.timeSpent ?? Duration.zero;
    if (widget.task.status == 'Focus') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.status == 'Focus' && _timer == null) {
      _startTimer();
    } else if (widget.task.status != 'Focus' && _timer != null) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = (widget.task.timeSpent ?? Duration.zero) +
            DateTime.now()
                .difference(widget.task.focusStartTime ?? DateTime.now());
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.status == 'Done';

    return GestureDetector(
      onTap: () {
        _showEditTaskForm(context);
      },
      child: Draggable<Task>(
        data: widget.task,
        feedback: Material(
          color: Colors.transparent,
          child: _buildTaskCardContent(context, isDone),
        ),
        childWhenDragging: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 6.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        child: _buildTaskCardContent(context, isDone),
      ),
    );
  }

  Widget _buildTaskCardContent(BuildContext context, bool isDone) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          widget.task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.description,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            Text(
              'Priority: ${widget.task.priority}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
              ),
            ),
            if (widget.task.focusStartTime != null ||
                _elapsedTime > Duration.zero)
              Text(
                '${_formatDuration(_elapsedTime)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF20BC20),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade400),
          onPressed: () {
            _confirmDelete(context);
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await ref
                    .read(taskListProvider.notifier)
                    .deleteTask(widget.task);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskForm(BuildContext context) {
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
          final updatedTask = widget.task.copyWith(
            title: title,
            description: description,
            priority: priority.toString(),
          );
          ref.read(taskListProvider.notifier).updateTask(updatedTask);
        },
        initialTitle: widget.task.title,
        initialDescription: widget.task.description,
        initialPriority: int.parse(widget.task.priority),
      ),
    );
  }
}
