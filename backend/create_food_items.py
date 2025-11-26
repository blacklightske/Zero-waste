#!/usr/bin/env python
"""
Script to create food items for a user in the ZeroWaste app
"""
import os
import sys
import django
from datetime import datetime, timedelta

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'zerowaste_backend.settings')
django.setup()

from api.models import FoodItem
from accounts.models import User


def create_food_items():
    """
    Create sample food items for the admin user
    """
    # Get the admin user
    try:
        admin_user = User.objects.get(email='admin@test.com')
        print(f"Found user: {admin_user.email}")
    except User.DoesNotExist:
        print("Error: User with email 'admin@test.com' not found.")
        print("Please make sure the user exists before running this script.")
        return
    
    # Sample food items with different expiry dates
    food_items = [
        {
            'name': 'Tomatoes',
            'quantity': '500g',
            'expiry_date': datetime.now() + timedelta(days=5)
        },
        {
            'name': 'Potatoes',
            'quantity': '1kg',
            'expiry_date': datetime.now() + timedelta(days=14)
        },
        {
            'name': 'Onions',
            'quantity': '3 medium',
            'expiry_date': datetime.now() + timedelta(days=10)
        },
        {
            'name': 'Carrots',
            'quantity': '6 pieces',
            'expiry_date': datetime.now() + timedelta(days=7)
        },
        {
            'name': 'Bell Peppers',
            'quantity': '4 pieces',
            'expiry_date': datetime.now() + timedelta(days=4)
        },
        {
            'name': 'Garlic',
            'quantity': '1 bulb',
            'expiry_date': datetime.now() + timedelta(days=20)
        },
        {
            'name': 'Chicken Breast',
            'quantity': '500g',
            'expiry_date': datetime.now() + timedelta(days=2)
        },
        {
            'name': 'Rice',
            'quantity': '2kg',
            'expiry_date': datetime.now() + timedelta(days=180)
        },
        {
            'name': 'Pasta',
            'quantity': '500g',
            'expiry_date': datetime.now() + timedelta(days=120)
        },
        {
            'name': 'Olive Oil',
            'quantity': '1 bottle',
            'expiry_date': datetime.now() + timedelta(days=365)
        }
    ]
    
    created_count = 0
    for item_data in food_items:
        # Check if food item already exists
        existing = FoodItem.objects.filter(
            name=item_data['name'],
            user=admin_user
        ).exists()
        
        if not existing:
            food_item = FoodItem.objects.create(
                user=admin_user,
                name=item_data['name'],
                quantity=item_data['quantity'],
                expiry_date=item_data['expiry_date'].date()
            )
            created_count += 1
            print(f"+ Created food item: {food_item.name}")
        else:
            print(f"- Food item already exists: {item_data['name']}")
    
    print(f"\n{created_count} new food items created out of {len(food_items)} total.")


def main():
    print("Creating food items for admin user...\n")
    create_food_items()
    print("\nFood items creation complete!")


if __name__ == '__main__':
    main()