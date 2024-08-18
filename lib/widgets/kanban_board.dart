import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'kanban_column.dart';
import 'dart:async';

class KanbanBoard extends StatefulWidget {
  final List<Task> tasks;

  const KanbanBoard({Key? key, required this.tasks}) : super(key: key);

  @override
  _KanbanBoardState createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  late ScrollController _scrollController;
  bool _isTaskBeingDragged = false;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isTaskBeingDragged) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const scrollThreshold = 50.0;
    const scrollAmount = 30.0;

    if (details.globalPosition.dx < scrollThreshold) {
      _scrollTimer?.cancel();
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        _scrollController.jumpTo(_scrollController.offset - scrollAmount);
      });
    } else if (details.globalPosition.dx > screenWidth - scrollThreshold) {
      _scrollTimer?.cancel();
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        _scrollController.jumpTo(_scrollController.offset + scrollAmount);
      });
    } else {
      _scrollTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backlogTasks =
        widget.tasks.where((task) => task.status == 'Backlog').toList();
    final inProgressTasks =
        widget.tasks.where((task) => task.status == 'Ready').toList();
    final focusTasks =
        widget.tasks.where((task) => task.status == 'Focus').toList();
    final doneTasks =
        widget.tasks.where((task) => task.status == 'Done').toList();

    return Stack(
      children: [
        Listener(
          onPointerDown: (_) => setState(() => _isTaskBeingDragged = true),
          onPointerUp: (_) {
            setState(() => _isTaskBeingDragged = false);
            _scrollTimer?.cancel();
          },
          onPointerMove: (PointerMoveEvent event) => _handleDragUpdate(
              DragUpdateDetails(globalPosition: event.position)),
          child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: [
              KanbanColumn(title: 'Backlog', tasks: backlogTasks),
              KanbanColumn(title: 'Ready', tasks: inProgressTasks),
              KanbanColumn(title: 'Focus', tasks: focusTasks),
              KanbanColumn(title: 'Done', tasks: doneTasks),
            ],
          ),
        ),
      ],
    );
  }
}
