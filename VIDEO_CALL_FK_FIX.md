# Video Call Foreign Key Constraint Fix

## Problem
When trying to start a video call with `lessonId=0` (free conversation mode), the backend throws this error:

```
insert or update on table "video_call_sessions" violates foreign key constraint "video_call_sessions_lesson_id_fkey"
```

## Root Cause
The `video_call_sessions` table has a foreign key constraint on `lesson_id` that doesn't allow NULL values, even though the column is marked as nullable in the TypeORM entity.

## Solution
We need to update the database foreign key constraint to allow NULL values for `lesson_id`.

## Quick Fix

### Option 1: Run the Fix Script (Recommended)
```bash
./backend/fix-video-call-db.sh
```

This script will:
1. Find your PostgreSQL container
2. Drop the existing foreign key constraint
3. Recreate it with `ON DELETE SET NULL` to allow NULL values
4. Verify the change

### Option 2: Manual SQL Execution
If you prefer to run the SQL manually:

```bash
# Start your Docker containers if not running
docker-compose up -d

# Find your postgres container name
docker ps | grep postgres

# Execute the SQL (replace CONTAINER_NAME with your actual container name)
docker exec -i CONTAINER_NAME psql -U postgres -d fluentfly < backend/database/migrations/fix-video-call-fk.sql
```

### Option 3: Using psql directly
If you have psql installed locally:

```bash
psql -U postgres -d fluentfly -f backend/database/migrations/fix-video-call-fk.sql
```

## How It Works

The fix changes the foreign key constraint from:
```sql
FOREIGN KEY (lesson_id) REFERENCES lessons(id)
```

To:
```sql
FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE SET NULL
```

This allows:
- `lesson_id` can be NULL (for free conversation mode)
- When `lessonId=0` is passed from the frontend, the backend converts it to NULL
- The database accepts NULL values for the foreign key

## Testing

After applying the fix, test the video call feature:

1. Start the backend: `docker-compose up -d`
2. Run the fix script: `./backend/fix-video-call-db.sh`
3. Start the mobile app
4. Try to start a video call with free conversation mode (lessonId=0)
5. The call should now start successfully

## Code Flow

1. **Frontend** sends `lessonId=0` for free conversation
2. **RTC Controller** receives the request
3. **RTC Service** converts `lessonId === 0` to `null` (line 119 in rtc.service.ts)
4. **Database** accepts NULL value because of the updated foreign key constraint
5. **Session** is created successfully

## Files Modified

- `backend/database/migrations/fix-video-call-fk.sql` - SQL migration file
- `backend/fix-video-call-db.sh` - Automated fix script
- `VIDEO_CALL_FK_FIX.md` - This documentation

## Prevention

To prevent this issue in the future:
1. Always test with NULL values when designing nullable foreign keys
2. Ensure database constraints match TypeORM entity definitions
3. Add integration tests for edge cases like free conversation mode

## Related Files

- `backend/src/modules/rtc/rtc.service.ts` - Handles lessonId=0 → null conversion
- `backend/src/modules/rtc/entities/video-call-session.entity.ts` - Entity definition
- `backend/database/create_video_tables.sql` - Original table creation

## Status

✅ Fix created and ready to apply
⏳ Waiting for database update
🧪 Needs testing after application
