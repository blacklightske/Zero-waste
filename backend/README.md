# ZeroWaste Django Backend

This is the Django REST API backend for the ZeroWaste Flutter application, replacing Firebase with a traditional SQL database.

## Features

- User authentication with JWT tokens
- Food item management with expiry tracking
- Recipe management (custom and saved recipes)
- Todo management with priority and due dates
- RESTful API endpoints
- Admin interface for data management
- PostgreSQL database support (SQLite for development)

## Setup Instructions

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- PostgreSQL (optional, SQLite is used by default in development)

### Installation

1. **Create a virtual environment:**
   ```bash
   python -m venv venv
   ```

2. **Activate the virtual environment:**
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment configuration:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` file with your configuration.

5. **Run database migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Create a superuser (optional):**
   ```bash
   python manage.py createsuperuser
   ```

7. **Run the development server:**
   ```bash
   python manage.py runserver
   ```

The API will be available at `http://localhost:8000/`

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/profile/` - Get user profile
- `PUT /api/auth/profile/` - Update user profile
- `POST /api/auth/password-reset/` - Request password reset
- `POST /api/auth/password-change/` - Change password

### Food Items
- `GET /api/food-items/` - List food items
- `POST /api/food-items/` - Create food item
- `GET /api/food-items/{id}/` - Get food item details
- `PUT /api/food-items/{id}/` - Update food item
- `DELETE /api/food-items/{id}/` - Delete food item
- `GET /api/food-items/expiring/` - Get expiring food items

### Recipes
- `GET /api/recipes/` - List recipes
- `POST /api/recipes/` - Create recipe
- `GET /api/recipes/{id}/` - Get recipe details
- `PUT /api/recipes/{id}/` - Update recipe
- `DELETE /api/recipes/{id}/` - Delete recipe

### Todos
- `GET /api/todos/` - List todos
- `POST /api/todos/` - Create todo
- `GET /api/todos/{id}/` - Get todo details
- `PUT /api/todos/{id}/` - Update todo
- `DELETE /api/todos/{id}/` - Delete todo
- `PUT /api/todos/{id}/toggle/` - Toggle todo completion
- `GET /api/todos/due-today/` - Get todos due today

### Dashboard
- `GET /api/dashboard/` - Get dashboard summary
- `GET /api/user-data/` - Get all user data

### JWT Tokens
- `POST /api/token/` - Obtain JWT token pair
- `POST /api/token/refresh/` - Refresh access token

## Database Models

### User
- Custom user model with email as username
- Fields: email, username, first_name, last_name, created_at, updated_at

### FoodItem
- Fields: user, name, quantity, expiry_date, created_at, updated_at
- Properties: is_expired, is_expiring_soon, days_until_expiry

### Recipe
- Fields: user, name, description, ingredients (JSON), instructions (JSON), prep_time, cook_time, servings, difficulty, tags (JSON), image_url, is_custom, is_saved, created_at, updated_at
- Properties: total_time, estimated_time

### Todo
- Fields: user, title, description, is_completed, priority, due_date, completed_at, created_at, updated_at
- Properties: is_overdue, is_due_today

## Admin Interface

Access the Django admin at `http://localhost:8000/admin/` to manage users and data.

## Development

### Running Tests
```bash
python manage.py test
```

### Creating Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### Collecting Static Files (for production)
```bash
python manage.py collectstatic
```

## Production Deployment

1. Set `DEBUG=False` in environment variables
2. Configure PostgreSQL database
3. Set up proper CORS origins
4. Use a production WSGI server like Gunicorn
5. Set up SSL certificates
6. Configure email backend for password resets

## Security Notes

- JWT tokens are used for authentication
- CORS is configured for Flutter app origins
- Password validation is enforced
- User data is isolated per user
- Admin interface is available for data management