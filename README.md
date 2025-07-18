# ZeroWaste Application

A full-stack application for reducing food waste, built with Flutter frontend and Django backend.

## Project Structure

```
zerowaste/
├── frontend/          # Flutter mobile/web application
│   ├── lib/          # Dart source code
│   ├── assets/       # Images, icons, etc.
│   ├── web/          # Web-specific files
│   ├── windows/      # Windows desktop files
│   └── setup_env.bat # Frontend setup script
├── backend/          # Django REST API
│   ├── accounts/     # User authentication
│   ├── api/          # API endpoints
│   ├── manage.py     # Django management script
│   └── setup_env.bat # Backend setup script
└── README.md         # This file
```

## Quick Start

### Backend Setup (Django)

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Run the setup script:
   ```bash
   setup_env.bat
   ```

3. Create a superuser (if needed):
   ```bash
   python manage.py createsuperuser
   ```

4. Start the development server:
   ```bash
   python manage.py runserver
   ```

The backend will be available at `http://127.0.0.1:8000/`

### Frontend Setup (Flutter)

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Run the setup script:
   ```bash
   setup_env.bat
   ```

3. Start the Flutter app:
   ```bash
   flutter run
   ```

## Development

- Make sure the Django backend is running before starting the Flutter frontend
- The frontend is configured to connect to the backend at `http://127.0.0.1:8000/`
- Both environments have separate dependency management

## Features

- User authentication and profiles
- Food item tracking and expiration management
- Recipe suggestions based on available ingredients
- Todo list for food-related tasks
- Dashboard with statistics and insights

## Technologies

- **Frontend**: Flutter (Dart)
- **Backend**: Django (Python)
- **Database**: SQLite (development)
- **Authentication**: JWT tokens