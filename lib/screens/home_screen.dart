import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../widgets/kanban_board.dart';
import '../widgets/animated_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localStorageServiceAsync = ref.watch(localStorageServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('focus')),
      body: AnimatedBackground(
        child: localStorageServiceAsync.when(
          data: (_) {
            final tasks = ref.watch(taskListProvider);
            return KanbanBoard(tasks: tasks);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('error: $error')),
        ),
      ),
    );
  }
}
