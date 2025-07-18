# ZeroWaste Agent Configuration

## Commands

### Backend (Django)
- **Start server**: `cd backend && python manage.py runserver`
- **Run tests**: `cd backend && python manage.py test`
- **Run single test**: `cd backend && python manage.py test app.tests.TestClass.test_method`
- **Make migrations**: `cd backend && python manage.py makemigrations`
- **Apply migrations**: `cd backend && python manage.py migrate`
- **Create superuser**: `cd backend && python manage.py createsuperuser`

### Frontend (Flutter)
- **Run app**: `cd frontend && flutter run`
- **Run tests**: `cd frontend && flutter test`
- **Run single test**: `cd frontend && flutter test test/widget_test.dart`
- **Build**: `cd frontend && flutter build web`
- **Analyze**: `cd frontend && flutter analyze`

## Architecture
- **Backend**: Django REST API with JWT auth, SQLite database
- **Frontend**: Flutter (Dart) with Provider state management
- **Apps**: `accounts` (user auth), `api` (main endpoints)
- **Database**: SQLite with custom User model in accounts app
- **CORS**: Configured for multiple Flutter dev server ports

## Code Style
- **Backend**: Follow Django conventions, use DRF for API endpoints
- **Frontend**: Follow Flutter/Dart conventions, use Provider for state
- **Environment**: Use .env files for configuration
- **Auth**: JWT tokens with SimpleJWT, custom User model
