@echo off
echo Setting up ZeroWaste Backend Environment...

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Run migrations
echo Running database migrations...
python manage.py migrate

echo.
echo Backend environment setup complete!
echo To start the server, run: python manage.py runserver
echo To create a superuser, run: python manage.py createsuperuser
pause