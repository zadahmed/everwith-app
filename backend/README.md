# EverWith Backend

A FastAPI backend for the EverWith mobile application.

## Features

- User authentication (register/login)
- JWT token-based authentication
- Message system
- Event management
- User management
- CORS support for mobile app integration

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables:
```bash
cp env.example .env
# Edit .env with your configuration
```

3. Run the application:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

## API Documentation

Once the server is running, you can access:
- Interactive API docs: `http://localhost:8000/docs`
- ReDoc documentation: `http://localhost:8000/redoc`

## Environment Variables

- `DATABASE_URL`: Database connection string
- `SECRET_KEY`: JWT secret key
- `ALGORITHM`: JWT algorithm (default: HS256)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration time
- `CORS_ORIGINS`: Allowed CORS origins

## Project Structure

```
backend/
├── app/
│   ├── core/
│   │   ├── database.py      # Database configuration
│   │   └── security.py      # Authentication & security
│   ├── models/
│   │   ├── database.py      # SQLAlchemy models
│   │   └── schemas.py       # Pydantic schemas
│   └── routers/
│       ├── auth.py          # Authentication endpoints
│       └── api.py           # Main API endpoints
├── main.py                  # FastAPI application
├── requirements.txt         # Python dependencies
└── env.example             # Environment variables template
```
