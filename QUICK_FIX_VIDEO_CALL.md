# 🚀 Quick Fix: Video Call Database Error

## The Error You're Seeing
```
insert or update on table "video_call_sessions" violates foreign key constraint "video_call_sessions_lesson_id_fkey"
```

## What's Happening
When you try to start a video call in "free conversation mode" (without a specific lesson), the app sends `lessonId=0`. The backend correctly converts this to `NULL`, but the database rejects it because of a strict foreign key constraint.

## The Fix (Takes 30 seconds)

### Step 1: Start Docker
```bash
docker-compose up -d
```

### Step 2: Run the Fix Script
```bash
./backend/fix-video-call-db.sh
```

That's it! ✅

## What the Fix Does
- Drops the old foreign key constraint that doesn't allow NULL
- Creates a new one that allows NULL values for free conversation mode
- Verifies the change was successful

## Alternative: Manual Fix
If the script doesn't work, run this SQL directly:

```bash
# Find your postgres container
docker ps | grep postgres

# Run the SQL (replace CONTAINER_NAME)
docker exec -i CONTAINER_NAME psql -U postgres -d fluentfly <<EOF
ALTER TABLE video_call_sessions 
DROP CONSTRAINT IF EXISTS video_call_sessions_lesson_id_fkey;

ALTER TABLE video_call_sessions
ADD CONSTRAINT video_call_sessions_lesson_id_fkey 
FOREIGN KEY (lesson_id) 
REFERENCES lessons(id) 
ON DELETE SET NULL;
EOF
```

## Test It
1. Restart your backend if needed: `docker-compose restart api`
2. Open the mobile app
3. Try starting a video call
4. It should work now! 🎉

## Why This Happened
The database table was created with a foreign key that doesn't match the TypeORM entity definition. The entity says `nullable: true`, but the database constraint was too strict.

## Need Help?
If you still see the error:
1. Make sure Docker containers are running: `docker ps`
2. Check the backend logs: `docker-compose logs api`
3. Verify the fix was applied: Run the script again

---

**Files Created:**
- `backend/fix-video-call-db.sh` - Automated fix script
- `backend/database/migrations/fix-video-call-fk.sql` - SQL migration
- `VIDEO_CALL_FK_FIX.md` - Detailed documentation
