import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

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
      await NotificationService.scheduleAllTaskReminders(tasks);
    } catch (e) {
      print('error loading tasks: $e');
      state = [];
    }
  }

  Future<void> addTask(String title, String description, int priority,
      String status, DateTime? dueDate) async {
    final newTask = Task(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      priority: priority.toString(),
      status: status,
      focusStartTime: status == 'Focus' ? DateTime.now() : null,
      dueDate: dueDate,
      isDateDetected: dueDate != null,
    );

    try {
      await _localStorageService.addTask(newTask);
      state = [...state, newTask];

      if (dueDate != null) {
        await NotificationService.scheduleTaskReminders(newTask);
      }
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

      if (task.status == 'Done') {
        await NotificationService.cancelTaskReminders(task);
      } else if (task.dueDate != null) {
        await NotificationService.scheduleTaskReminders(task);
      }
    } catch (e) {
      print('error updating task: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _localStorageService.deleteTask(task);
      await NotificationService.cancelTaskReminders(task);
      state = state.where((t) => t.id != task.id).toList();
    } catch (e) {
      print('error deleting task: $e');
    }
  }

  Future<void> saveFocusTimeBeforeDrag(Task task) async {
    if (task.status == 'Focus' && task.focusStartTime != null) {
      final timeSpentInFocus = DateTime.now().difference(task.focusStartTime!);
      final updatedTask = task.copyWith(
        timeSpent: task.timeSpent + timeSpentInFocus,
        focusStartTime: null,
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> moveTask(Task task, String newStatus) async {
    try {
      final currentTask =
          state.firstWhere((t) => t.id == task.id, orElse: () => task);
      late Task updatedTask;

      if (newStatus == 'Focus' && currentTask.status != 'Focus') {
        // start focusing & tracking time
        updatedTask = currentTask.copyWith(
          status: newStatus,
          focusStartTime: DateTime.now(),
        );
      } else if (currentTask.status == 'Focus' && newStatus != 'Focus') {
        // stop focusing
        final timeSpentInFocus = currentTask.focusStartTime != null
            ? DateTime.now().difference(currentTask.focusStartTime!)
            : Duration.zero;
        updatedTask = currentTask.copyWith(
          status: newStatus,
          timeSpent: currentTask.timeSpent + timeSpentInFocus,
          focusStartTime: null,
        );
      } else {
        updatedTask = currentTask.copyWith(status: newStatus);
      }

      await _localStorageService.updateTask(updatedTask);

      state = [
        for (final t in state)
          if (t.id == updatedTask.id) updatedTask else t
      ];

      if (updatedTask.status == 'Done') {
        await NotificationService.cancelTaskReminders(updatedTask);
      } else if (updatedTask.dueDate != null) {
        await NotificationService.scheduleTaskReminders(updatedTask);
      }
    } catch (e) {
      print('error moving task: $e');
    }
  }
}
