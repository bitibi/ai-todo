class User {
  final String id;
  final String email;
  final String? fullName;

  User({required this.id, required this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
    );
  }
}

class TodoList {
  final String id;
  final String name;
  final String? icon;
  final String? iconBg;
  final bool isUrgent;
  final int position;
  final List<Section>? sections;
  final List<Task>? tasks;

  TodoList({
    required this.id,
    required this.name,
    this.icon,
    this.iconBg,
    required this.isUrgent,
    required this.position,
    this.sections,
    this.tasks,
  });

  factory TodoList.fromJson(Map<String, dynamic> json) {
    var sectionList = json['sections'] as List?;
    var taskList = json['tasks'] as List?;
    
    return TodoList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      iconBg: json['icon_bg'],
      isUrgent: json['is_urgent'] ?? false,
      position: json['position'] ?? 0,
      sections: sectionList?.map((s) => Section.fromJson(s)).toList(),
      tasks: taskList?.map((t) => Task.fromJson(t)).toList(),
    );
  }

  TodoList copyWith({
    String? name,
    String? icon,
    String? iconBg,
    bool? isUrgent,
    int? position,
    List<Section>? sections,
    List<Task>? tasks,
  }) {
    return TodoList(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconBg: iconBg ?? this.iconBg,
      isUrgent: isUrgent ?? this.isUrgent,
      position: position ?? this.position,
      sections: sections ?? this.sections,
      tasks: tasks ?? this.tasks,
    );
  }
}

class Section {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int position;
  final String listId;
  final List<Task>? tasks;

  Section({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.position,
    required this.listId,
    this.tasks,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List?;
    return Section(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      color: json['color'],
      position: json['position'] ?? 0,
      listId: json['list_id'] ?? '',
      tasks: taskList?.map((t) => Task.fromJson(t)).toList(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String priority;
  final String? timeEstimate;
  final String? details;
  final String? subText;
  final int position;
  final bool isCompleted;
  final String? completedAt;
  final String listId;
  final String? sectionId;
  final String? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.timeEstimate,
    this.details,
    this.subText,
    required this.position,
    required this.isCompleted,
    this.completedAt,
    required this.listId,
    this.sectionId,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      priority: json['priority'] ?? 'medium',
      timeEstimate: json['time_estimate'],
      details: json['details'],
      subText: json['sub_text'],
      position: json['position'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'],
      listId: json['list_id'] ?? '',
      sectionId: json['section_id'],
      dueDate: json['due_date'],
    );
  }

  Task copyWith({
    bool? isCompleted,
    String? title,
    String? details,
    String? subText,
    String? dueDate,
    String? priority,
    String? timeEstimate,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      details: details ?? this.details,
      subText: subText ?? this.subText,
      position: position,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt,
      listId: listId,
      sectionId: sectionId,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
