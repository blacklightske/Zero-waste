# ZeroWaste Frontend (Flutter)

This is the Flutter frontend for the ZeroWaste application.

## Setup

1. Make sure you have Flutter installed
2. Navigate to the frontend directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate model files:
   ```bash
   flutter packages pub run build_runner build
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Development

- The app connects to the Django backend running on `http://127.0.0.1:8000/`
- Make sure the backend server is running before starting the frontend

## Build

To build for production:
```bash
flutter build web
```