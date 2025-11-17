-- FluentFly Lesson Seed Data
-- 10 sample lessons across A1, A2, B1 levels

-- A1 Level Lessons (Beginner)

-- Lesson 1: Basic Greetings
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Greetings', 'Basic Greetings', 'A1', 'Learn how to greet people in English', 
 '{"duration": 10, "xp": 25, "vocabulary": ["hello", "hi", "goodbye", "bye", "good morning", "good evening"]}'::jsonb, 1);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(1, 'vocabulary', 'Listen and repeat: Hello', NULL, '{"text": "Hello", "pronunciation": "həˈloʊ"}'::jsonb, 1),
(1, 'vocabulary', 'Listen and repeat: Good morning', NULL, '{"text": "Good morning", "pronunciation": "ɡʊd ˈmɔːrnɪŋ"}'::jsonb, 2),
(1, 'mcq', 'How do you greet someone in the morning?', 
 '["Good night", "Good morning", "Goodbye", "See you"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(1, 'speaking', 'Say: "Hello, how are you?"', NULL, '{"expected": "Hello, how are you?"}'::jsonb, 4),
(1, 'fill_blank', 'Complete: Good _____ (evening)', '["morning", "evening", "night", "afternoon"]'::jsonb, '{"correct": 1}'::jsonb, 5);

-- Lesson 2: Introductions
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Introductions', 'Introducing Yourself', 'A1', 'Learn how to introduce yourself in English', 
 '{"duration": 12, "xp": 25, "vocabulary": ["name", "my", "I am", "nice to meet you", "pleased"]}'::jsonb, 2);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(2, 'vocabulary', 'Listen and repeat: My name is...', NULL, '{"text": "My name is", "pronunciation": "maɪ neɪm ɪz"}'::jsonb, 1),
(2, 'vocabulary', 'Listen and repeat: Nice to meet you', NULL, '{"text": "Nice to meet you", "pronunciation": "naɪs tuː miːt juː"}'::jsonb, 2),
(2, 'mcq', 'What do you say when you meet someone for the first time?', 
 '["Goodbye", "Nice to meet you", "See you later", "Good night"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(2, 'speaking', 'Say: "My name is John. Nice to meet you."', NULL, '{"expected": "My name is John. Nice to meet you."}'::jsonb, 4),
(2, 'fill_blank', 'Complete: Nice to _____ you', '["see", "meet", "know", "find"]'::jsonb, '{"correct": 1}'::jsonb, 5);

-- Lesson 3: Daily Routine (A1)
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Daily Life', 'My Daily Routine', 'A1', 'Learn to talk about your daily activities', 
 '{"duration": 15, "xp": 30, "vocabulary": ["wake up", "eat", "sleep", "work", "study", "play"]}'::jsonb, 3);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(3, 'vocabulary', 'Listen and repeat: I wake up', NULL, '{"text": "I wake up", "pronunciation": "aɪ weɪk ʌp"}'::jsonb, 1),
(3, 'vocabulary', 'Listen and repeat: I eat breakfast', NULL, '{"text": "I eat breakfast", "pronunciation": "aɪ iːt ˈbrekfəst"}'::jsonb, 2),
(3, 'mcq', 'What do you do in the morning?', 
 '["I sleep", "I wake up", "I go to bed", "I have dinner"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(3, 'listening', 'Listen and choose: What time does she wake up?', 
 '["6 AM", "7 AM", "8 AM", "9 AM"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(3, 'speaking', 'Say: "I wake up at 7 AM every day."', NULL, '{"expected": "I wake up at 7 AM every day."}'::jsonb, 5);

-- A2 Level Lessons (Elementary)

-- Lesson 4: Travel - At the Airport
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Travel', 'At the Airport', 'A2', 'Learn essential phrases for airport travel', 
 '{"duration": 15, "xp": 30, "vocabulary": ["ticket", "passport", "boarding pass", "gate", "flight", "luggage"]}'::jsonb, 4);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(4, 'vocabulary', 'Listen and repeat: Boarding pass', NULL, '{"text": "Boarding pass", "pronunciation": "ˈbɔːrdɪŋ pæs"}'::jsonb, 1),
(4, 'vocabulary', 'Listen and repeat: Where is gate 5?', NULL, '{"text": "Where is gate 5?", "pronunciation": "weər ɪz ɡeɪt faɪv"}'::jsonb, 2),
(4, 'mcq', 'What do you need to board a plane?', 
 '["A ticket", "A boarding pass", "A passport", "All of the above"]'::jsonb, '{"correct": 3}'::jsonb, 3),
