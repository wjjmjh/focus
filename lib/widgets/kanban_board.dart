import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'kanban_column.dart';

final ValueNotifier<bool> isDraggingGlobally = ValueNotifier<bool>(false);
final ValueNotifier<Offset?> dragPositionGlobally =
    ValueNotifier<Offset?>(null);

class KanbanBoard extends StatefulWidget {
  final List<Task> tasks;

  const KanbanBoard({Key? key, required this.tasks}) : super(key: key);

  @override
  _KanbanBoardState createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  int _dir = 0;

  static const _edgePx = 100.0;
  static const _pxPerTick = 20.0;
  static const _tick = Duration(milliseconds: 20);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    dragPositionGlobally.addListener(_onDragPositionChanged);
  }

  @override
  void dispose() {
    dragPositionGlobally.removeListener(_onDragPositionChanged);
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragPositionChanged() {
    final pos = dragPositionGlobally.value;
    if (pos == null || !isDraggingGlobally.value) {
      _stopAutoScroll();
      return;
    }
    _maybeAutoScroll(pos.dx);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDraggingGlobally.value) {
      dragPositionGlobally.value = event.position;
    }
  }

  void _maybeAutoScroll(double globalDx) {
    final screenWidth = MediaQuery.of(context).size.width;

    int desired;
    if (globalDx <= _edgePx) {
      desired = -1;
    } else if (globalDx >= screenWidth - _edgePx) {
      desired = 1;
    } else {
      desired = 0;
    }

    if (desired == 0) {
      _stopAutoScroll();
      return;
    }

    if (_dir != desired) {
      _dir = desired;
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(_tick, (_) {
        if (!_scrollController.hasClients) return;
        final pos = _scrollController.position;
        final next = (_scrollController.offset + _pxPerTick * _dir)
            .clamp(pos.minScrollExtent, pos.maxScrollExtent);
        if (next == _scrollController.offset) {
          _stopAutoScroll();
          return;
        }
        _scrollController.jumpTo(next);
      });
    }
  }

  void _stopAutoScroll() {
    _dir = 0;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final backlogTasks =
        widget.tasks.where((t) => t.status == 'Backlog').toList();
    final readyTasks = widget.tasks.where((t) => t.status == 'Ready').toList();
    final focusTasks = widget.tasks.where((t) => t.status == 'Focus').toList();
    final doneTasks = widget.tasks.where((t) => t.status == 'Done').toList();

    return Listener(
      onPointerMove: _handlePointerMove,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: [
          KanbanColumn(title: 'Backlog', tasks: backlogTasks),
          KanbanColumn(title: 'Ready', tasks: readyTasks),
          KanbanColumn(title: 'Focus', tasks: focusTasks),
          KanbanColumn(title: 'Done', tasks: doneTasks),
        ],
      ),
    );
  }
}
