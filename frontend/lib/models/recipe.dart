import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

@JsonSerializable()
class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final List<String> instructions;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_custom')
  final bool isCustom; // true for user-created, false for AI-generated
  @JsonKey(name: 'is_saved')
  final bool isSaved; // true if saved to favorites

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.createdAt,
    this.isCustom = false,
    this.isSaved = false,
  });

  // JSON serialization
  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);

  // Factory constructor from map (backward compatibility)
  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      name: map['name'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      isCustom: map['isCustom'] ?? false,
      isSaved: map['isSaved'] ?? false,
    );
  }

  // Convert to map (backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'createdAt': createdAt.toIso8601String(),
      'isCustom': isCustom,
      'isSaved': isSaved,
    };
  }

  // Factory constructor for AI-generated recipe
  factory Recipe.fromAI({
    required String name,
    required List<String> ingredients,
    required List<String> instructions,
  }) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      createdAt: DateTime.now(),
      isCustom: false,
      isSaved: false,
    );
  }

  // Factory constructor for custom recipe
  factory Recipe.custom({
    required String name,
    required List<String> ingredients,
    required List<String> instructions,
  }) {
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      ingredients: ingredients,
      instructions: instructions,
      createdAt: DateTime.now(),
      isCustom: true,
      isSaved: true,
    );
  }

  // Copy with method for updates
  Recipe copyWith({
    String? id,
    String? name,
    List<String>? ingredients,
    List<String>? instructions,
    DateTime? createdAt,
    bool? isCustom,
    bool? isSaved,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
      isCustom: isCustom ?? this.isCustom,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Get estimated cooking time based on instructions count
  String get estimatedTime {
    final steps = instructions.length;
    if (steps <= 3) return '15-20 min';
    if (steps <= 5) return '25-35 min';
    return '40+ min';
  }

  // Get difficulty level based on ingredients and instructions
  String get difficulty {
    final totalComplexity = ingredients.length + instructions.length;
    if (totalComplexity <= 8) return 'Easy';
    if (totalComplexity <= 15) return 'Medium';
    return 'Hard';
  }

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, isCustom: $isCustom, isSaved: $isSaved)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}