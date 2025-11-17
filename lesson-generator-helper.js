/**
 * FluentFly Lesson Generator Helper
 * Helps track progress and generate prompts for lesson creation
 */

const LESSON_STRUCTURE = {
  A1: {
    totalLessons: 50,
    wordsPerLesson: { min: 12, max: 15 },
    totalWords: 750,
    duration: 15,
    xpReward: 50,
    topics: [
      // Week 1: Foundation (1-25)
      "Greetings & Introductions",
      "Personal Information",
      "The Alphabet & Spelling",
      "Numbers 0-20",
      "Numbers 20-100",
      "Days of the Week",
      "Months of the Year",
      "Seasons & Basic Weather",
      "Colors (Basic)",
      "Family Members (Immediate)",
      "Body Parts",
      "Common Objects",
      "Classroom Objects",
      "Personal Pronouns",
      "Possessive Adjectives",
      "This/That/These/Those",
      "Simple Present: To Be",
      "Simple Present: To Have",
      "Simple Present: Regular Verbs",
      "Basic Questions (What, Where, Who)",
      "Yes/No Questions",
      "Food & Drinks (Basic)",
      "Fruits",
      "Vegetables",
      "At the Restaurant (Basic)",
      // Week 2: Daily Life (26-50)
      "Shopping for Clothes",
      "Clothing Items",
      "Daily Routines",
      "Telling Time",
      "Time Expressions",
      "Weather Descriptions",
      "Directions & Places",
      "Prepositions of Place",
      "My House & Rooms",
      "Furniture",
      "Countries & Nationalities",
      "Jobs & Occupations",
      "Hobbies & Free Time",
      "Sports & Activities",
      "Animals & Pets",
      "Transportation",
      "At the Doctor",
      "School Subjects",
      "Feelings & Emotions",
      "Describing People",
      "Describing Things",
      "There is/There are",
      "Can/Can't (Ability)",
      "Like/Don't Like",
      "A1 Review & Progress Check"
    ]
  },
  A2: {
    totalLessons: 60,
    wordsPerLesson: { min: 20, max: 25 },
    totalWords: 1500,
    duration: 20,
    xpReward: 75,
    topics: [] // Add A2 topics similarly
  },
  B1: {
    totalLessons: 70,
    wordsPerLesson: { min: 25, max: 30 },
    totalWords: 2100,
    duration: 25,
    xpReward: 100,
    topics: [] // Add B1 topics
  },
  B2: {
    totalLessons: 60,
    wordsPerLesson: { min: 30, max: 35 },
    totalWords: 2100,
    duration: 30,
    xpReward: 150,
    topics: [] // Add B2 topics
  },
  C1: {
    totalLessons: 40,
    wordsPerLesson: { min: 40, max: 50 },
    totalWords: 2000,
    duration: 35,
    xpReward: 200,
    topics: [] // Add C1 topics
  },
  C2: {
    totalLessons: 30,
    wordsPerLesson: { min: 70, max: 80 },
    totalWords: 2400,
    duration: 40,
    xpReward: 250,
    topics: [] // Add C2 topics
  }
};

/**
 * Generate a prompt for a specific lesson
 */
function generateLessonPrompt(level, lessonNumber, topic) {
  const config = LESSON_STRUCTURE[level];
  
  return `
Following the FluentFly content guidelines, generate a complete ${level} lesson on "${topic}".

LESSON METADATA:
- Level: ${level}
- Lesson Number: ${lessonNumber}
- Title: [Create an engaging title for "${topic}"]
- Description: [2-3 sentences about what students will learn]
- Duration: ${config.duration} minutes
- Category: [Choose: grammar/vocabulary/conversation/business/academic]
- XP Reward: ${config.xpReward}
- Order: ${lessonNumber}

VOCABULARY (${config.wordsPerLesson.min}-${config.wordsPerLesson.max} words):
For each word provide:
1. Word/Phrase
2. Part of speech
3. Definition (${level} level appropriate)
4. Example sentence (natural, contextual)
5. Audio text (for text-to-speech)
6. Pronunciation guide (IPA or simplified)
${level !== 'A1' ? '7. Collocations (2-3 common combinations)' : ''}
${['A2', 'B1', 'B2', 'C1', 'C2'].includes(level) ? '8. Synonyms/Antonyms' : ''}
${['B2', 'C1', 'C2'].includes(level) ? '9. Usage notes (formal/informal, British/American)' : ''}
${['B1', 'B2', 'C1', 'C2'].includes(level) ? '10. Word family (related forms)' : ''}

EXERCISES (5 total):

1. MULTIPLE CHOICE (10 points)
   - Question: [Test understanding of key concept]
   - Options: [4 options, one correct]
   - Correct Answer: [Index 0-3]
   - Explanation: [Why this is correct]

2. FILL IN THE BLANKS (10 points)
   - Question: [Sentence with blank using ___]
   - Correct Answer: [The word/phrase]
   - Acceptable Answers: [Array of acceptable variations]
   - Hint: [Helpful clue]

3. LISTENING COMPREHENSION (15 points)
   - Audio Text: [Natural dialogue or monologue for TTS]
   - Question: [About the audio content]
   - Options: [4 options]
   - Correct Answer: [Index 0-3]

4. SPEAKING PRACTICE (20 points)
   - Prompt: [What student should say]
   - Sample Answer: [Example response]
   - Key Phrases: [Array of phrases to include]
   - Evaluation Criteria: [What to assess]

5. QUIZ/GRAMMAR (10 points)
   - Question: [Grammar or usage question]
   - Options: [4 options]
   - Correct Answer: [Index 0-3]
   - Explanation: [Detailed grammar explanation]

GRAMMAR FOCUS:
- Main grammar point for this lesson
- Rules and patterns
- Common mistakes to avoid
- Practice examples

${['B1', 'B2', 'C1', 'C2'].includes(level) ? `
CULTURAL NOTES:
- Cultural context for this topic
- Usage in different English-speaking countries
- Formal vs informal contexts
` : ''}

Format the output as a valid JSON object that can be directly inserted into the database.
Use this structure:
{
  "id": ${lessonNumber},
  "title": "...",
  "description": "...",
  "level": "${level}",
  "category": "...",
  "duration": ${config.duration},
  "order": ${lessonNumber},
  "xpReward": ${config.xpReward},
  "isPublished": true,
  "vocabulary": [...],
  "exercises": [...]
}
`;
}

