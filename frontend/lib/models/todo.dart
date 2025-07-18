import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  final String id;
  final String title;
  final String description;
  
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  
  @JsonKey(name: 'related_recipe_id')
  final String? relatedRecipeId;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.dueDate,
    this.relatedRecipeId,
  });

  // JSON serialization
  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);

  // Factory constructor from map (backward compatibility)
  factory Todo.fromMap(Map<String, dynamic> map, String id) {
    return Todo(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null 
          ? DateTime.parse(map['dueDate']) 
          : null,
      relatedRecipeId: map['relatedRecipeId'],
    );
  }

  // Convert to map (backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'relatedRecipeId': relatedRecipeId,
    };
  }

  // Factory constructor for new todo
  factory Todo.create({
    required String title,
    required String description,
    DateTime? dueDate,
    String? relatedRecipeId,
  }) {
    return Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      isCompleted: false,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      relatedRecipeId: relatedRecipeId,
    );
  }

  // Copy with method for updates
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    String? relatedRecipeId,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      relatedRecipeId: relatedRecipeId ?? this.relatedRecipeId,
    );
  }

  // Check if todo is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Check if todo is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAtSameMomentAs(due);
  }

  // Get priority level based on due date
  String get priority {
    if (dueDate == null) return 'Low';
    if (isOverdue) return 'Urgent';
    if (isDueToday) return 'High';
    
    final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;
    if (daysUntilDue <= 1) return 'High';
    if (daysUntilDue <= 3) return 'Medium';
    return 'Low';
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}