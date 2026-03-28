// lib/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // Re-read from provider to always show latest data
    final t        = provider.taskById(task.id) ?? task;
    final blocked  = provider.isBlocked(t);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: t)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.danger),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await _confirmDelete(context);
              if (confirm == true && context.mounted) {
                await context.read<TaskProvider>().deleteTask(t.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Title + status ────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    color: blocked ? AppColors.blockedText : AppColors.textPrimary,
                    decoration: t.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textDisabled,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: t.status),
            ]),

            const SizedBox(height: 20),

            // ── Meta cards ────────────────────────────────────────────────
            _metaRow(
              Icons.calendar_today_outlined,
              'Due Date',
              DateFormat('EEEE, MMMM d, yyyy').format(t.dueDate),
              _dueDateColor(t),
            ),

            if (t.blockedByTitle != null)
              _metaRow(
                Icons.lock_outline_rounded,
                'Blocked By',
                t.blockedByTitle!,
                blocked ? AppColors.danger : AppColors.done,
              ),

            _metaRow(
              Icons.sort_rounded,
              'Priority Order',
              '#${t.sortOrder + 1}',
              AppColors.textSecondary,
            ),

            _metaRow(
              Icons.access_time_rounded,
              'Created',
              DateFormat('MMM d, yyyy · HH:mm').format(t.createdAt),
              AppColors.textSecondary,
            ),

            _metaRow(
              Icons.update_rounded,
              'Updated',
              DateFormat('MMM d, yyyy · HH:mm').format(t.updatedAt),
              AppColors.textSecondary,
            ),

            // ── Description ───────────────────────────────────────────────
            if (t.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary, letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  t.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],

            if (blocked) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This task is blocked until "${t.blockedByTitle}" is marked Done.',
                      style: const TextStyle(
                        color: AppColors.danger, fontSize: 13, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text('$label  ',
            style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
          ),
        ]),
      );

  Color _dueDateColor(Task t) {
    if (t.status == TaskStatus.done) return AppColors.done;
    if (t.dueDate.isBefore(DateTime.now())) return AppColors.danger;
    if (t.dueDate.difference(DateTime.now()).inDays <= 2) return AppColors.inProgress;
    return AppColors.textSecondary;
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Delete Task?',
        style: TextStyle(color: AppColors.textPrimary)),
      content: const Text(
        'This cannot be undone. Tasks blocked by this one will be unblocked.',
        style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete',
            style: TextStyle(color: AppColors.danger))),
      ],
    ),
  );
}
