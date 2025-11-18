---
inclusion: always
---

# FluentFly AI - Development Standards

## Code Quality Standards

### TypeScript/NestJS (Backend)
- Use strict TypeScript types - no `any`
- Follow NestJS best practices (modules, services, controllers)
- Use DTOs for all API requests/responses
- Implement proper error handling with custom exceptions
- Add JSDoc comments for complex functions
- Use dependency injection properly

### Dart/Flutter (Mobile)
- Follow Flutter best practices
- Use Provider for state management
- Implement proper error handling
- Add comments for complex widgets
- Use const constructors where possible
- Follow Material Design guidelines

### General Rules
- Write clean, readable code
- Keep functions small and focused (max 50 lines)
- Use meaningful variable names
- No commented-out code in commits
- Follow DRY principle (Don't Repeat Yourself)

## Git Workflow

### Commit Messages
Follow conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

Example: `feat: add user authentication with Firebase`

### Branch Strategy
- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - New features
- `fix/*` - Bug fixes

### Before Committing
1. Test locally
2. Check for console errors
3. Run linter/formatter
4. Review changes

## File Organization

### Backend Structure
```
backend/src/
├── modules/          # Feature modules
│   ├── auth/
│   ├── lessons/
│   └── users/
├── common/           # Shared code
│   ├── decorators/
│   ├── guards/
│   └── interceptors/
└── config/           # Configuration
```

### Mobile Structure
```
mobile/lib/
├── screens/          # UI screens
├── widgets/          # Reusable widgets
├── providers/        # State management
├── services/         # Business logic
├── models/           # Data models
└── config/           # App configuration
```

## Security Best Practices

- Never commit `.env` files
- Never commit API keys or secrets
- Use environment variables for sensitive data
- Validate all user inputs
- Implement rate limiting
- Use HTTPS in production
- Keep dependencies updated

## Performance Guidelines

- Optimize database queries
- Use caching where appropriate (Redis)
- Lazy load images and data
- Minimize API calls
- Use pagination for large datasets
- Optimize bundle size

## Testing Standards

- Write unit tests for critical functions
- Test error scenarios
- Mock external dependencies
- Aim for >70% code coverage
- Test on multiple devices (mobile)

## Documentation

- Update README when adding features
- Document API endpoints
- Add inline comments for complex logic
- Keep deployment docs updated
- Document environment variables

## Code Review Checklist

Before asking for review:
- [ ] Code follows standards
- [ ] Tests pass
- [ ] No console.log() in production code
- [ ] Error handling implemented
- [ ] Documentation updated
- [ ] No sensitive data exposed
- [ ] Performance optimized

## When to Ask Kiro

### Good Questions:
- "How do I implement X feature?"
- "What's the best way to structure Y?"
- "Help me debug this error"
- "Review this code for improvements"

### Provide Context:
- Share relevant code
- Explain what you've tried
- Include error messages
- Mention your goal

## Project-Specific Notes

### Tech Stack
- Backend: NestJS, PostgreSQL, Redis, Docker
- Mobile: Flutter, Provider, LiveKit
- AI: Gemini API, Azure Speech
- Auth: Firebase
- Deployment: AWS EC2, Docker Compose

### Key Features
- Phone OTP authentication
- AI-powered language lessons
- Real-time video calls with AI tutor
- Gamification (XP, badges, streaks)
- Offline support

### Important Files
- `backend/.env` - Backend configuration (NEVER commit)
- `mobile/lib/config/constants.dart` - Mobile config
- `docker-compose.yml` - Local development
- `.gitignore` - Files to ignore

## Quick Commands

### Backend
```bash
cd backend
npm run start:dev    # Development
npm run test         # Run tests
npm run build        # Production build
```

### Mobile
```bash
cd mobile
flutter pub get      # Install dependencies
flutter run          # Run app
flutter test         # Run tests
flutter build apk    # Build Android
```

### Docker
```bash
docker-compose up -d       # Start services
docker-compose logs -f     # View logs
docker-compose down        # Stop services
```

## Deployment Workflow

1. Test locally
2. Commit and push to GitHub
3. SSH to EC2
4. Run: `git pull && docker-compose up -d --build`
5. Verify deployment
6. Monitor logs

## Common Issues & Solutions

### Backend won't start
- Check `.env` file exists
- Verify database connection
- Check Docker containers running

### Mobile build fails
- Run `flutter clean`
- Run `flutter pub get`
- Check for syntax errors

### Database connection error
- Verify PostgreSQL is running
- Check DATABASE_URL in .env
- Ensure port 5432 is not blocked

## Resources

- NestJS Docs: https://docs.nestjs.com
- Flutter Docs: https://docs.flutter.dev
- TypeScript: https://www.typescriptlang.org/docs
- Dart: https://dart.dev/guides
