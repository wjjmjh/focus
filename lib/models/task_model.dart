import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String priority;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final int timeSpentMillis;

  @HiveField(6)
  final DateTime? focusStartTime;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    Duration timeSpent = Duration.zero,
    this.focusStartTime,
  }) : timeSpentMillis = timeSpent.inMilliseconds;

  Duration get timeSpent => Duration(milliseconds: timeSpentMillis);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    Duration? timeSpent,
    DateTime? focusStartTime,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      timeSpent: timeSpent ?? this.timeSpent,
      focusStartTime: focusStartTime ?? this.focusStartTime,
    );
  }
}
