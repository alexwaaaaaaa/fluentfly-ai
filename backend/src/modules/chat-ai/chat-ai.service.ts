import { Injectable, Logger } from '@nestjs/common';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { RedisService } from '../../common/redis/redis.service';
import { SpeechService } from '../speech/speech.service';
import { ChatResponse } from './dto/chat-turn.dto';
import { FeedbackResponse, DetailedAnalysis, GrammarError } from './dto/feedback-request.dto';
import { WordConfidence } from '../speech/dto/stt-response.dto';

@Injectable()
export class ChatAiService {
  private readonly logger = new Logger(ChatAiService.name);
  private readonly CONTEXT_TTL = 3600; // 1 hour
  private readonly MAX_CONTEXT_MESSAGES = 10;

  constructor(
    private readonly geminiProvider: GeminiProvider,
    private readonly openaiProvider: OpenAiProvider,
    private readonly redisService: RedisService,
    private readonly speechService: SpeechService,
  ) {}

  /**
   * Process a chat turn with dual LLM provider logic
   * @param userText - User's input text
   * @param userId - User ID for context management
   * @param sessionId - Optional session ID
   * @returns Chat response with AI reply and TTS audio
   */
  async processTurn(
    userText: string,
    userId: number,
    sessionId?: string,
  ): Promise<ChatResponse> {
    try {
      // Get conversation context from Redis
      const context = await this.getContext(userId, sessionId);

      // Try Gemini first
      let aiResponse;
      try {
        this.logger.log(`Attempting Gemini for user ${userId}`);
        aiResponse = await this.geminiProvider.generate(userText, context);
      } catch (geminiError) {
        this.logger.warn(
          `Gemini failed for user ${userId}, falling back to OpenAI: ${geminiError.message}`,
        );

        // Fallback to OpenAI
        try {
          aiResponse = await this.openaiProvider.generate(userText, context);
        } catch (openaiError) {
          this.logger.error(
            `Both AI providers failed for user ${userId}: ${openaiError.message}`,
          );

          // Return fallback response
          return await this.getFallbackResponse();
        }
      }

      // Generate TTS audio for AI reply
      const ttsUrl = await this.speechService.textToSpeech(aiResponse.reply);

      // Update context in Redis
      await this.updateContext(userId, userText, aiResponse.reply, sessionId);

      return {
        reply: aiResponse.reply,
        emotion: aiResponse.emotion,
        hint: aiResponse.hint,
        ttsUrl,
      };
    } catch (error) {
      this.logger.error(`Error processing chat turn: ${error.message}`);
      return await this.getFallbackResponse();
    }
  }

