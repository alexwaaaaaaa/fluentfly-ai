#!/bin/bash

# Fix video call foreign key constraint for LOCAL PostgreSQL
# This script fixes the database to allow NULL lesson_id for free conversation mode

echo "🔧 Fixing video_call_sessions foreign key constraint..."
echo "📍 Using local PostgreSQL database"

# Execute the SQL directly on local PostgreSQL
psql postgresql://postgres:password@localhost:5432/fluentfly <<EOF
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
    echo ""
    echo "If psql is not installed, you can:"
    echo "1. Install PostgreSQL client tools"
    echo "2. Or run the SQL manually in your database client"
    echo ""
    echo "SQL to run:"
    echo "ALTER TABLE video_call_sessions DROP CONSTRAINT IF EXISTS video_call_sessions_lesson_id_fkey;"
    echo "ALTER TABLE video_call_sessions ADD CONSTRAINT video_call_sessions_lesson_id_fkey FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE SET NULL;"
    exit 1
fi
