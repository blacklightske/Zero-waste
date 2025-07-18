#!/usr/bin/env python3
"""
Setup script for ZeroWaste Django Backend

This script helps set up the Django backend for the ZeroWaste Flutter app.
"""

import os
import sys
import subprocess
import secrets
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n{description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✓ {description} completed successfully")
        return result
    except subprocess.CalledProcessError as e:
        print(f"✗ {description} failed: {e}")
        if e.stdout:
            print(f"STDOUT: {e.stdout}")
        if e.stderr:
            print(f"STDERR: {e.stderr}")
        return None

def create_env_file():
    """Create .env file with default settings"""
    env_file = Path('.env')
    if env_file.exists():
        print("\n.env file already exists, skipping creation")
        return
    
    print("\nCreating .env file...")
    secret_key = secrets.token_urlsafe(50)
    
    env_content = f"""# Django Settings
SECRET_KEY={secret_key}
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Settings (SQLite for development)
# Uncomment and configure for PostgreSQL in production
# DB_NAME=zerowaste_db
# DB_USER=postgres
# DB_PASSWORD=your-password
# DB_HOST=localhost
# DB_PORT=5432

# Email Settings (for password reset)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# Frontend URL (for password reset links)
FRONTEND_URL=http://localhost:3000
"""
    
    with open(env_file, 'w') as f:
        f.write(env_content)
    
    print("✓ .env file created successfully")

def main():
    """Main setup function"""
    print("ZeroWaste Django Backend Setup")
    print("=" * 40)
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required")
        sys.exit(1)
    
    print(f"Python version: {sys.version}")
    
    # Create virtual environment
    if not Path('venv').exists():
        run_command('python -m venv venv', 'Creating virtual environment')
    else:
        print("\n✓ Virtual environment already exists")
    
    # Activate virtual environment and install dependencies
    if os.name == 'nt':  # Windows
        activate_cmd = 'venv\\Scripts\\activate &&'
    else:  # Unix/Linux/macOS
        activate_cmd = 'source venv/bin/activate &&'
    
    # Install dependencies
    run_command(f'{activate_cmd} pip install --upgrade pip', 'Upgrading pip')
    run_command(f'{activate_cmd} pip install -r requirements.txt', 'Installing dependencies')
    
    # Create .env file
    create_env_file()
    
    # Run Django setup commands
    run_command(f'{activate_cmd} python manage.py makemigrations accounts', 'Creating accounts migrations')
    run_command(f'{activate_cmd} python manage.py makemigrations api', 'Creating API migrations')
    run_command(f'{activate_cmd} python manage.py migrate', 'Running database migrations')
    
    # Ask if user wants to create superuser
    create_superuser = input("\nDo you want to create a Django superuser? (y/n): ").lower().strip()
    if create_superuser in ['y', 'yes']:
        print("\nCreating superuser...")
        subprocess.run(f'{activate_cmd} python manage.py createsuperuser', shell=True)
    
    print("\n" + "=" * 50)
    print("Setup completed successfully!")
    print("\nTo start the development server:")
    if os.name == 'nt':  # Windows
        print("1. venv\\Scripts\\activate")
    else:  # Unix/Linux/macOS
        print("1. source venv/bin/activate")
    print("2. python manage.py runserver")
    print("\nThe API will be available at: http://localhost:8000/")
    print("Admin interface: http://localhost:8000/admin/")
    print("API documentation: http://localhost:8000/api/")
    print("\nDon't forget to update your Flutter app's API base URL!")
    print("=" * 50)

if __name__ == '__main__':
    main()