  /**
   * Generate feedback for user's speech performance
   * @param transcript - Full conversation transcript
   * @param wordConfidences - Word-level confidence scores from STT
   * @param duration - Duration of speech in seconds
   * @returns Feedback with scores and tips
   */
  async generateFeedback(
    transcript: string,
    wordConfidences: WordConfidence[],
    duration?: number,
  ): Promise<FeedbackResponse> {
    try {
      this.logger.log('Generating feedback for transcript');

      // Calculate pronunciation score from word confidences
      const pronunciation = this.calculatePronunciationScore(wordConfidences);

      // Calculate fluency score
      const fluency = this.calculateFluencyScore(
        transcript,
        wordConfidences,
        duration,
      );

      // Analyze grammar using LLM
      const grammarAnalysis = await this.analyzeGrammar(transcript);

      // Generate actionable tips
      const tips = this.generateTips(
        pronunciation,
        fluency,
        grammarAnalysis.score,
        wordConfidences,
        grammarAnalysis.errors,
      );

      // Build detailed analysis
      const detailedAnalysis = this.buildDetailedAnalysis(
        transcript,
        wordConfidences,
        duration,
        grammarAnalysis.errors,
      );

      return {
        fluency,
        pronunciation,
        grammar: grammarAnalysis.score,
        tips,
        detailedAnalysis,
      };
    } catch (error) {
      this.logger.error(`Error generating feedback: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get conversation context from Redis
   * @param userId - User ID
   * @param sessionId - Optional session ID
   * @returns Array of conversation messages
   */
  private async getContext(
    userId: number,
    sessionId?: string,
  ): Promise<string[]> {
    const key = `chat:context:${userId}${sessionId ? `:${sessionId}` : ''}`;
    const context = await this.redisService.get<string[]>(key);
    return context || [];
  }

  /**
   * Update conversation context in Redis
   * @param userId - User ID
   * @param userText - User's message
   * @param aiReply - AI's reply
   * @param sessionId - Optional session ID
   */
  private async updateContext(
    userId: number,
    userText: string,
    aiReply: string,
    sessionId?: string,
  ): Promise<void> {
    const key = `chat:context:${userId}${sessionId ? `:${sessionId}` : ''}`;
    const context = await this.getContext(userId, sessionId);

    // Add new messages
    context.push(userText, aiReply);

    // Keep only last N messages
    const trimmedContext = context.slice(-this.MAX_CONTEXT_MESSAGES);

    // Store in Redis with TTL
    await this.redisService.set(key, trimmedContext, this.CONTEXT_TTL);
  }

  /**
   * Get fallback response when AI providers fail
   * @returns Fallback chat response
   */
  private async getFallbackResponse(): Promise<ChatResponse> {
    const fallbackText =
      "I'm having trouble connecting right now. Could you try again?";

    return {
      reply: fallbackText,
      emotion: 'neutral',
      hint: 'System is experiencing issues',
      ttsUrl: await this.speechService.textToSpeech(fallbackText),
    };
  }

  /**
   * Calculate pronunciation score from word confidence scores
   * @param wordConfidences - Word-level confidence scores
   * @returns Pronunciation score (0-100)
   */
  private calculatePronunciationScore(
    wordConfidences: WordConfidence[],
  ): number {
    if (wordConfidences.length === 0) return 0;

    const avgConfidence =
      wordConfidences.reduce((sum, word) => sum + word.confidence, 0) /
      wordConfidences.length;

    // Convert 0-1 confidence to 0-100 score
    return Math.round(avgConfidence * 100);
  }

  /**
   * Calculate fluency score based on speech pace and pauses
   * @param transcript - Full transcript
   * @param wordConfidences - Word-level confidence scores
   * @param duration - Duration in seconds
   * @returns Fluency score (0-100)
   */
  private calculateFluencyScore(
    transcript: string,
    wordConfidences: WordConfidence[],
    duration?: number,
  ): number {
    const wordCount = transcript.split(/\s+/).length;

    // Calculate words per minute if duration is provided
    let wpmScore = 50; // Default score
    if (duration && duration > 0) {
      const wpm = (wordCount / duration) * 60;
      // Optimal WPM for English learners: 100-150
      if (wpm >= 100 && wpm <= 150) {
        wpmScore = 100;
      } else if (wpm < 100) {
        wpmScore = Math.max(50, (wpm / 100) * 100);
      } else {
        wpmScore = Math.max(50, 100 - ((wpm - 150) / 50) * 50);
      }
    }

    // Calculate pause frequency from word timings
    let pauseScore = 100;
    if (wordConfidences.length > 1) {
      let longPauses = 0;
      for (let i = 1; i < wordConfidences.length; i++) {
        const gap =
          wordConfidences[i].offset -
          (wordConfidences[i - 1].offset + wordConfidences[i - 1].duration);
        // Gap > 1 second is considered a long pause
        if (gap > 10000000) {
          // 1 second in 100-nanosecond units
          longPauses++;
        }
      }
      pauseScore = Math.max(50, 100 - (longPauses / wordCount) * 200);
    }

    // Combine scores
    return Math.round((wpmScore + pauseScore) / 2);
  }

  /**
   * Analyze grammar using LLM
   * @param transcript - Full transcript
   * @returns Grammar score and errors
   */
  private async analyzeGrammar(
    transcript: string,
  ): Promise<{ score: number; errors: GrammarError[] }> {
    try {
      const prompt = `Analyze the following English text for grammar errors. Return JSON with: {"score": 0-100, "errors": [{"text": "...", "correction": "...", "explanation": "..."}]}

Text: ${transcript}`;

      // Try Gemini first
      let response;
      try {
        const result = await this.geminiProvider.generate(prompt, []);
        response = result.reply;
      } catch {
        // Fallback to OpenAI
        const result = await this.openaiProvider.generate(prompt, []);
        response = result.reply;
      }

      // Parse response
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          score: parsed.score || 100,
          errors: parsed.errors || [],
        };
      }

      return { score: 100, errors: [] };
    } catch (error) {
      this.logger.error(`Grammar analysis failed: ${error.message}`);
      return { score: 100, errors: [] };
    }
  }

  /**
   * Generate actionable tips based on scores
   * @param pronunciation - Pronunciation score
   * @param fluency - Fluency score
   * @param grammar - Grammar score
   * @param wordConfidences - Word-level confidence scores
   * @param grammarErrors - Grammar errors found
   * @returns Array of tips
   */
  private generateTips(
    pronunciation: number,
    fluency: number,
    grammar: number,
    wordConfidences: WordConfidence[],
    grammarErrors: GrammarError[],
  ): string[] {
    const tips: string[] = [];

    // Pronunciation tips
    if (pronunciation < 70) {
      const lowConfWords = wordConfidences
        .filter((w) => w.confidence < 0.7)
        .map((w) => w.word)
        .slice(0, 3);

      if (lowConfWords.length > 0) {
        tips.push(
          `Practice these words: ${lowConfWords.join(', ')}. They had low pronunciation confidence.`,
        );
      } else {
        tips.push(
          'Focus on clear pronunciation. Try speaking more slowly and enunciating each word.',
        );
      }
    }

    // Fluency tips
    if (fluency < 70) {
      tips.push(
        'Try to speak more smoothly without long pauses. Practice speaking continuously.',
      );
    }

    // Grammar tips
    if (grammar < 70 && grammarErrors.length > 0) {
      const firstError = grammarErrors[0];
      tips.push(
        `Grammar tip: ${firstError.explanation}. Say "${firstError.correction}" instead of "${firstError.text}".`,
      );
    }

    // Positive reinforcement
    if (pronunciation >= 80 && fluency >= 80 && grammar >= 80) {
      tips.push('Great job! Your English is improving. Keep practicing!');
    }

    return tips;
  }

  /**
   * Build detailed analysis object
   * @param transcript - Full transcript
   * @param wordConfidences - Word-level confidence scores
   * @param duration - Duration in seconds
   * @param grammarErrors - Grammar errors found
   * @returns Detailed analysis
   */
  private buildDetailedAnalysis(
    transcript: string,
    wordConfidences: WordConfidence[],
    duration: number | undefined,
    grammarErrors: GrammarError[],
  ): DetailedAnalysis {
    const wordCount = transcript.split(/\s+/).length;
    const wordsPerMinute = duration ? (wordCount / duration) * 60 : 0;

    // Count pauses
    let pauseCount = 0;
    if (wordConfidences.length > 1) {
      for (let i = 1; i < wordConfidences.length; i++) {
        const gap =
          wordConfidences[i].offset -
          (wordConfidences[i - 1].offset + wordConfidences[i - 1].duration);
        if (gap > 10000000) {
          pauseCount++;
        }
      }
    }

    // Get low confidence words
    const lowConfidenceWords = wordConfidences
      .filter((w) => w.confidence < 0.7)
      .map((w) => w.word);

    return {
      wordsPerMinute: Math.round(wordsPerMinute),
      pauseCount,
      lowConfidenceWords,
      grammarErrors,
    };
  }
}