(4, 'listening', 'Listen: Which gate is the flight departing from?', 
 '["Gate 3", "Gate 5", "Gate 7", "Gate 9"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(4, 'speaking', 'Say: "Excuse me, where is gate 5?"', NULL, '{"expected": "Excuse me, where is gate 5?"}'::jsonb, 5);

-- Lesson 5: Shopping
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Shopping', 'At the Store', 'A2', 'Learn how to shop and ask for prices', 
 '{"duration": 15, "xp": 30, "vocabulary": ["buy", "price", "cost", "expensive", "cheap", "how much"]}'::jsonb, 5);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(5, 'vocabulary', 'Listen and repeat: How much is this?', NULL, '{"text": "How much is this?", "pronunciation": "haʊ mʌtʃ ɪz ðɪs"}'::jsonb, 1),
(5, 'vocabulary', 'Listen and repeat: That is expensive', NULL, '{"text": "That is expensive", "pronunciation": "ðæt ɪz ɪkˈspensɪv"}'::jsonb, 2),
(5, 'mcq', 'What do you say to ask the price?', 
 '["How are you?", "How much is this?", "What is your name?", "Where is it?"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(5, 'listening', 'Listen: How much does the shirt cost?', 
 '["$10", "$20", "$30", "$40"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(5, 'speaking', 'Say: "I would like to buy this shirt."', NULL, '{"expected": "I would like to buy this shirt."}'::jsonb, 5);

-- Lesson 6: Food and Restaurants
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Food', 'Ordering Food', 'A2', 'Learn how to order food at a restaurant', 
 '{"duration": 15, "xp": 30, "vocabulary": ["menu", "order", "waiter", "delicious", "hungry", "thirsty"]}'::jsonb, 6);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(6, 'vocabulary', 'Listen and repeat: Can I see the menu?', NULL, '{"text": "Can I see the menu?", "pronunciation": "kæn aɪ siː ðə ˈmenjuː"}'::jsonb, 1),
(6, 'vocabulary', 'Listen and repeat: I would like to order', NULL, '{"text": "I would like to order", "pronunciation": "aɪ wʊd laɪk tuː ˈɔːrdər"}'::jsonb, 2),
(6, 'mcq', 'What do you say to the waiter when you want to order?', 
 '["I am hungry", "I would like to order", "Give me food", "I want menu"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(6, 'listening', 'Listen: What did she order?', 
 '["Pizza", "Pasta", "Salad", "Soup"]'::jsonb, '{"correct": 0}'::jsonb, 4),
(6, 'speaking', 'Say: "I would like to order a pizza, please."', NULL, '{"expected": "I would like to order a pizza, please."}'::jsonb, 5);

-- B1 Level Lessons (Intermediate)

-- Lesson 7: Weather
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Weather', 'Talking About Weather', 'B1', 'Learn to describe weather conditions', 
 '{"duration": 18, "xp": 35, "vocabulary": ["sunny", "rainy", "cloudy", "windy", "temperature", "forecast"]}'::jsonb, 7);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(7, 'vocabulary', 'Listen and repeat: It is sunny today', NULL, '{"text": "It is sunny today", "pronunciation": "ɪt ɪz ˈsʌni təˈdeɪ"}'::jsonb, 1),
(7, 'vocabulary', 'Listen and repeat: The weather forecast', NULL, '{"text": "The weather forecast", "pronunciation": "ðə ˈweðər ˈfɔːrkæst"}'::jsonb, 2),
(7, 'mcq', 'How do you describe a day with lots of clouds?', 
 '["It is sunny", "It is cloudy", "It is rainy", "It is windy"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(7, 'listening', 'Listen: What will the weather be like tomorrow?', 
 '["Sunny", "Rainy", "Cloudy", "Snowy"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(7, 'speaking', 'Say: "The weather forecast says it will rain tomorrow."', NULL, '{"expected": "The weather forecast says it will rain tomorrow."}'::jsonb, 5);

-- Lesson 8: Hobbies and Interests
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Hobbies', 'My Hobbies', 'B1', 'Learn to talk about your hobbies and interests', 
 '{"duration": 18, "xp": 35, "vocabulary": ["hobby", "interest", "enjoy", "free time", "activity", "passion"]}'::jsonb, 8);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(8, 'vocabulary', 'Listen and repeat: In my free time', NULL, '{"text": "In my free time", "pronunciation": "ɪn maɪ friː taɪm"}'::jsonb, 1),
