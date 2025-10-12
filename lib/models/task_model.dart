import 'package:hive/hive.dart';

part 'task_model.g.dart';

const Object _undefined = Object();

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

  @HiveField(7)
  final DateTime? dueDate;

  @HiveField(8)
  final bool isDateDetected;

  @HiveField(9)
  final String category;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    Duration timeSpent = Duration.zero,
    this.focusStartTime,
    this.dueDate,
    this.isDateDetected = false,
    String? category,
  })  : timeSpentMillis = timeSpent.inMilliseconds,
        category = category ?? 'life';

  Duration get timeSpent => Duration(milliseconds: timeSpentMillis);

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    Duration? timeSpent,
    DateTime? focusStartTime,
    Object? dueDate = _undefined,
    bool? isDateDetected,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      timeSpent: timeSpent ?? this.timeSpent,
      focusStartTime: focusStartTime ?? this.focusStartTime,
      dueDate: dueDate == _undefined ? this.dueDate : dueDate as DateTime?,
      isDateDetected: isDateDetected ?? this.isDateDetected,
      category: category ?? this.category,
    );
  }

  static DateTime? extractDateFromDescription(String description) {
    final RegExp dateRegex = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    final Match? match = dateRegex.firstMatch(description);

    if (match != null) {
      try {
        final int day = int.parse(match.group(1)!);
        final int month = int.parse(match.group(2)!);
        final int year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due == today;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due == tomorrow;
  }
}
