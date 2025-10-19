import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

enum TaskFilter { all, life, work }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.life);

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

final filteredTaskListProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);

  switch (filter) {
    case TaskFilter.all:
      return tasks;
    case TaskFilter.life:
      return tasks.where((task) => task.category == 'life').toList();
    case TaskFilter.work:
      return tasks.where((task) => task.category == 'work').toList();
  }
});

class TaskListNotifier extends StateNotifier<List<Task>> {
  final LocalStorageService _localStorageService;

  TaskListNotifier(this._localStorageService) : super([]) {
    _loadTasksFromStorage();
  }

  Future<void> _loadTasksFromStorage() async {
    try {
      // only load non-archived tasks
      final tasks = await _localStorageService.getTasks(includeArchived: false);
      state = tasks;
    } catch (e) {
      print('error loading tasks: $e');
      state = [];
    }
  }

  Future<void> addTask(String title, String description, int priority,
      String status, DateTime? dueDate,
      [String category = 'life']) async {
    final newTask = Task(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      priority: priority.toString(),
      status: status,
      focusStartTime: status == 'Focus' ? DateTime.now() : null,
      dueDate: dueDate,
      isDateDetected: dueDate != null,
      category: category,
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

      await (task.status == 'Done' || task.dueDate == null
          ? NotificationService.cancelTaskReminders(task)
          : NotificationService.scheduleTaskReminders(task));
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
        // stop focusing, and set completedAt if moving to Done
        updatedTask = currentTask.copyWith(
          status: newStatus,
          focusStartTime: null,
          completedAt:
              newStatus == 'Done' ? DateTime.now() : currentTask.completedAt,
        );
      } else if (newStatus == 'Done' && currentTask.status != 'Done') {
        // set completedAt when moving to Done
        updatedTask = currentTask.copyWith(
          status: newStatus,
          completedAt: DateTime.now(),
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

  Future<void> resetFocusTime(Task task) async {
    try {
      final updatedTask = task.copyWith(
        timeSpent: Duration.zero,
        focusStartTime: task.status == 'Focus' ? DateTime.now() : null,
      );
      await updateTask(updatedTask);
    } catch (e) {
      print('error resetting focus time: $e');
    }
  }

  Future<void> clearDueDate(Task task) async {
    try {
      final updatedTask = task.copyWith(
        dueDate: null,
        isDateDetected: false,
      );
      await _localStorageService.updateTask(updatedTask);
      await NotificationService.cancelTaskReminders(task);

      state = [
        for (final t in state)
          if (t.id == task.id) updatedTask else t
      ];
    } catch (e) {
      print('error clearing due date: $e');
    }
  }

  Future<void> archiveTask(Task task) async {
    try {
      final archivedTask = task.copyWith(isArchived: true);
      await _localStorageService.updateTask(archivedTask);
      state = state.where((t) => t.id != task.id).toList();
    } catch (e) {
      print('error archiving task: $e');
    }
  }

  Future<void> archiveAllDoneTasks(String category) async {
    try {
      final doneTasks = state
          .where((task) => task.status == 'Done' && task.category == category)
          .toList();

      for (final task in doneTasks) {
        final archivedTask = task.copyWith(isArchived: true);
        await _localStorageService.updateTask(archivedTask);
      }

      state = state
          .where(
              (task) => !(task.status == 'Done' && task.category == category))
          .toList();
    } catch (e) {
      print('error archiving done tasks: $e');
    }
  }

  Future<List<Task>> getArchivedTasks(String category) async {
    try {
      return await _localStorageService.getArchivedTasks(category);
    } catch (e) {
      print('error getting archived tasks: $e');
      return [];
    }
  }

  Future<void> unarchiveTask(Task task) async {
    try {
      final unarchivedTask = task.copyWith(isArchived: false);
      await _localStorageService.updateTask(unarchivedTask);
      state = [...state, unarchivedTask];

      if (unarchivedTask.dueDate != null && unarchivedTask.status != 'Done') {
        await NotificationService.scheduleTaskReminders(unarchivedTask);
      }
    } catch (e) {
      print('error unarchiving task: $e');
    }
  }
}
