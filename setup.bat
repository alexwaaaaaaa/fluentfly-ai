@echo off
REM FluentFly Setup Script for Windows
REM This script sets up the development environment for FluentFly

echo ========================================
echo FluentFly Setup Script
echo ========================================
echo.

REM Check Docker
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed
    echo Please install Docker Desktop from: https://docs.docker.com/desktop/install/windows-install/
    exit /b 1
) else (
    echo [OK] Docker is installed
)

REM Check Docker Compose
docker compose version >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker Compose is not available
    exit /b 1
) else (
    echo [OK] Docker Compose is available
)

REM Check Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Node.js is not installed (optional for local development)
) else (
    echo [OK] Node.js is installed
)

REM Check Flutter
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Flutter is not installed (required for mobile development)
) else (
    echo [OK] Flutter is installed
)

echo.
echo Setting up environment...
echo.

REM Create .env file if it doesn't exist
if not exist backend\.env (
    echo Creating backend\.env from .env.example...
    copy backend\.env.example backend\.env
    echo [OK] Created backend\.env
    echo [WARNING] Please edit backend\.env with your actual credentials
) else (
    echo [INFO] backend\.env already exists
)

echo.
echo Starting services with Docker Compose...
echo.

REM Start Docker services
docker-compose up -d

echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo Checking service health...
echo.

REM Check PostgreSQL
docker-compose exec -T postgres pg_isready -U postgres >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] PostgreSQL is ready
) else (
    echo [ERROR] PostgreSQL is not ready
)

REM Check Redis
docker-compose exec -T redis redis-cli ping >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Redis is ready
) else (
    echo [ERROR] Redis is not ready
)

REM Check API
timeout /t 5 /nobreak >nul
curl -f http://localhost:3000/health >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] API is ready
) else (
    echo [WARNING] API is not ready yet (may need more time to start)
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Services running:
echo   - API:        http://localhost:3000
echo   - API Docs:   http://localhost:3000/api/docs
echo   - PostgreSQL: localhost:5432
echo   - Redis:      localhost:6379
echo   - LiveKit:    localhost:7880
echo.
echo Next steps:
echo   1. Edit backend\.env with your API keys
echo   2. Restart services: docker-compose restart api
echo   3. View logs: docker-compose logs -f
echo   4. Run mobile app: cd mobile ^&^& flutter run
echo.
echo Useful commands:
echo   - Stop services:    docker-compose down
echo   - View logs:        docker-compose logs -f api
echo   - Restart API:      docker-compose restart api
echo.
pause
