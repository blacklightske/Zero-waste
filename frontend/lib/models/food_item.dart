import 'package:intl/intl.dart';

class FoodItem {
  final String id;
  final String name;
  final String quantity;
  
  final DateTime expiryDate;
  
  final DateTime createdAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    required this.createdAt,
  });

  // JSON serialization
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'].toString(),
      name: json['name'],
      quantity: json['quantity'],
      expiryDate: DateTime.parse(json['expiry_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'expiry_date': DateFormat('yyyy-MM-dd').format(expiryDate),
    };
  }

  // Factory constructor from map (backward compatibility)
  factory FoodItem.fromMap(Map<String, dynamic> map, String id) {
    return FoodItem(
      id: id,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      expiryDate: DateTime.parse(map['expiryDate']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Convert to map (backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Check if food item is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  // Check if food item expires soon (within 2 days)
  bool get expiresSoon {
    final now = DateTime.now();
    final twoDaysFromNow = now.add(const Duration(days: 2));
    return expiryDate.isBefore(twoDaysFromNow) && !isExpired;
  }

  // Get days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  // Copy with method for updates
  FoodItem copyWith({
    String? id,
    String? name,
    String? quantity,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, quantity: $quantity, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}