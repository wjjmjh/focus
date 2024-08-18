import 'package:hive/hive.dart';
import '../models/task_model.dart';

class LocalStorageService {
  late Box<Task> _taskBox;

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
  }

  Future<List<Task>> getTasks() async {
    return _taskBox.values.toList();
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
