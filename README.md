# FluentFly - AI-Powered English Learning Platform

FluentFly is a full-stack AI-powered English learning mobile application designed for Hindi speakers. The system combines structured lesson flows with real-time AI conversation practice using an animated avatar.

## 🚀 Features

- **Structured Lessons**: Vocabulary, listening, speaking, quiz, and feedback stages
- **AI Conversation Practice**: Real-time chat with AI tutor powered by Gemini/OpenAI
- **Speech Recognition**: Azure Speech Services for TTS and STT
- **Gamification**: XP points, streaks, badges, and leaderboards
- **Offline Support**: Cache lessons and practice without internet
- **Animated Avatar**: Engaging Lottie animations synchronized with audio
- **Progress Tracking**: Detailed analytics and performance metrics

## 📋 Architecture

### Backend (NestJS)
- **Framework**: NestJS with TypeScript
- **Database**: PostgreSQL with TypeORM
- **Cache**: Redis for session management and rate limiting
- **Authentication**: JWT with Google OAuth and Phone OTP
- **AI Integration**: Gemini (primary) and OpenAI (fallback)
- **Speech**: Azure Cognitive Services
- **Storage**: S3/Cloudflare R2 for audio files
- **RTC**: LiveKit for real-time communication

### Mobile (Flutter)
- **Framework**: Flutter 3.24+ with Dart 3
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Local Storage**: Hive and SharedPreferences
- **Audio**: audioplayers and record packages
- **Animations**: Lottie

## 🛠️ Quick Start

### Automated Setup (Recommended)

**Linux/macOS:**
```bash
./setup.sh
```

**Windows:**
```bash
setup.bat
```

This will:
- Check prerequisites
- Create environment configuration
- Start all services with Docker Compose
- Verify service health

### Manual Setup

#### Prerequisites

- **Docker**: 24.0+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: 2.20+ (included with Docker Desktop)
- **Node.js**: 20+ (optional, for local development)
- **Flutter**: 3.24+ (for mobile development)

#### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fluentfly
   ```

2. **Configure environment variables**
   ```bash
   cp backend/.env.example backend/.env
   # Edit backend/.env with your actual credentials
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running**
   ```bash
   docker-compose ps
   curl http://localhost:3000/health
   ```

   The API will be available at `http://localhost:3000`
   API Documentation: `http://localhost:3000/api/docs`

#### Mobile Setup

1. **Navigate to mobile directory**
   ```bash
   cd mobile
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API URL** (if needed)
   
   Edit `mobile/lib/config/constants.dart`:
   ```dart
   const String apiBaseUrl = 'http://localhost:3000/api';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Local Development (Without Docker)

If you prefer to run services locally:

1. **Install and start PostgreSQL**
   ```bash
   # macOS with Homebrew
   brew install postgresql@16
   brew services start postgresql@16
   
   # Create database
   createdb fluentfly
   ```

2. **Install and start Redis**
   ```bash
   # macOS with Homebrew
   brew install redis
   brew services start redis
   ```

3. **Install backend dependencies**
   ```bash
   cd backend
   npm install
   ```

4. **Run database migrations**
   ```bash
   npm run migration:run
   ```

5. **Start the backend server**
   ```bash
   npm run start:dev
   ```

## 📚 API Documentation

Once the backend is running, visit `http://localhost:3000/api/docs` for interactive Swagger documentation.

### Key Endpoints

- **Authentication**: `/api/auth/*`
- **Lessons**: `/api/lessons/*`
- **Progress**: `/api/progress/*`
- **Gamification**: `/api/gamification/*`
- **AI Chat**: `/api/chat/*`
- **Speech**: `/api/speech/*`
- **RTC**: `/api/rtc/*`

## 🗄️ Database Schema

The application uses PostgreSQL with the following main tables:

- `users` - User accounts and profiles
- `lessons` - Lesson content and metadata
- `exercises` - Individual exercises within lessons
- `progress` - User progress tracking
- `chat_sessions` - AI conversation history
- `badges` - Achievement definitions
- `user_badges` - User badge awards

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test                 # Run unit tests
npm run test:e2e        # Run integration tests
npm run test:cov        # Generate coverage report
```

### Mobile Tests
```bash
cd mobile
flutter test            # Run widget tests
flutter test integration_test  # Run integration tests
```

## 🚢 Deployment

### Quick Deployment with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

This will start:
- **Backend API** on port 3000
- **PostgreSQL** on port 5432
- **Redis** on port 6379
- **LiveKit** on ports 7880-7882

### Production Deployment

For detailed production deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

Key topics covered:
- Multi-stage Docker builds
- Environment configuration
- Database backups and migrations
- SSL/TLS setup
- Scaling and load balancing
- Monitoring and health checks
- CI/CD pipeline setup

### CI/CD Pipeline

The project includes GitHub Actions workflows for automated testing and deployment:

- **Backend CI** (`.github/workflows/backend-ci.yml`)
  - Runs unit and integration tests
  - Builds Docker images
  - Generates coverage reports

- **Mobile CI** (`.github/workflows/mobile-ci.yml`)
  - Runs Flutter tests
  - Builds Android APK
  - Builds iOS IPA

- **Deployment** (`.github/workflows/deploy.yml`)
  - Deploys on tag creation (e.g., `v1.0.0`)
  - Builds and pushes Docker images
  - Creates GitHub releases with APK

### Environment Variables

See `backend/.env.example` for all required environment variables.

**Critical Variables:**
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `JWT_SECRET` - Secret key for JWT tokens (32+ characters)
- `JWT_REFRESH_SECRET` - Refresh token secret
- `AZURE_SPEECH_KEY` - Azure Speech Services API key
- `AZURE_SPEECH_REGION` - Azure region (e.g., eastus)
- `GEMINI_API_KEY` - Google Gemini API key
- `OPENAI_API_KEY` - OpenAI API key (fallback)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase client email
- `S3_ENDPOINT` - S3/R2 storage endpoint
- `S3_ACCESS_KEY` - Storage access key
- `S3_SECRET_KEY` - Storage secret key

### Docker Image Size

The production Docker image is optimized to be under 200MB using:
- Multi-stage builds
- Alpine Linux base image
- Production-only dependencies
- Non-root user for security

## 📱 Mobile App Configuration

Update the API URL in `mobile/lib/config/constants.dart`:

```dart
const String apiBaseUrl = 'http://your-api-url:3000/api';
```

## 🎨 Design System

### Colors
- Primary: `#00BFFF` (Sky Blue)
- Accent: `#39FF14` (Neon Green)
- Background: `#0A0E12` (Dark)

### Fonts
- Primary: Poppins
- Secondary: Inter

### Animations
All Lottie animations are stored in `mobile/assets/lottie/`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Troubleshooting

### Backend won't start
- Check if PostgreSQL and Redis are running
- Verify environment variables in `.env`
- Check logs: `docker-compose logs api`

### Database connection errors
- Ensure PostgreSQL is accessible
- Verify `DATABASE_URL` format
- Check firewall settings

### Mobile app can't connect to API
- Verify API URL in constants
- Check if backend is running
- For Android emulator, use `10.0.2.2` instead of `localhost`

## 📞 Support

For issues and questions, please open an issue on GitHub.

---

Built with ❤️ by the FluentFly Team
