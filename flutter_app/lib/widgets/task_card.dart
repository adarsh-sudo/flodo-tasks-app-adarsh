// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  final Task     task;
  final String   searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final blocked  = provider.isBlocked(task);

    final cardBg     = blocked ? AppColors.blockedCard   : AppColors.card;
    final borderCol  = blocked ? AppColors.blockedBorder : AppColors.border;
    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      fontFamily: 'Georgia',
      color: blocked ? AppColors.blockedText : AppColors.textPrimary,
      decoration: task.status == TaskStatus.done
          ? TextDecoration.lineThrough
          : null,
      decorationColor: AppColors.textDisabled,
    );

    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.danger.withOpacity(0.15),
            foregroundColor: AppColors.danger,
            icon: Icons.delete_outline_rounded,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_indicator_rounded,
                  size: 18,
                  color: blocked ? AppColors.blockedText : AppColors.textDisabled),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(children: [
                      Expanded(
                        child: HighlightedText(
                          text:      task.title,
                          highlight: searchQuery,
                          baseStyle: titleStyle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: task.status, compact: true),
                    ]),

                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: blocked
                              ? AppColors.blockedText
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Footer row
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                        size: 11,
                        color: _dueDateColor(task.dueDate, blocked)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(task.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: _dueDateColor(task.dueDate, blocked),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (blocked && task.blockedByTitle != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.lock_outline_rounded,
                          size: 11, color: AppColors.danger),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Blocked by "${task.blockedByTitle}"',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                size: 18,
                color: blocked ? AppColors.blockedText : AppColors.textDisabled),
            ]),
          ),
        ),
      ),
    );
  }

  Color _dueDateColor(DateTime due, bool blocked) {
    if (blocked) return AppColors.blockedText;
    if (task.status == TaskStatus.done) return AppColors.textDisabled;
    final now = DateTime.now();
    if (due.isBefore(now)) return AppColors.danger;
    if (due.difference(now).inDays <= 2) return AppColors.inProgress;
    return AppColors.textSecondary;
  }
}
