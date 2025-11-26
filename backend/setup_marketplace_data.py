#!/usr/bin/env python
"""
Setup script to create initial marketplace data for ZeroWaste app
"""
import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'zerowaste_backend.settings')
django.setup()

from api.models import Category, UserProfile, WasteProduct
from accounts.models import User
from datetime import datetime, timedelta


def create_categories():
    """Create initial waste categories"""
    categories = [
        {
            'name': 'Food Scraps',
            'description': 'Vegetable peels, fruit scraps, coffee grounds, tea bags',
            'icon': 'fa-apple-alt'
        },
        {
            'name': 'Garden Waste',
            'description': 'Grass clippings, leaves, small branches, pruned plants',
            'icon': 'fa-seedling'
        },
        {
            'name': 'Agricultural Waste',
            'description': 'Crop residues, livestock manure, organic farm waste',
            'icon': 'fa-tractor'
        },
        {
            'name': 'Kitchen Waste',
            'description': 'Cooking scraps, expired food, organic kitchen waste',
            'icon': 'fa-utensils'
        },
        {
            'name': 'Compost Materials',
            'description': 'Ready-to-use compost, decomposed organic matter',
            'icon': 'fa-recycle'
        },
        {
            'name': 'Wood Waste',
            'description': 'Sawdust, wood chips, small wood pieces',
            'icon': 'fa-tree'
        },
        {
            'name': 'Paper Waste',
            'description': 'Biodegradable paper, cardboard, newspaper',
            'icon': 'fa-newspaper'
        },
        {
            'name': 'Animal Feed',
            'description': 'Organic waste suitable for animal consumption',
            'icon': 'fa-paw'
        }
    ]
    
    created_count = 0
    for cat_data in categories:
        category, created = Category.objects.get_or_create(
            name=cat_data['name'],
            defaults={
                'description': cat_data['description'],
                'icon': cat_data['icon']
            }
        )
        if created:
            created_count += 1
            print(f"+ Created category: {category.name}")
        else:
            print(f"- Category already exists: {category.name}")
    
    print(f"\n{created_count} new categories created out of {len(categories)} total.")


def create_user_profiles():
    """Create user profiles for existing users"""
    users_without_profiles = User.objects.filter(profile__isnull=True)
    created_count = 0
    
    for user in users_without_profiles:
        profile = UserProfile.objects.create(
            user=user,
            bio=f"Green waste enthusiast from {user.email.split('@')[0].title()}",
        )
        created_count += 1
        print(f"+ Created profile for user: {user.email}")
    
    print(f"\n{created_count} user profiles created.")


def create_sample_products():
    """Create three sample marketplace products"""
    
    # Get or create a sample user (admin)
    admin_user, created = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@zerowaste.com',
            'first_name': 'Admin',
            'last_name': 'User',
            'is_staff': True,
            'is_superuser': True
        }
    )
    
    if created:
        admin_user.set_password('admin123')
        admin_user.save()
        print(f"+ Created admin user: {admin_user.username}")
    
    # Ensure user has a profile
    profile, profile_created = UserProfile.objects.get_or_create(
        user=admin_user,
        defaults={'bio': 'ZeroWaste marketplace administrator'}
    )
    
    # Get categories
    fruits_category = Category.objects.filter(name__icontains='Fruits').first()
    garden_category = Category.objects.filter(name__icontains='Garden').first()
    compost_category = Category.objects.filter(name__icontains='Compost').first()
    
    # If categories don't exist, use the first three available
    categories = Category.objects.all()[:3]
    if len(categories) < 3:
        print("Warning: Not enough categories found. Please run create_categories() first.")
        return
    
    fruits_category = fruits_category or categories[0]
    garden_category = garden_category or categories[1] 
    compost_category = compost_category or categories[2]
    
    sample_products = [
        {
            'title': 'Fresh Organic Tomatoes',
            'description': 'Surplus tomatoes from my garden. Perfectly ripe and organic. Great for cooking or preserving. Grown without pesticides.',
            'category': fruits_category,
            'price': 3.50,
            'is_free': False,
            'quantity': '2',
            'unit': 'kg',
            'condition': 'excellent',
            'location': 'Downtown Community Garden, Main St',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'estimated_weight': 2.0,
            'pickup_available': True,
            'delivery_available': True,
            'delivery_radius': 5,
        },
        {
            'title': 'Free Garden Leaves for Composting',
            'description': 'Large bag of fresh fallen leaves, perfect for composting or mulching. Already sorted and clean. Help yourself!',
            'category': garden_category,
            'price': 0.0,
            'is_free': True,
            'quantity': '3',
            'unit': 'bags',
            'condition': 'excellent',
            'location': 'Suburban Neighborhood, Oak Avenue',
            'latitude': 40.7580,
            'longitude': -73.9855,
            'estimated_weight': 15.0,
            'pickup_available': True,
            'delivery_available': False,
            'delivery_radius': None,
        },
        {
            'title': 'Rich Homemade Compost',
            'description': 'Well-aged compost from kitchen scraps and yard waste. Dark, rich soil perfect for gardens. Has been composting for 8 months.',
            'category': compost_category,
            'price': 8.00,
            'is_free': False,
            'quantity': '10',
            'unit': 'kg',
            'condition': 'excellent',
            'location': 'Green Valley Farm, Route 23',
            'latitude': 40.6892,
            'longitude': -74.0445,
            'estimated_weight': 10.0,
            'pickup_available': True,
            'delivery_available': True,
            'delivery_radius': 15,
        }
    ]
    
    created_count = 0
    for product_data in sample_products:
        # Check if product already exists
        existing = WasteProduct.objects.filter(
            title=product_data['title'],
            seller=admin_user
        ).exists()
        
        if not existing:
            product = WasteProduct.objects.create(
                seller=admin_user,
                title=product_data['title'],
                description=product_data['description'],
                category=product_data['category'],
                price=product_data['price'],
                is_free=product_data['is_free'],
                quantity=product_data['quantity'],
                unit=product_data['unit'],
                condition=product_data['condition'],
                location=product_data['location'],
                latitude=product_data['latitude'],
                longitude=product_data['longitude'],
                estimated_weight=product_data['estimated_weight'],
                pickup_available=product_data['pickup_available'],
                delivery_available=product_data['delivery_available'],
                delivery_radius=product_data['delivery_radius'],
                available_from=datetime.now(),
                available_until=datetime.now() + timedelta(days=30),
                status='available'
            )
            created_count += 1
            print(f"+ Created product: {product.title}")
        else:
            print(f"- Product already exists: {product_data['title']}")
    
    print(f"\n{created_count} new products created out of {len(sample_products)} total.")


def main():
    print("Setting up ZeroWaste Marketplace initial data...\n")
    
    print("Creating categories...")
    create_categories()
    
    print("\nCreating user profiles...")
    create_user_profiles()
    
    print("\nCreating sample products...")
    create_sample_products()
    
    print("\nMarketplace setup complete!")
    print("\nWhat was created:")
    print("- 8 waste categories for different types of green waste")
    print("- User profiles for existing users")
    print("- 3 sample marketplace products")
    print("\nYou can now:")
    print("- Browse sample products in the marketplace")
    print("- Add more waste products through the API or admin interface")
    print("- Users can browse categories and list their waste products")
    print("- Start trading green waste with the community!")


if __name__ == '__main__':
    main()
