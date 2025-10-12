import 'package:hive/hive.dart';
import '../models/task_model.dart';

class LocalStorageService {
  late Box<Task> _taskBox;

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
  }

  Future<List<Task>> getTasks() async {
    try {
      final tasks = _taskBox.values.toList();
      return tasks;
    } catch (e, stackTrace) {
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
