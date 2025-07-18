@echo off
echo Setting up ZeroWaste Frontend Environment...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Clean previous builds
echo Cleaning previous builds...
flutter clean

REM Get dependencies
echo Installing Flutter dependencies...
flutter pub get

REM Generate model files
echo Generating model files...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo Frontend environment setup complete!
echo To run the app, use: flutter run
echo To build for web, use: flutter build web
pause