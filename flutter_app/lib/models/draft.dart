// lib/models/draft.dart
class TaskDraft {
  final String  title;
  final String  description;
  final DateTime? dueDate;
  final String? statusValue;
  final String? blockedById;

  const TaskDraft({
    this.title        = '',
    this.description  = '',
    this.dueDate,
    this.statusValue,
    this.blockedById,
  });

  bool get isEmpty =>
      title.isEmpty && description.isEmpty &&
      dueDate == null && statusValue == null && blockedById == null;

  Map<String, dynamic> toJson() => {
    'title':        title,
    'description':  description,
    'due_date':     dueDate?.toIso8601String(),
    'status_value': statusValue,
    'blocked_by_id': blockedById,
  };

  factory TaskDraft.fromJson(Map<String, dynamic> j) => TaskDraft(
    title:        j['title']         as String? ?? '',
    description:  j['description']   as String? ?? '',
    dueDate:      j['due_date'] != null
                    ? DateTime.tryParse(j['due_date'] as String)
                    : null,
    statusValue:  j['status_value']  as String?,
    blockedById:  j['blocked_by_id'] as String?,
  );
}
