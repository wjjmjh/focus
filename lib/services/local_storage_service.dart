import 'package:hive/hive.dart';
import '../models/task_model.dart';

class LocalStorageService {
  late Box<Task> _taskBox;

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
  }

  Future<List<Task>> getTasks({bool includeArchived = false}) async {
    try {
      final tasks = _taskBox.values.toList();
      if (includeArchived) {
        return tasks;
      }
      return tasks.where((task) => !task.isArchived).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Task>> getArchivedTasks(String category) async {
    try {
      final tasks = _taskBox.values.toList();
      return tasks
          .where((task) => task.isArchived && task.category == category)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(Task task) async {
    await _taskBox.delete(task.id);
  }
}
