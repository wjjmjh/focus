import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';

final localStorageServiceProvider =
    FutureProvider<LocalStorageService>((ref) async {
  final service = LocalStorageService();
  await service.init();
  return service;
});

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  final storageService = ref.watch(localStorageServiceProvider).maybeWhen(
        data: (service) => service,
        orElse: () => throw Exception('LocalStorageService not initialised'),
      );
  return TaskListNotifier(storageService);
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final LocalStorageService _localStorageService;

  TaskListNotifier(this._localStorageService) : super([]) {
    _loadTasksFromStorage();
  }

  Future<void> _loadTasksFromStorage() async {
    try {
      final tasks = await _localStorageService.getTasks();
      state = tasks;
    } catch (e) {
      print('error loading tasks: $e');
      state = [];
    }
  }

  Future<void> addTask(
      String title, String description, int priority, String status) async {
    final newTask = Task(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      priority: priority.toString(),
      status: status,
    );
    try {
      await _localStorageService.addTask(newTask);
      state = [...state, newTask];
    } catch (e) {
      print('error adding task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _localStorageService.updateTask(task);
      state = [
        for (final t in state)
          if (t.id == task.id) task else t
      ];
    } catch (e) {
      print('error updating task: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _localStorageService.deleteTask(task);
      state = state.where((t) => t.id != task.id).toList();
    } catch (e) {
      print('error deleting task: $e');
    }
  }

  Future<void> moveTask(Task task, String newStatus) async {
    try {
      late Task updatedTask;

      if (newStatus == 'Focus' && task.status != 'Focus') {
        // start focusing & tracking time
        updatedTask = task.copyWith(
          status: newStatus,
          focusStartTime: DateTime.now(),
        );
      } else if (task.status == 'Focus' && newStatus != 'Focus') {
        // stop focusing & update total time spent
        final timeSpentInFocus =
            DateTime.now().difference(task.focusStartTime ?? DateTime.now());
        updatedTask = task.copyWith(
          status: newStatus,
          focusStartTime: null,
          timeSpent: (task.timeSpent ?? Duration.zero) + timeSpentInFocus,
        );
      } else {
        updatedTask = task.copyWith(status: newStatus);
      }

      await _localStorageService.updateTask(updatedTask);

      state = [
        for (final t in state)
          if (t.id == updatedTask.id) updatedTask else t
      ];
    } catch (e) {
      print('error moving task: $e');
    }
  }
}