/**
 * Generate prompts for a batch of lessons
 */
function generateBatchPrompts(level, startLesson, endLesson) {
  const config = LESSON_STRUCTURE[level];
  const prompts = [];
  
  for (let i = startLesson; i <= endLesson; i++) {
    const topicIndex = i - 1;
    if (topicIndex < config.topics.length) {
      const topic = config.topics[topicIndex];
      prompts.push({
        lessonNumber: i,
        topic: topic,
        prompt: generateLessonPrompt(level, i, topic)
      });
    }
  }
  
  return prompts;
}

/**
 * Calculate progress
 */
function calculateProgress(completedLessons) {
  const total = Object.values(LESSON_STRUCTURE).reduce((sum, level) => sum + level.totalLessons, 0);
  const totalWords = Object.values(LESSON_STRUCTURE).reduce((sum, level) => sum + level.totalWords, 0);
  
  const completed = completedLessons.length;
  const percentage = ((completed / total) * 100).toFixed(2);
  
  // Calculate words generated (approximate)
  const wordsByLevel = {};
  completedLessons.forEach(lesson => {
    const level = lesson.level;
    if (!wordsByLevel[level]) wordsByLevel[level] = 0;
    wordsByLevel[level] += lesson.vocabularyCount || 0;
  });
  
  const totalWordsGenerated = Object.values(wordsByLevel).reduce((sum, count) => sum + count, 0);
  const wordPercentage = ((totalWordsGenerated / totalWords) * 100).toFixed(2);
  
  return {
    lessons: {
      completed: completed,
      total: total,
      remaining: total - completed,
      percentage: percentage
    },
    vocabulary: {
      generated: totalWordsGenerated,
      total: totalWords,
      remaining: totalWords - totalWordsGenerated,
      percentage: wordPercentage
    },
    byLevel: Object.keys(LESSON_STRUCTURE).map(level => {
      const levelLessons = completedLessons.filter(l => l.level === level);
      return {
        level: level,
        completed: levelLessons.length,
        total: LESSON_STRUCTURE[level].totalLessons,
        words: wordsByLevel[level] || 0,
        targetWords: LESSON_STRUCTURE[level].totalWords
      };
    })
  };
}

/**
 * Generate a daily task list
 */
function generateDailyTasks(currentDay, lessonsPerDay = 5) {
  const allLessons = [];
  let lessonNumber = 1;
  
  for (const [level, config] of Object.entries(LESSON_STRUCTURE)) {
    for (let i = 0; i < config.topics.length; i++) {
      allLessons.push({
        lessonNumber: lessonNumber++,
        level: level,
        topic: config.topics[i]
      });
    }
  }
  
  const startIndex = (currentDay - 1) * lessonsPerDay;
  const endIndex = Math.min(startIndex + lessonsPerDay, allLessons.length);
  
  return allLessons.slice(startIndex, endIndex);
}

/**
 * Export functions for use
 */
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    LESSON_STRUCTURE,
    generateLessonPrompt,
    generateBatchPrompts,
    calculateProgress,
    generateDailyTasks
  };
}

// Example usage:
console.log("=== FluentFly Lesson Generator Helper ===\n");
console.log("Example: Generate prompt for A1 Lesson 1\n");
console.log(generateLessonPrompt('A1', 1, 'Greetings & Introductions'));
console.log("\n=== Daily Task Example (Day 1) ===\n");
console.log(generateDailyTasks(1, 5));
