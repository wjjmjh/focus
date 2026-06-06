import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../widgets/kanban_board.dart';
import '../widgets/styled_background.dart';
import 'archived_tasks_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localStorageServiceAsync = ref.watch(localStorageServiceProvider);
    final currentFilter = ref.watch(taskFilterProvider);

    final notificationsEnabled =
        ref.watch(notificationsEnabledProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('focus'),
        actions: [
          if (!notificationsEnabled)
            IconButton(
              icon: const Icon(Icons.notifications_off_outlined),
              tooltip: 'Reminders are off',
              onPressed: () => _handleEnableNotifications(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'View archived tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ArchivedTasksScreen(),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleButton(
                    'Life',
                    Icons.home_rounded,
                    TaskFilter.life,
                    currentFilter == TaskFilter.life,
                    ref,
                  ),
                  _buildToggleButton(
                    'Work',
                    Icons.work_rounded,
                    TaskFilter.work,
                    currentFilter == TaskFilter.work,
                    ref,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StyledBackground(
        child: localStorageServiceAsync.when(
          data: (_) {
            final tasks = ref.watch(filteredTaskListProvider);
            return KanbanBoard(tasks: tasks);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('error: $error')),
        ),
      ),
    );
  }

  Future<void> _handleEnableNotifications(
      BuildContext context, WidgetRef ref) async {
    final granted = await NotificationService.requestPermission();
    ref.invalidate(notificationsEnabledProvider);

    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable notifications in Settings to get task reminders.',
          ),
        ),
      );
    }
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    TaskFilter filter,
    bool isSelected,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(taskFilterProvider.notifier).state = filter;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
