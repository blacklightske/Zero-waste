# ZeroWaste Agent Configuration

## ✅ MARKETPLACE FULLY IMPLEMENTED AND WORKING

### Quick Start Commands
- **Backend**: `cd backend && python manage.py runserver` (http://127.0.0.1:8000)
- **Frontend**: `cd frontend && flutter run -d chrome` (Chrome web app)
- **Admin Panel**: http://127.0.0.1:8000/admin (admin/admin123)
- **API Docs**: http://127.0.0.1:8000/api/

## Commands

### Backend (Django)
- **Start server**: `cd backend && python manage.py runserver`
- **Run tests**: `cd backend && python manage.py test`
- **Run single test**: `cd backend && python manage.py test app.tests.TestClass.test_method`
- **Make migrations**: `cd backend && python manage.py makemigrations`
- **Apply migrations**: `cd backend && python manage.py migrate`
- **Create superuser**: `cd backend && python manage.py createsuperuser`
- **Populate data**: `cd backend && python manage.py populate_initial_data`

### Frontend (Flutter)
- **Run app**: `cd frontend && flutter run -d chrome`
- **Run tests**: `cd frontend && flutter test`
- **Run single test**: `cd frontend && flutter test test/widget_test.dart`
- **Build**: `cd frontend && flutter build web`
- **Analyze**: `cd frontend && flutter analyze`
- **Get dependencies**: `cd frontend && flutter pub get`

## Architecture
- **Backend**: Django REST API with JWT auth, SQLite database, WebSocket support
- **Frontend**: Flutter (Dart) with Provider state management, WebSocket chat
- **Apps**: `accounts` (user auth), `api` (marketplace endpoints)
- **Database**: SQLite with custom User model and marketplace models
- **CORS**: Configured for multiple Flutter dev server ports
- **WebSockets**: Django Channels for real-time messaging

## Marketplace Features ✅
- **8 Product Categories**: Fruits, Garden Waste, Farm Produce, Food Scraps, etc.
- **Product Management**: Create, edit, list, search, filter products
- **Image Upload**: Multiple image support for products
- **Location Services**: GPS-based location picker and distance sorting  
- **Real-time Chat**: WebSocket-powered messaging between users
- **User Profiles**: Complete marketplace user profiles
- **Reviews & Ratings**: Product review and rating system
- **Interest System**: Express interest and contact sellers
- **Advanced Search**: Filter by category, price, location, delivery options

## Code Style
- **Backend**: Follow Django conventions, use DRF for API endpoints
- **Frontend**: Follow Flutter/Dart conventions, use Provider for state
- **Environment**: Use .env files for configuration
- **Auth**: JWT tokens with SimpleJWT, custom User model
- **WebSockets**: Django Channels with proper consumer patterns

## API Endpoints (25+ endpoints)
- **Categories**: `/api/marketplace/categories/`
- **Products**: `/api/marketplace/products/`
- **Interests**: `/api/marketplace/interests/`
- **Messages**: `/api/marketplace/messages/`
- **Reviews**: `/api/marketplace/reviews/`
- **Profiles**: `/api/marketplace/profiles/`
- **Images**: `/api/marketplace/images/`
- **WebSocket**: `ws://127.0.0.1:8000/ws/chat/{product_id}/`

## Test Credentials
- **Admin**: admin / admin123
- **Categories**: 8 initial categories populated
- **Database**: SQLite with all marketplace models
