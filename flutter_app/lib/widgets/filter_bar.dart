// lib/widgets/filter_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});
  @override State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final _ctrl  = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    // 300 ms debounce — satisfies the stretch goal requirement
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<TaskProvider>().setSearch(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(children: [
        // ── Search field ─────────────────────────────────────────────────
        TextField(
          controller: _ctrl,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search tasks…',
            prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textSecondary),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                    onPressed: () {
                      _ctrl.clear();
                      context.read<TaskProvider>().setSearch('');
                    },
                  )
                : null,
          ),
        ),

        const SizedBox(height: 10),

        // ── Status filter chips ──────────────────────────────────────────
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(context, null,             'All',         provider.statusFilter),
              _chip(context, TaskStatus.todo,        'To-Do',       provider.statusFilter),
              _chip(context, TaskStatus.inProgress,  'In Progress', provider.statusFilter),
              _chip(context, TaskStatus.done,        'Done',        provider.statusFilter),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext ctx, TaskStatus? value, String label, TaskStatus? current) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => ctx.read<TaskProvider>().setStatusFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
