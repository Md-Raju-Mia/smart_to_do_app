enum Priority { low, medium, high }

class Task {
  final int? id;
  final String title;
  final String description;
  final Priority priority;
  final DateTime dueDate;
  final bool isCompleted;
  final bool reminderActive;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    required this.dueDate,
    this.isCompleted = false,
    this.reminderActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'reminderActive': reminderActive ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      priority: Priority.values[map['priority']],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      reminderActive: map['reminderActive'] == 1,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    Priority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    bool? reminderActive,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderActive: reminderActive ?? this.reminderActive,
    );
  }
}
