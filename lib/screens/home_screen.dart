import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../widgets/kanban_board.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localStorageServiceAsync = ref.watch(localStorageServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text('focus')),
      body: localStorageServiceAsync.when(
        data: (_) {
          final tasks = ref.watch(taskListProvider);
          return KanbanBoard(tasks: tasks);
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('error: $error')),
      ),
    );
  }
}
