from django.core.management.base import BaseCommand
from api.models import Category

class Command(BaseCommand):
    help = 'Populate initial marketplace data'

    def handle(self, *args, **options):
        # Create initial categories
        categories = [
            {'name': 'Green Waste', 'description': 'Leaves, grass clippings, yard trimmings, and garden waste', 'icon': 'fa-seedling'},
            {'name': 'Left Over Food', 'description': 'Uneaten meals, excess food, and edible leftovers', 'icon': 'fa-utensils'},
            {'name': 'Opened Products', 'description': 'Partially used spices, butter, condiments, and pantry items', 'icon': 'fa-box-open'},
            {'name': 'Fruits & Vegetables', 'description': 'Fresh produce, vegetable scraps, and fruit waste', 'icon': 'fa-apple-alt'},
            {'name': 'Farm Produce', 'description': 'Agricultural surplus, crops, and farm waste', 'icon': 'fa-tractor'},
            {'name': 'Compost Material', 'description': 'Organic materials suitable for composting', 'icon': 'fa-recycle'},
            {'name': 'Food Scraps', 'description': 'Kitchen waste and organic food materials', 'icon': 'fa-trash'},
            {'name': 'Animal Feed', 'description': 'Safe organic waste suitable for animal feed', 'icon': 'fa-paw'},
        ]

        for cat_data in categories:
            category, created = Category.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'Created category: {category.name}')
                )
            else:
                self.stdout.write(f'Category already exists: {category.name}')

        self.stdout.write(
            self.style.SUCCESS(f'Total categories: {Category.objects.count()}')
        )
