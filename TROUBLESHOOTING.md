# FluentFly Troubleshooting Guide

This guide helps you diagnose and fix common issues in the FluentFly application.

## Table of Contents

1. [Backend Issues](#backend-issues)
2. [Mobile App Issues](#mobile-app-issues)
3. [Database Issues](#database-issues)
4. [Redis Issues](#redis-issues)
5. [Firebase Issues](#firebase-issues)
6. [AI Service Issues](#ai-service-issues)
7. [Speech Service Issues](#speech-service-issues)
8. [Deployment Issues](#deployment-issues)
9. [Performance Issues](#performance-issues)

## Backend Issues

### Server Won't Start

**Symptoms:**
- Application crashes on startup
- Port already in use error
- Module not found errors

**Solutions:**

1. **Check environment variables:**
   ```bash
   # Verify .env file exists
   ls -la .env
   
   # Validate required variables
   npm run validate:env
   ```

2. **Check port availability:**
   ```bash
   # Find process using port 3000
   lsof -i :3000
   
   # Kill process if needed
   kill -9 <PID>
   ```

3. **Install dependencies:**
   ```bash
   # Clean install
   rm -rf node_modules package-lock.json
   npm install
   ```

4. **Check Node version:**
   ```bash
   node --version  # Should be >= 18.x
   npm --version   # Should be >= 9.x
   ```

### API Returns 500 Errors

**Symptoms:**
- Internal server error responses
- Unhandled exceptions in logs

**Solutions:**

1. **Check logs:**
   ```bash
   # View recent logs
   tail -f logs/error.log
   
   # Or with Docker
   docker logs fluentfly-backend
   ```

2. **Verify database connection:**
   ```bash
   # Test PostgreSQL connection
   psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME
   ```

3. **Check Redis connection:**
   ```bash
   # Test Redis
   redis-cli -h $REDIS_HOST ping
   ```

4. **Review error stack traces:**
   - Check `logs/error.log` for detailed errors
   - Look for missing environment variables
   - Verify external service connectivity

### Authentication Fails

**Symptoms:**
- 401 Unauthorized errors
- "Invalid token" messages
- Firebase auth errors

**Solutions:**

1. **Verify Firebase configuration:**
   ```bash
   # Check Firebase env vars
   echo $FIREBASE_PROJECT_ID
   echo $FIREBASE_CLIENT_EMAIL
   
   # Verify service account file
   cat firebase-service-account.json
   ```

2. **Test token validation:**
   ```bash
   # Use curl to test auth
   curl -H "Authorization: Bearer <token>" \
        http://localhost:3000/auth/me
   ```

3. **Check token expiration:**
   - Firebase tokens expire after 1 hour
   - Implement token refresh logic
   - Verify system clock is correct

### Rate Limiting Issues

**Symptoms:**
- 429 Too Many Requests errors
- Users blocked unexpectedly

**Solutions:**

1. **Check rate limit configuration:**
   ```typescript
   // Verify in .env
   RATE_LIMIT_TTL=60
   RATE_LIMIT_MAX=100
   ```

2. **Review Redis rate limit keys:**
   ```bash
   redis-cli keys "rate-limit:*"
   redis-cli get "rate-limit:user:123"
   ```

3. **Adjust limits if needed:**
   - Increase limits for production
   - Use different limits per endpoint
   - Implement user-tier based limits

## Mobile App Issues

### App Won't Build

**Symptoms:**
- Build fails with errors
- Gradle/CocoaPods errors
- Dependency conflicts

**Solutions:**

1. **Clean build:**
   ```bash
   # Flutter clean
   flutter clean
   flutter pub get
   
   # Android
   cd android && ./gradlew clean && cd ..
   
   # iOS
   cd ios && pod deinstall && pod install && cd ..
   ```

2. **Check Flutter version:**
   ```bash
   flutter --version  # Should be >= 3.16.0
   flutter doctor     # Check for issues
   ```

3. **Update dependencies:**
   ```bash
   flutter pub upgrade
   ```

4. **Check for platform-specific issues:**
   ```bash
   # Android
   flutter build apk --verbose
   
   # iOS
   flutter build ios --verbose
   ```

### App Crashes on Launch

**Symptoms:**
- App closes immediately after opening
- White screen or splash screen freeze

**Solutions:**

1. **Check logs:**
   ```bash
   # Android
   adb logcat | grep Flutter
   
   # iOS
   # View logs in Xcode Console
   ```

2. **Verify Firebase configuration:**
   - Check `google-services.json` (Android)
   - Check `GoogleService-Info.plist` (iOS)
   - Ensure package name matches

3. **Check permissions:**
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   ```

4. **Test on different devices:**
   - Try emulator vs physical device
   - Test different Android/iOS versions

### Network Requests Fail

**Symptoms:**
- "No internet connection" errors
- API requests timeout
- SSL certificate errors

**Solutions:**

1. **Check API URL:**
   ```dart
   // Verify in constants.dart
   static const String apiBaseUrl = 'https://api.fluentfly.app';
   ```

2. **Test connectivity:**
   ```bash
   # From device/emulator
   curl https://api.fluentfly.app/health
   ```

3. **Check network permissions:**
   ```xml
   <!-- Android: AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

4. **Verify SSL certificates:**
   - Ensure API uses valid SSL certificate
   - Check for certificate pinning issues
   - Test with HTTP (development only)

### Audio Not Working

**Symptoms:**
- No sound during lessons
- Microphone not recording
- Audio playback errors

**Solutions:**

1. **Check permissions:**
   ```dart
   // Request microphone permission
   await Permission.microphone.request();
   ```

2. **Verify audio files:**
   ```bash
   # Check if audio URLs are accessible
   curl -I https://storage.../audio.mp3
   ```

3. **Test on different devices:**
   - Some emulators don't support audio
   - Test on physical device
   - Check device volume settings

4. **Review audio service logs:**
   ```dart
   // Enable debug logging
   Logger.level = Level.debug;
   ```

## Database Issues

### Connection Refused

**Symptoms:**
- "Connection refused" errors
- "Could not connect to database"

**Solutions:**

1. **Verify PostgreSQL is running:**
   ```bash
   # Check status
   systemctl status postgresql
   
   # Or with Docker
   docker ps | grep postgres
   ```

2. **Check connection parameters:**
   ```bash
   # Test connection
   psql -h localhost -U postgres -d fluentfly
   ```

3. **Verify firewall rules:**
   ```bash
   # Check if port 5432 is open
   telnet localhost 5432
   ```

4. **Check pg_hba.conf:**
   ```conf
   # Allow connections from application
   host    all    all    0.0.0.0/0    md5
   ```

### Slow Queries

**Symptoms:**
- API responses are slow
- Database CPU usage high
- Timeout errors

**Solutions:**

1. **Identify slow queries:**
   ```sql
   -- Enable query logging
   ALTER SYSTEM SET log_min_duration_statement = 1000;
   
   -- View slow queries
   SELECT query, mean_exec_time, calls
   FROM pg_stat_statements
   ORDER BY mean_exec_time DESC
   LIMIT 10;
   ```

2. **Check missing indexes:**
   ```sql
   -- Find tables without indexes
   SELECT schemaname, tablename, attname
   FROM pg_stats
   WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
   AND n_distinct > 100
   AND correlation < 0.1;
   ```

3. **Analyze query plans:**
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM lessons WHERE level = 'A1';
   ```

4. **Add indexes:**
   ```sql
   -- Add missing indexes
   CREATE INDEX idx_lessons_level ON lessons(level);
   CREATE INDEX idx_progress_user_id ON progress(user_id);
   ```

### Migration Failures

**Symptoms:**
- Migration errors during deployment
- Schema out of sync
- Duplicate key errors

**Solutions:**

1. **Check migration status:**
   ```bash
   npm run migration:show
   ```

2. **Revert failed migration:**
   ```bash
   npm run migration:revert
   ```

3. **Run migrations manually:**
   ```bash
   npm run migration:run
   ```

4. **Reset database (development only):**
   ```bash
   npm run db:reset
   npm run migration:run
   npm run seed:run
   ```

## Redis Issues

### Connection Timeout

**Symptoms:**
- Redis connection errors
- Cache not working
- Timeout errors

**Solutions:**

1. **Verify Redis is running:**
   ```bash
   # Check status
   redis-cli ping
   
   # Or with Docker
   docker ps | grep redis
   ```

2. **Check connection parameters:**
   ```bash
   # Test connection
   redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD
   ```

3. **Verify network connectivity:**
   ```bash
   telnet $REDIS_HOST 6379
   ```

4. **Check Redis logs:**
   ```bash
   # View logs
   tail -f /var/log/redis/redis-server.log
   
   # Or with Docker
   docker logs fluentfly-redis
   ```

### Cache Not Working

**Symptoms:**
- Slow API responses
- Cache misses in logs
- Stale data

**Solutions:**

1. **Verify cache keys:**
   ```bash
   # List all keys
   redis-cli keys "*"
   
   # Check specific key
   redis-cli get "lesson:1"
   ```

2. **Check TTL:**
   ```bash
   # View time to live
   redis-cli ttl "lesson:1"
   ```

3. **Clear cache:**
   ```bash
   # Clear all cache
   redis-cli flushall
   
   # Clear specific pattern
   redis-cli --scan --pattern "lessons:*" | xargs redis-cli del
   ```

4. **Monitor cache hit rate:**
   ```bash
   redis-cli info stats | grep keyspace
   ```

## Firebase Issues

### Authentication Errors

**Symptoms:**
- "Invalid credentials" errors
- Token verification fails
- User creation errors

**Solutions:**

1. **Verify service account:**
   ```bash
   # Check service account file
   cat firebase-service-account.json | jq .
   ```

2. **Test Firebase connection:**
   ```typescript
   // Test in Node.js
   const admin = require('firebase-admin');
   admin.initializeApp({
     credential: admin.credential.cert(serviceAccount)
   });
   ```

3. **Check project ID:**
   ```bash
   # Verify project ID matches
   echo $FIREBASE_PROJECT_ID
   ```

4. **Verify IAM permissions:**
   - Service account needs "Firebase Admin SDK Administrator Service Agent"
   - Check in Google Cloud Console

### OTP Not Sending

**Symptoms:**
- Users don't receive OTP
- SMS/Email not delivered
- "Too many requests" errors

**Solutions:**

1. **Check Firebase Auth settings:**
   - Verify phone auth is enabled
   - Check SMS quota
   - Review rate limits

2. **Test phone number format:**
   ```typescript
   // Must include country code
   const phone = '+1234567890';  // Correct
   const phone = '1234567890';   // Wrong
   ```

3. **Check Firebase quotas:**
   - View in Firebase Console
   - Upgrade plan if needed
   - Implement rate limiting

4. **Test with test phone numbers:**
   ```typescript
   // Add test numbers in Firebase Console
   // Settings > Phone Auth > Test phone numbers
   ```

## AI Service Issues

### OpenAI API Errors

**Symptoms:**
- "Rate limit exceeded" errors
- "Invalid API key" errors
- Slow responses

**Solutions:**

1. **Verify API key:**
   ```bash
   # Test API key
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer $OPENAI_API_KEY"
   ```

2. **Check rate limits:**
   - Review usage in OpenAI dashboard
   - Implement exponential backoff
   - Cache AI responses

3. **Monitor costs:**
   - Set up billing alerts
   - Track token usage
   - Optimize prompts

4. **Handle errors gracefully:**
   ```typescript
   try {
     const response = await openai.chat.completions.create({...});
   } catch (error) {
     if (error.status === 429) {
       // Rate limit - retry with backoff
     } else if (error.status === 500) {
       // OpenAI error - use fallback
     }
   }
   ```

### Gemini API Errors

**Symptoms:**
- "API key not valid" errors
- "Quota exceeded" errors
- Timeout errors

**Solutions:**

1. **Verify API key:**
   ```bash
   curl "https://generativelanguage.googleapis.com/v1/models?key=$GEMINI_API_KEY"
   ```

2. **Check quotas:**
   - View in Google Cloud Console
   - Enable billing if needed
   - Request quota increase

3. **Implement fallback:**
   ```typescript
   // Try Gemini first, fallback to OpenAI
   try {
     return await geminiService.chat(message);
   } catch (error) {
     return await openaiService.chat(message);
   }
   ```

## Speech Service Issues

### TTS Not Working

**Symptoms:**
- No audio generated
- "Invalid voice ID" errors
- Poor audio quality

**Solutions:**

1. **Verify ElevenLabs API key:**
   ```bash
   curl -X GET "https://api.elevenlabs.io/v1/voices" \
     -H "xi-api-key: $ELEVENLABS_API_KEY"
   ```

2. **Check voice ID:**
   ```bash
   # List available voices
   curl "https://api.elevenlabs.io/v1/voices" \
     -H "xi-api-key: $ELEVENLABS_API_KEY"
   ```

3. **Test audio generation:**
   ```bash
   curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
     -H "xi-api-key: $ELEVENLABS_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"text": "Hello world"}' \
     --output test.mp3
   ```

4. **Check storage:**
   - Verify audio files are uploaded to R2/S3
   - Check bucket permissions
   - Test audio URL accessibility

### STT Not Working

**Symptoms:**
- Speech not recognized
- "Invalid audio format" errors
- Low accuracy

**Solutions:**

1. **Verify audio format:**
   ```bash
   # Check audio file
   ffprobe recording.mp3
   
   # Convert if needed
   ffmpeg -i input.m4a -ar 16000 -ac 1 output.mp3
   ```

2. **Check Google Cloud credentials:**
   ```bash
   # Test credentials
   gcloud auth application-default print-access-token
   ```

3. **Improve audio quality:**
   - Use 16kHz sample rate
   - Mono channel
   - Reduce background noise
   - Use supported formats (MP3, WAV, FLAC)

4. **Test recognition:**
   ```bash
   # Test with Google Cloud CLI
   gcloud ml speech recognize recording.mp3 \
     --language-code=en-US
   ```

## Deployment Issues

### Docker Build Fails

**Symptoms:**
- Docker build errors
- Image size too large
- Dependency installation fails

**Solutions:**

1. **Check Dockerfile:**
   ```bash
   # Build with verbose output
   docker build --progress=plain -t fluentfly-backend .
   ```

2. **Clear Docker cache:**
   ```bash
   docker system prune -a
   docker builder prune
   ```

3. **Check .dockerignore:**
   ```
   node_modules
   dist
   .env
   *.log
   ```

4. **Optimize image size:**
   - Use multi-stage builds
   - Remove dev dependencies
   - Use alpine base images

### Kubernetes Deployment Fails

**Symptoms:**
- Pods crash looping
- Image pull errors
- Resource limits exceeded

**Solutions:**

1. **Check pod status:**
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. **Verify secrets:**
   ```bash
   kubectl get secrets
   kubectl describe secret fluentfly-secrets
   ```

3. **Check resource limits:**
   ```yaml
   resources:
     requests:
       memory: "256Mi"
       cpu: "250m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

4. **Review health checks:**
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 3000
     initialDelaySeconds: 30
   ```

## Performance Issues

### High Memory Usage

**Symptoms:**
- Application crashes with OOM
- Slow performance
- Memory leaks

**Solutions:**

1. **Profile memory usage:**
   ```bash
   # Node.js heap snapshot
   node --inspect index.js
   
   # Or use clinic.js
   clinic doctor -- node index.js
   ```

2. **Check for memory leaks:**
   ```typescript
   // Use weak references for caches
   const cache = new WeakMap();
   
   // Clear intervals/timeouts
   clearInterval(intervalId);
   ```

3. **Optimize database queries:**
   - Use pagination
   - Limit result sets
   - Close connections properly

4. **Increase memory limit:**
   ```bash
   # Node.js
   node --max-old-space-size=4096 index.js
   ```

### High CPU Usage

**Symptoms:**
- Slow API responses
- High server load
- Timeout errors

**Solutions:**

1. **Profile CPU usage:**
   ```bash
   # Use clinic.js
   clinic flame -- node index.js
   ```

2. **Optimize hot paths:**
   - Cache expensive computations
   - Use async/await properly
   - Avoid blocking operations

3. **Scale horizontally:**
   - Add more instances
   - Use load balancer
   - Implement caching

4. **Review algorithms:**
   - Optimize O(n²) operations
   - Use efficient data structures
   - Implement pagination

## Getting Help

### Support Channels

- **Email**: support@fluentfly.app
- **Discord**: https://discord.gg/fluentfly
- **GitHub Issues**: https://github.com/fluentfly/issues

### Information to Include

When reporting issues, include:
1. Error messages and stack traces
2. Steps to reproduce
3. Environment details (OS, versions)
4. Relevant logs
5. Screenshots if applicable

### Emergency Contacts

For critical production issues:
- On-call engineer: +1-XXX-XXX-XXXX
- DevOps team: devops@fluentfly.app
- Status page: https://status.fluentfly.app
