from django.contrib.auth import get_user_model
import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'zerowaste_backend.settings')
django.setup()

User = get_user_model()

# Create test users
test_users = [
    {
        'username': 'testuser1',
        'email': 'testuser1@example.com',
        'password': 'password123',
        'first_name': 'Test',
        'last_name': 'User1'
    },
    {
        'username': 'testuser2',
        'email': 'testuser2@example.com',
        'password': 'password123',
        'first_name': 'Test',
        'last_name': 'User2'
    }
]

for user_data in test_users:
    # Check if user already exists
    if not User.objects.filter(username=user_data['username']).exists():
        user = User.objects.create_user(
            username=user_data['username'],
            email=user_data['email'],
            password=user_data['password'],
            first_name=user_data['first_name'],
            last_name=user_data['last_name']
        )
        print(f"Created user: {user.username}")
    else:
        print(f"User {user_data['username']} already exists")

print("Test users creation completed.")