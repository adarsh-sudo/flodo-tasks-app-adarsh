// lib/screens/task_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/draft.dart';
import '../models/task.dart';
import '../providers/draft_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/save_button.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = create mode

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  DateTime?   _dueDate;
  TaskStatus  _status    = TaskStatus.todo;
  String?     _blockedById;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final t     = widget.task!;
      _titleCtrl  = TextEditingController(text: t.title);
      _descCtrl   = TextEditingController(text: t.description);
      _dueDate    = t.dueDate;
      _status     = t.status;
      _blockedById = t.blockedById;
    } else {
      // Load draft for new-task mode
      final draft = context.read<DraftProvider>().draft;
      _titleCtrl  = TextEditingController(text: draft.title);
      _descCtrl   = TextEditingController(text: draft.description);
      _dueDate    = draft.dueDate;
      _status     = draft.statusValue != null
          ? TaskStatusX.fromApi(draft.statusValue!)
          : TaskStatus.todo;
      _blockedById = draft.blockedById;
    }

    // Persist draft on every keystroke (create mode only)
    if (!_isEdit) {
      _titleCtrl.addListener(_saveDraft);
      _descCtrl.addListener(_saveDraft);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _saveDraft() {
    context.read<DraftProvider>().update(TaskDraft(
      title:        _titleCtrl.text,
      description:  _descCtrl.text,
      dueDate:      _dueDate,
      statusValue:  _status.apiValue,
      blockedById:  _blockedById,
    ));
  }

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final pick = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (pick != null) {
      setState(() => _dueDate = pick);
      if (!_isEdit) _saveDraft();
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a due date.')),
      );
      return;
    }

    final provider = context.read<TaskProvider>();

    final body = {
      'title':         _titleCtrl.text.trim(),
      'description':   _descCtrl.text.trim(),
      'due_date':      _dueDate!.toUtc().toIso8601String(),
      'status':        _status.apiValue,
      'blocked_by_id': _blockedById,
      'sort_order':    _isEdit ? widget.task!.sortOrder : 0,
    };

    bool ok;
    if (_isEdit) {
      ok = await provider.updateTask(widget.task!.id, body);
    } else {
      body['id'] = const Uuid().v4();
      ok = await provider.createTask(body);
    }

    if (!mounted) return;

    if (ok) {
      if (!_isEdit) await context.read<DraftProvider>().clear();
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Something went wrong')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<TaskProvider, bool>((p) => p.isSaving);
    final tasks    = context.select<TaskProvider, List<Task>>((p) => p.tasks);
    final choices  = tasks.where((t) => t.id != widget.task?.id).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Title ──────────────────────────────────────────────────
              _label('TITLE'),
              const SizedBox(height: 6),
              TextFormField(
                controller:  _titleCtrl,
                enabled:     !isSaving,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Task title…'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),

              const SizedBox(height: 18),

              // ── Description ────────────────────────────────────────────
              _label('DESCRIPTION'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                enabled:    !isSaving,
                maxLines:   4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Optional notes…'),
              ),

              const SizedBox(height: 18),

              // ── Due date ───────────────────────────────────────────────
              _label('DUE DATE'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: isSaving ? null : _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                          : 'Pick a date',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dueDate != null
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 18),

              // ── Status ─────────────────────────────────────────────────
              _label('STATUS'),
              const SizedBox(height: 6),
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
                decoration: const InputDecoration(),
                items: TaskStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.label),
                )).toList(),
                onChanged: isSaving ? null : (v) {
                  if (v != null) {
                    setState(() => _status = v);
                    if (!_isEdit) _saveDraft();
                  }
                },
              ),

              const SizedBox(height: 18),

              // ── Blocked by ─────────────────────────────────────────────
              _label('BLOCKED BY (OPTIONAL)'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                value: _blockedById,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
                decoration: const InputDecoration(hintText: 'None'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...choices.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      t.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
                onChanged: isSaving ? null : (v) {
                  setState(() => _blockedById = v);
                  if (!_isEdit) _saveDraft();
                },
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────────
              SaveButton(
                isSaving:  isSaving,
                label:     _isEdit ? 'Update Task' : 'Create Task',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: AppColors.textSecondary,
      letterSpacing: 1.2,
    ),
  );
}
