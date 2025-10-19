import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/styled_background.dart';
import '../widgets/task_card.dart';

class ArchivedTasksScreen extends ConsumerStatefulWidget {
  const ArchivedTasksScreen({super.key});

  @override
  _ArchivedTasksScreenState createState() => _ArchivedTasksScreenState();
}

class _ArchivedTasksScreenState extends ConsumerState<ArchivedTasksScreen> {
  List<Task> _archivedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedTasks();
  }

  Future<void> _loadArchivedTasks() async {
    setState(() => _isLoading = true);
    final currentFilter = ref.read(taskFilterProvider);
    final category = currentFilter == TaskFilter.work ? 'work' : 'life';
    final notifier = ref.read(taskListProvider.notifier);
    final tasks = await notifier.getArchivedTasks(category);

    tasks.sort((a, b) {
      final aTime = a.completedAt;
      final bTime = b.completedAt;

      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime);
      }

      if (aTime != null) return -1;
      if (bTime != null) return 1;

      return b.priority.compareTo(a.priority);
    });

    setState(() {
      _archivedTasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(taskFilterProvider);
    final category = currentFilter == TaskFilter.work ? 'work' : 'life';
    final categoryCapitalized =
        category[0].toUpperCase() + category.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Archived $categoryCapitalized Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StyledBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _archivedTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No archived tasks',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archivedTasks.length,
                    itemBuilder: (context, index) {
                      final task = _archivedTasks[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.unarchive, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'Unarchive',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _confirmUnarchive(task);
                        },
                        onDismissed: (direction) {
                          final notifier = ref.read(taskListProvider.notifier);
                          notifier.unarchiveTask(task);
                          setState(() {
                            _archivedTasks.removeWhere((t) => t.id == task.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task unarchived'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: TaskCard(
                            task: task,
                            isArchived: true,
                            onDeleted: () {
                              setState(() {
                                _archivedTasks
                                    .removeWhere((t) => t.id == task.id);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<bool> _confirmUnarchive(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Unarchive Task',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Restore "${task.title}" to active tasks?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Unarchive'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
