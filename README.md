# EverWith App

A complete mobile app starter with Flutter frontend and FastAPI backend.

## Project Structure

```
everwith-app/
├── app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API services
│   │   └── main.dart      # App entry point
│   ├── assets/            # App assets
│   └── pubspec.yaml       # Flutter dependencies
├── backend/               # FastAPI backend
│   ├── app/
│   │   ├── core/          # Core functionality
│   │   ├── models/        # Database & API models
│   │   └── routers/       # API endpoints
│   ├── main.py           # FastAPI application
│   ├── requirements.txt   # Python dependencies
│   └── env.example       # Environment variables
└── README.md             # This file
```

## Quick Start

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
```bash
cp env.example .env
# Edit .env with your configuration
```

4. Run the FastAPI server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

### Mobile App Setup

1. Navigate to the app directory:
```bash
cd app
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the Flutter app:
```bash
flutter run
```

## Features

### Backend (FastAPI)
- ✅ User authentication (register/login)
- ✅ JWT token-based authentication
- ✅ Message system
- ✅ Event management
- ✅ User management
- ✅ CORS support
- ✅ SQLAlchemy ORM
- ✅ Pydantic validation
- ✅ Interactive API documentation

### Mobile App (Flutter)
- ✅ User authentication screens
- ✅ Home dashboard
- ✅ User profile management
- ✅ Navigation between screens
- ✅ State management with Provider
- ✅ HTTP API integration
- ✅ Modern Material Design UI

## API Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `GET /api/messages` - Get user messages
- `POST /api/messages` - Send message
- `GET /api/events` - Get events
- `POST /api/events` - Create event
- `GET /api/users` - Get users

## Development

### Backend Development
- API documentation: `http://localhost:8000/docs`
- ReDoc documentation: `http://localhost:8000/redoc`

### Mobile App Development
- Hot reload is enabled for Flutter development
- State management handled by Provider
- Navigation managed by GoRouter

## Next Steps

1. Set up a proper database (PostgreSQL recommended)
2. Add more authentication features (password reset, email verification)
3. Implement real-time messaging with WebSockets
4. Add push notifications
5. Implement file upload for profile images
6. Add more screens and features to the mobile app
7. Set up CI/CD pipelines
8. Add comprehensive testing

## Technologies Used

### Backend
- FastAPI
- SQLAlchemy
- Pydantic
- JWT Authentication
- Uvicorn
- Python 3.8+

### Mobile App
- Flutter
- Dart
- Provider (State Management)
- GoRouter (Navigation)
- HTTP (API Communication)
- Material Design

## License

This project is open source and available under the MIT License.
