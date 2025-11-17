-- Fix foreign key constraint for video_call_sessions to allow NULL lesson_id
-- This allows free conversation mode (lessonId = 0 becomes NULL)

-- Drop the existing foreign key constraint
ALTER TABLE video_call_sessions 
DROP CONSTRAINT IF EXISTS video_call_sessions_lesson_id_fkey;

-- Recreate the foreign key constraint with ON DELETE SET NULL
-- This allows lesson_id to be NULL for free conversation mode
ALTER TABLE video_call_sessions
ADD CONSTRAINT video_call_sessions_lesson_id_fkey 
FOREIGN KEY (lesson_id) 
REFERENCES lessons(id) 
ON DELETE SET NULL;

-- Verify the constraint
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='video_call_sessions'
  AND kcu.column_name='lesson_id';
