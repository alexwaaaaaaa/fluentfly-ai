# Authentication Fix Summary

## Issues Fixed

### 1. Token Refresh Infinite Loop (401 Errors)
**Problem:** The mobile app was stuck in an infinite loop trying to refresh expired tokens, causing repeated 401 errors.

**Root Cause:** 
- Token refresh interceptor was triggering even for auth endpoints
- No flag to prevent concurrent refresh attempts
- Refresh failures weren't properly handled

**Solution:**
- Added `_isRefreshing` flag to prevent concurrent refresh attempts
- Excluded auth endpoints (`/auth/`) from token refresh logic
- Properly clear tokens on refresh failure

**Files Modified:**
- `mobile/lib/services/api_service.dart`

### 2. OTP Send Failing with 400 Error
**Problem:** Backend was returning 400 Bad Request when sending OTP.

**Root Causes:**
1. Rate limiting was blocking requests (user had exceeded 5 OTP requests in 15 minutes)
2. Redis service was returning JSON-parsed values instead of strings for OTP storage
3. Redis errors weren't handled gracefully

**Solutions:**
1. **Rate Limit Management:**
   - Clear rate limits using: `redis-cli DEL "otp:ratelimit:+PHONE_NUMBER"`
   - Added better error messages to distinguish rate limiting from other errors

2. **Redis Service Fix:**
   - Modified `get()` method to handle both JSON and string values
   - Modified `set()` method to store strings as-is without JSON encoding
   - Files: `backend/src/common/redis/redis.service.ts`

3. **Graceful Error Handling:**
   - Added try-catch blocks around Redis operations
   - Backend continues with warnings if Redis is unavailable
   - Better error messages for debugging
   - Files: `backend/src/modules/auth/auth.service.ts`

4. **Redis String Handling Fix:**
   - Fixed Redis service to not JSON-parse simple string values
   - Only JSON-parse values that start with `{` or `[` (objects/arrays)
   - This fixed OTP comparison where stored "876313" wasn't matching received "876313"
   - Files: `backend/src/common/redis/redis.service.ts`

## Testing

### Backend Test (Successful)
```bash
# Send OTP
curl -X POST http://localhost:3000/api/auth/phone/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+918434887077"}'
# Response: {"success":true}
# OTP logged in backend: 876313

# Verify OTP
curl -X POST http://localhost:3000/api/auth/phone/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+918434887077", "otp": "876313"}'
# Response: {"accessToken":"...","refreshToken":"...","user":{...}}
```

### Clear Rate Limits (If Needed)
```bash
# Clear rate limit for a specific phone number
redis-cli DEL "otp:ratelimit:+PHONE_NUMBER"

# Clear OTP for a specific phone number
redis-cli DEL "otp:+PHONE_NUMBER"

# View all OTP-related keys
redis-cli KEYS "otp:*"
```

## How to Use

1. **Start Backend:**
   ```bash
   cd backend
   npm run start:dev
   ```

2. **Ensure Redis is Running:**
   ```bash
   redis-cli ping
   # Should return: PONG
   ```

3. **Run Mobile App:**
   ```bash
   cd mobile
   flutter run
   ```

4. **Login Flow:**
   - Enter phone number (e.g., +918434887077)
   - Click "Send OTP"
   - Check backend logs for OTP code
   - Enter OTP in the app
   - Should successfully authenticate

## Rate Limiting Details

- **Max OTP Requests:** 5 per 15 minutes per phone number
- **OTP Expiration:** 10 minutes
- **Rate Limit Reset:** Automatic after 15 minutes, or manual via Redis CLI

## Important Notes

1. **Token Refresh:** Now properly prevents infinite loops by:
   - Checking if already refreshing
   - Excluding auth endpoints from refresh logic
   - Clearing tokens on failure

2. **OTP Development Mode:** OTPs are logged to backend console for testing
   - In production, integrate with SMS service (Twilio, AWS SNS, etc.)

3. **Redis Dependency:** 
   - Backend gracefully handles Redis unavailability
   - Logs warnings but continues operation
   - Rate limiting disabled if Redis is down

## Files Modified

### Mobile App
- `mobile/lib/services/api_service.dart` - Fixed token refresh loop

### Backend
- `backend/src/modules/auth/auth.service.ts` - Added Redis error handling, phone validation
- `backend/src/common/redis/redis.service.ts` - Fixed string/JSON handling

## Next Steps

1. Test complete auth flow in mobile app
2. Verify token refresh works correctly
3. Test rate limiting behavior
4. Consider adding in-memory fallback for OTP storage if Redis is critical
