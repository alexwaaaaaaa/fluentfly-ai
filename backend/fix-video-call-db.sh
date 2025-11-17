#!/bin/bash

# Fix video call foreign key constraint
# This script fixes the database to allow NULL lesson_id for free conversation mode

echo "🔧 Fixing video_call_sessions foreign key constraint..."

# Find the postgres container
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep postgres | head -n 1)

if [ -z "$POSTGRES_CONTAINER" ]; then
    echo "❌ Error: PostgreSQL container not found. Please start Docker containers first."
    echo "Run: docker-compose up -d"
    exit 1
fi

echo "📦 Found PostgreSQL container: $POSTGRES_CONTAINER"

# Execute the migration
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d fluentfly <<EOF
-- Drop the existing foreign key constraint
ALTER TABLE video_call_sessions 
DROP CONSTRAINT IF EXISTS video_call_sessions_lesson_id_fkey;

-- Recreate the foreign key constraint with ON DELETE SET NULL
ALTER TABLE video_call_sessions
ADD CONSTRAINT video_call_sessions_lesson_id_fkey 
FOREIGN KEY (lesson_id) 
REFERENCES lessons(id) 
ON DELETE SET NULL;

-- Verify the change
SELECT 'Foreign key constraint updated successfully!' as status;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database fixed successfully!"
    echo "You can now use lessonId=0 for free conversation mode."
else
    echo "❌ Error: Failed to update database"
    exit 1
fi