(8, 'vocabulary', 'Listen and repeat: I enjoy reading', NULL, '{"text": "I enjoy reading", "pronunciation": "aɪ ɪnˈdʒɔɪ ˈriːdɪŋ"}'::jsonb, 2),
(8, 'mcq', 'What is another word for hobby?', 
 '["Work", "Interest", "Job", "Duty"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(8, 'listening', 'Listen: What is his favorite hobby?', 
 '["Reading", "Swimming", "Cooking", "Painting"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(8, 'speaking', 'Say: "In my free time, I enjoy playing guitar."', NULL, '{"expected": "In my free time, I enjoy playing guitar."}'::jsonb, 5);

-- Lesson 9: Work and Career
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Work', 'Talking About Work', 'B1', 'Learn to discuss your job and career', 
 '{"duration": 20, "xp": 35, "vocabulary": ["job", "career", "profession", "colleague", "office", "salary"]}'::jsonb, 9);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(9, 'vocabulary', 'Listen and repeat: What do you do for a living?', NULL, '{"text": "What do you do for a living?", "pronunciation": "wʌt duː juː duː fɔːr ə ˈlɪvɪŋ"}'::jsonb, 1),
(9, 'vocabulary', 'Listen and repeat: I work as a teacher', NULL, '{"text": "I work as a teacher", "pronunciation": "aɪ wɜːrk æz ə ˈtiːtʃər"}'::jsonb, 2),
(9, 'mcq', 'How do you ask someone about their job?', 
 '["What is your name?", "What do you do?", "Where are you from?", "How old are you?"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(9, 'listening', 'Listen: What is her profession?', 
 '["Doctor", "Teacher", "Engineer", "Lawyer"]'::jsonb, '{"correct": 2}'::jsonb, 4),
(9, 'speaking', 'Say: "I work as a software engineer at a tech company."', NULL, '{"expected": "I work as a software engineer at a tech company."}'::jsonb, 5);

-- Lesson 10: Family
INSERT INTO lessons (skill, title, level, description, meta, order_index) VALUES
('Family', 'My Family', 'B1', 'Learn to talk about your family members', 
 '{"duration": 20, "xp": 35, "vocabulary": ["mother", "father", "sister", "brother", "parents", "siblings"]}'::jsonb, 10);

INSERT INTO exercises (lesson_id, type, question, options, answer, order_index) VALUES
(10, 'vocabulary', 'Listen and repeat: I have two siblings', NULL, '{"text": "I have two siblings", "pronunciation": "aɪ hæv tuː ˈsɪblɪŋz"}'::jsonb, 1),
(10, 'vocabulary', 'Listen and repeat: My family is very close', NULL, '{"text": "My family is very close", "pronunciation": "maɪ ˈfæməli ɪz ˈveri kloʊs"}'::jsonb, 2),
(10, 'mcq', 'What do you call your mother and father together?', 
 '["Siblings", "Parents", "Relatives", "Cousins"]'::jsonb, '{"correct": 1}'::jsonb, 3),
(10, 'listening', 'Listen: How many siblings does he have?', 
 '["One", "Two", "Three", "None"]'::jsonb, '{"correct": 1}'::jsonb, 4),
(10, 'speaking', 'Say: "I have one brother and one sister."', NULL, '{"expected": "I have one brother and one sister."}'::jsonb, 5);

-- Badge Definitions
INSERT INTO badges (name, description, icon_url, criteria) VALUES
('Streak Starter', 'Practice for 7 consecutive days', NULL, '{"type": "streak", "value": 7}'::jsonb),
('Vocabulary Hero', 'Learn 100 new words', NULL, '{"type": "vocabulary", "value": 100}'::jsonb),
('Fluent Flyer', 'Complete 50 lessons', NULL, '{"type": "lessons_completed", "value": 50}'::jsonb),
('Early Bird', 'Complete your first lesson', NULL, '{"type": "lessons_completed", "value": 1}'::jsonb),
('Conversation Master', 'Complete 20 speaking exercises', NULL, '{"type": "speaking_exercises", "value": 20}'::jsonb);
