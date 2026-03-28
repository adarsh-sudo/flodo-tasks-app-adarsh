// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool compact;
  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _bg {
    switch (status) {
      case TaskStatus.todo:       return AppColors.todo.withOpacity(0.15);
      case TaskStatus.inProgress: return AppColors.inProgress.withOpacity(0.15);
      case TaskStatus.done:       return AppColors.done.withOpacity(0.15);
    }
  }
  Color get _fg {
    switch (status) {
      case TaskStatus.todo:       return AppColors.todo;
      case TaskStatus.inProgress: return AppColors.inProgress;
      case TaskStatus.done:       return AppColors.done;
    }
  }
  IconData get _icon {
    switch (status) {
      case TaskStatus.todo:       return Icons.circle_outlined;
      case TaskStatus.inProgress: return Icons.timelapse_rounded;
      case TaskStatus.done:       return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: compact ? 10 : 12, color: _fg),
        SizedBox(width: compact ? 3 : 4),
        Text(status.label,
          style: TextStyle(
            color: _fg,
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          )),
      ]),
    );
  }
}
