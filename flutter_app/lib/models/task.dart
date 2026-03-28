// lib/models/task.dart
enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:       return 'To-Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done:       return 'Done';
    }
  }
  String get apiValue {
    switch (this) {
      case TaskStatus.todo:       return 'todo';
      case TaskStatus.inProgress: return 'in_progress';
      case TaskStatus.done:       return 'done';
    }
  }
  static TaskStatus fromApi(String v) {
    switch (v) {
      case 'in_progress': return TaskStatus.inProgress;
      case 'done':        return TaskStatus.done;
      default:            return TaskStatus.todo;
    }
  }
}

class Task {
  final String   id;
  final String   title;
  final String   description;
  final DateTime dueDate;
  final TaskStatus status;
  final String?  blockedById;
  final String?  blockedByTitle;   // populated by backend serializer
  final int      sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    this.blockedByTitle,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBlocked => false; // resolved by provider, not stored here

  Task copyWith({
    String?    title,
    String?    description,
    DateTime?  dueDate,
    TaskStatus? status,
    String?    blockedById,
    bool       clearBlockedBy = false,
    int?       sortOrder,
  }) =>
      Task(
        id:             id,
        title:          title          ?? this.title,
        description:    description    ?? this.description,
        dueDate:        dueDate        ?? this.dueDate,
        status:         status         ?? this.status,
        blockedById:    clearBlockedBy ? null : (blockedById ?? this.blockedById),
        blockedByTitle: blockedByTitle,
        sortOrder:      sortOrder      ?? this.sortOrder,
        createdAt:      createdAt,
        updatedAt:      updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'title':        title,
    'description':  description,
    'due_date':     dueDate.toUtc().toIso8601String(),
    'status':       status.apiValue,
    'blocked_by_id': blockedById,
    'sort_order':   sortOrder,
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id:             j['id']            as String,
    title:          j['title']         as String,
    description:    j['description']   as String? ?? '',
    dueDate:        DateTime.parse(j['due_date'] as String).toLocal(),
    status:         TaskStatusX.fromApi(j['status'] as String),
    blockedById:    j['blocked_by_id'] as String?,
    blockedByTitle: j['blocked_by_title'] as String?,
    sortOrder:      j['sort_order']    as int? ?? 0,
    createdAt:      DateTime.parse(j['created_at'] as String).toLocal(),
    updatedAt:      DateTime.parse(j['updated_at'] as String).toLocal(),
  );

  @override bool operator ==(Object o) => o is Task && o.id == id;
  @override int get hashCode => id.hashCode;
}
