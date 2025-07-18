// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste_lite/widgets/food_card.dart';
import 'package:zerowaste_lite/models/food_item.dart';

void main() {
  group('ZeroWaste Widget Tests', () {
    testWidgets('FoodCard displays food item information correctly', (WidgetTester tester) async {
      // Create a test food item
      final testFoodItem = FoodItem(
        id: 'test-id',
        name: 'Test Apple',
        quantity: '5 pieces',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      // Build the FoodCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: testFoodItem,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify that the food item information is displayed
      expect(find.text('Test Apple'), findsOneWidget);
      expect(find.text('Quantity: 5 pieces'), findsOneWidget);
      expect(find.text('Fresh'), findsOneWidget);
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('FoodCard shows expired status correctly', (WidgetTester tester) async {
      // Create an expired food item
      final expiredFoodItem = FoodItem(
        id: 'expired-id',
        name: 'Expired Milk',
        quantity: '1 liter',
        expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      // Build the FoodCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodCard(
              foodItem: expiredFoodItem,
            ),
          ),
        ),
      );

      // Verify that the expired status is displayed
      expect(find.text('Expired Milk'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
}
