// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_bar.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks    = provider.filteredTasks;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Tasks'),
          Text(
            '${provider.tasks.length} task${provider.tasks.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              fontWeight: FontWeight.w400, fontFamily: 'Georgia',
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : provider.loadTasks,
          ),
        ],
      ),
      body: Column(children: [
        const FilterBar(),
        Expanded(child: _buildBody(provider, tasks)),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          if (result == true && context.mounted) {
            provider.loadTasks();
          }
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildBody(TaskProvider provider, List tasks) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent, strokeWidth: 2));
    }

    if (provider.error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
            size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          const Text('Could not connect to server',
            style: TextStyle(color: AppColors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(provider.error!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: provider.loadTasks,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      ));
    }

    if (tasks.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            provider.searchQuery.isNotEmpty || provider.statusFilter != null
                ? Icons.search_off_rounded
                : Icons.check_circle_outline_rounded,
            size: 56, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            provider.searchQuery.isNotEmpty || provider.statusFilter != null
                ? 'No tasks match your filters'
                : 'No tasks yet',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('Tap + to create your first task',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      ));
    }

    // Reorder is only sensible when no search/filter active
    final canReorder = provider.searchQuery.isEmpty && provider.statusFilter == null;

    if (canReorder) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: tasks.length,
        onReorder: provider.reorder,
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent, child: child),
        itemBuilder: (_, i) => _cardFor(tasks[i], provider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _cardFor(tasks[i], provider),
    );
  }

  Widget _cardFor(task, TaskProvider provider) => TaskCard(
    key: ValueKey(task.id),
    task: task,
    searchQuery: provider.searchQuery,
    onTap: () async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      );
      provider.loadTasks();
    },
    onDelete: () async {
      final ok = await provider.deleteTask(task.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Delete failed')));
      }
    },
  );
}
