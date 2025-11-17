# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for FluentFly.

## Overview

The FluentFly project uses GitHub Actions for automated testing, building, and deployment. The pipeline consists of multiple workflows that run on different triggers.

## Workflows

### 1. Backend CI (`backend-ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes in `backend/**` or workflow file

**Jobs:**

#### Test Job
- Sets up PostgreSQL and Redis services
- Installs Node.js 20 and dependencies
- Runs linting checks
- Executes unit tests
- Executes integration tests
- Generates code coverage report
- Uploads coverage to Codecov

#### Build Job
- Builds the NestJS application
- Uploads build artifacts
- Runs after test job succeeds

#### Docker Job
- Builds Docker image with multi-stage build
- Pushes to Docker Hub (on main branch only)
- Uses layer caching for faster builds
- Runs after test job succeeds

**Required Secrets:**
- `AZURE_SPEECH_KEY`
- `GEMINI_API_KEY`
- `OPENAI_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`
- `DOCKER_USERNAME` (optional)
- `DOCKER_PASSWORD` (optional)

### 2. Mobile CI (`mobile-ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes in `mobile/**` or workflow file

**Jobs:**

#### Test Job
- Sets up Java 17 and Flutter 3.24
- Runs code formatting checks
- Executes static analysis
- Runs widget tests with coverage
- Uploads coverage to Codecov

#### Build Android Job
- Builds release APK
- Uploads APK as artifact
- Runs after test job succeeds

#### Build iOS Job
- Builds iOS app (no codesign)
- Uploads build artifact
- Runs on macOS runner
- Only on main branch pushes

#### Integration Test Job
- Runs on macOS with iOS Simulator
- Executes integration tests
- Uploads test results
- Continues on error (tests may be flaky)

**Required Secrets:**
- None (uses public APIs for testing)

### 3. Deployment (`deploy.yml`)

**Triggers:**
- Tag creation matching `v*.*.*` (e.g., `v1.0.0`)
- Manual workflow dispatch

**Jobs:**

#### Build and Deploy Job
- Builds and pushes Docker image with version tag
- Builds Android APK
- Creates GitHub release with APK
- Deploys to server via SSH (if configured)
- Runs smoke tests
- Sends Slack notification

**Required Secrets:**
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `DEPLOY_HOST` (optional)
- `DEPLOY_USER` (optional)
- `DEPLOY_SSH_KEY` (optional)
- `API_URL` (for smoke tests)
- `SLACK_WEBHOOK` (optional)

### 4. Pull Request Checks (`pr-checks.yml`)

**Triggers:**
- Pull requests to `main` or `develop` branches

**Jobs:**

#### Lint and Format Check
- Checks backend code linting
- Checks mobile code formatting
- Runs static analysis

#### Security Scan
- Runs Trivy vulnerability scanner
- Uploads results to GitHub Security

#### Dependency Check
- Checks for vulnerable npm packages
- Continues on error (informational)

#### Size Check
- Builds Docker image
- Reports image size
- Validates size is under 200MB

#### PR Summary
- Posts summary comment on PR
- Shows status of all checks

## Setting Up CI/CD

### 1. Configure GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions, and add:

**Required for Backend CI:**
```
AZURE_SPEECH_KEY=your-azure-key
GEMINI_API_KEY=your-gemini-key
OPENAI_API_KEY=your-openai-key
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

**Optional for Docker Hub:**
```
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
```

**Optional for Deployment:**
```
DEPLOY_HOST=your-server-ip
DEPLOY_USER=deploy
DEPLOY_SSH_KEY=your-private-ssh-key
API_URL=https://api.fluentfly.app
SLACK_WEBHOOK=your-slack-webhook-url
```

### 2. Enable GitHub Actions

GitHub Actions are enabled by default. Workflows will run automatically on push/PR.

### 3. Configure Branch Protection

Recommended branch protection rules for `main`:

1. Go to Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Enable:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Required status checks:
     - `Test Backend`
     - `Test Flutter App`
     - `Lint and Format Check`

### 4. Set Up Codecov (Optional)

1. Sign up at [codecov.io](https://codecov.io)
2. Add your repository
3. No additional secrets needed (uses GitHub token)

## Deployment Process

### Automatic Deployment

1. **Create a release tag:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **GitHub Actions will:**
   - Build Docker image with version tag
   - Build Android APK
   - Create GitHub release
   - Deploy to server (if configured)
   - Run smoke tests
   - Send notification

### Manual Deployment

1. Go to Actions → Deploy to Production
2. Click "Run workflow"
3. Select environment (production/staging)
4. Click "Run workflow"

## Monitoring CI/CD

### View Workflow Runs

1. Go to Actions tab in GitHub
2. Select a workflow
3. View run details and logs

### Check Test Coverage

1. View coverage reports in Codecov
2. Coverage badge in README
3. Coverage trends over time

### Docker Image Tags

Images are tagged with:
- `latest` - Latest main branch build
- `main-<sha>` - Specific commit SHA
- `v1.0.0` - Release version tags

## Troubleshooting

### Tests Failing in CI but Passing Locally

**Possible causes:**
- Environment variable differences
- Database state differences
- Timing issues in tests

**Solutions:**
- Check workflow logs for specific errors
- Ensure all required secrets are set
- Run tests with same Node.js version as CI
- Check for race conditions in tests

### Docker Build Failing

**Possible causes:**
- Missing files in build context
- Dependency installation errors
- Out of memory

**Solutions:**
- Check `.dockerignore` file
- Verify all dependencies are in `package.json`
- Review Docker build logs
- Increase runner resources if needed

### Deployment Failing

**Possible causes:**
- SSH connection issues
- Server out of disk space
- Database migration errors

**Solutions:**
- Verify SSH credentials
- Check server disk space
- Review deployment logs
- Test SSH connection manually

### Slow CI Runs

**Optimizations:**
- Use dependency caching
- Use Docker layer caching
- Run jobs in parallel
- Skip unnecessary steps

## Best Practices

### 1. Keep Workflows Fast
- Use caching for dependencies
- Run tests in parallel when possible
- Skip redundant builds

### 2. Secure Secrets
- Never commit secrets to code
- Use GitHub Secrets for sensitive data
- Rotate secrets regularly

### 3. Test Before Merge
- Require status checks on PRs
- Review test results before merging
- Fix failing tests immediately

### 4. Version Control
- Use semantic versioning (v1.0.0)
- Tag releases consistently
- Document breaking changes

### 5. Monitor and Alert
- Set up Slack notifications
- Monitor deployment success rate
- Track test coverage trends

## Maintenance

### Updating Dependencies

1. Update `package.json` or `pubspec.yaml`
2. Run tests locally
3. Create PR
4. CI will test changes
5. Merge after approval

### Updating Workflows

1. Edit workflow files in `.github/workflows/`
2. Test changes on a branch
3. Create PR
4. Review workflow run results
5. Merge after verification

### Rotating Secrets

1. Generate new secret values
2. Update in GitHub Secrets
3. Update in production environment
4. Test deployment
5. Remove old secrets

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Semantic Versioning](https://semver.org/)
- [Codecov Documentation](https://docs.codecov.com/)

## Support

For CI/CD issues:
1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Open an issue with workflow run link
4. Contact DevOps team

---

**Last Updated**: 2025-01-13
