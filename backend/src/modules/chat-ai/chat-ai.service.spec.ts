import { Test, TestingModule } from '@nestjs/testing';
import { ChatAiService } from './chat-ai.service';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { RedisService } from '../../common/redis/redis.service';
import { SpeechService } from '../speech/speech.service';
import { WordConfidence } from '../speech/dto/stt-response.dto';

describe('ChatAiService', () => {
  let service: ChatAiService;
  let geminiProvider: GeminiProvider;
  let openaiProvider: OpenAiProvider;
  let redisService: RedisService;
  let speechService: SpeechService;

  const mockGeminiProvider = {
    generate: jest.fn(),
  };

  const mockOpenAiProvider = {
    generate: jest.fn(),
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  const mockSpeechService = {
    textToSpeech: jest.fn(),
    speechToText: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatAiService,
        { provide: GeminiProvider, useValue: mockGeminiProvider },
        { provide: OpenAiProvider, useValue: mockOpenAiProvider },
        { provide: RedisService, useValue: mockRedisService },
        { provide: SpeechService, useValue: mockSpeechService },
      ],
    }).compile();

    service = module.get<ChatAiService>(ChatAiService);
    geminiProvider = module.get<GeminiProvider>(GeminiProvider);
    openaiProvider = module.get<OpenAiProvider>(OpenAiProvider);
    redisService = module.get<RedisService>(RedisService);
    speechService = module.get<SpeechService>(SpeechService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('processTurn', () => {
    it('should use Gemini as primary provider', async () => {
      const userText = 'Hello, how are you?';
      const userId = 1;
      const aiResponse = {
        reply: 'I am doing great! How can I help you today?',
        emotion: 'happy' as const,
        hint: 'Keep practicing',
      };

      mockRedisService.get.mockResolvedValue([]);
      mockGeminiProvider.generate.mockResolvedValue(aiResponse);
      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://audio.url/tts.mp3',
      );
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.processTurn(userText, userId);

      expect(result).toEqual({
        reply: aiResponse.reply,
        emotion: aiResponse.emotion,
        hint: aiResponse.hint,
        ttsUrl: 'https://audio.url/tts.mp3',
      });
      expect(mockGeminiProvider.generate).toHaveBeenCalled();
      expect(mockOpenAiProvider.generate).not.toHaveBeenCalled();
    });

    it('should fallback to OpenAI when Gemini fails', async () => {
      const userText = 'Hello';
      const userId = 1;
      const aiResponse = {
        reply: 'Hi there!',
        emotion: 'neutral' as const,
      };

      mockRedisService.get.mockResolvedValue([]);
      mockGeminiProvider.generate.mockRejectedValue(new Error('Gemini error'));
      mockOpenAiProvider.generate.mockResolvedValue(aiResponse);
      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://audio.url/tts.mp3',
      );
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.processTurn(userText, userId);

      expect(result.reply).toBe(aiResponse.reply);
      expect(mockGeminiProvider.generate).toHaveBeenCalled();
      expect(mockOpenAiProvider.generate).toHaveBeenCalled();
    });

    it('should return fallback response when both providers fail', async () => {
      const userText = 'Hello';
      const userId = 1;

      mockRedisService.get.mockResolvedValue([]);
      mockGeminiProvider.generate.mockRejectedValue(new Error('Gemini error'));
      mockOpenAiProvider.generate.mockRejectedValue(new Error('OpenAI error'));
      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://audio.url/fallback.mp3',
      );

      const result = await service.processTurn(userText, userId);

      expect(result.reply).toContain('having trouble');
      expect(result.emotion).toBe('neutral');
      expect(mockGeminiProvider.generate).toHaveBeenCalled();
      expect(mockOpenAiProvider.generate).toHaveBeenCalled();
    });

    it('should maintain conversation context', async () => {
      const userText = 'What is your name?';
      const userId = 1;
      const context = ['Hello', 'Hi there!'];
      const aiResponse = {
        reply: 'I am FluentFly!',
        emotion: 'happy' as const,
      };

      mockRedisService.get.mockResolvedValue(context);
      mockGeminiProvider.generate.mockResolvedValue(aiResponse);
      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://audio.url/tts.mp3',
      );
      mockRedisService.set.mockResolvedValue('OK');

      await service.processTurn(userText, userId);

      expect(mockGeminiProvider.generate).toHaveBeenCalledWith(
        userText,
        context,
      );
      expect(mockRedisService.set).toHaveBeenCalled();
      // Verify context was updated with new messages
      const setCall = mockRedisService.set.mock.calls[0];
      expect(setCall[0]).toBe(`chat:context:${userId}`);
      expect(setCall[1]).toContain(userText);
      expect(setCall[1]).toContain(aiResponse.reply);
    });
  });

  describe('generateFeedback', () => {
    it('should calculate pronunciation score from word confidences', async () => {
      const transcript = 'Hello world';
      const wordConfidences: WordConfidence[] = [
        { word: 'Hello', confidence: 0.9, offset: 0, duration: 5000000 },
        { word: 'world', confidence: 0.8, offset: 6000000, duration: 5000000 },
      ];

      mockGeminiProvider.generate.mockResolvedValue({
        reply: '{"score": 95, "errors": []}',
        emotion: 'neutral',
      });

      const result = await service.generateFeedback(
        transcript,
        wordConfidences,
      );

      expect(result.pronunciation).toBe(85); // (0.9 + 0.8) / 2 * 100
      expect(result).toHaveProperty('fluency');
      expect(result).toHaveProperty('grammar');
      expect(result).toHaveProperty('tips');
    });

    it('should calculate fluency score based on speech pace', async () => {
      const transcript = 'Hello world this is a test';
      const wordConfidences: WordConfidence[] = [
        { word: 'Hello', confidence: 0.9, offset: 0, duration: 5000000 },
        { word: 'world', confidence: 0.9, offset: 6000000, duration: 5000000 },
        { word: 'this', confidence: 0.9, offset: 12000000, duration: 5000000 },
        { word: 'is', confidence: 0.9, offset: 18000000, duration: 5000000 },
        { word: 'a', confidence: 0.9, offset: 20000000, duration: 3000000 },
        { word: 'test', confidence: 0.9, offset: 24000000, duration: 5000000 },
      ];
      const duration = 3; // 3 seconds

      mockGeminiProvider.generate.mockResolvedValue({
        reply: '{"score": 90, "errors": []}',
        emotion: 'neutral',
      });

      const result = await service.generateFeedback(
        transcript,
        wordConfidences,
        duration,
      );

      expect(result.fluency).toBeGreaterThan(0);
      expect(result.fluency).toBeLessThanOrEqual(100);
    });

    it('should generate actionable tips based on scores', async () => {
      const transcript = 'Hello world';
      const wordConfidences: WordConfidence[] = [
        { word: 'Hello', confidence: 0.5, offset: 0, duration: 5000000 },
        { word: 'world', confidence: 0.6, offset: 6000000, duration: 5000000 },
      ];

      mockGeminiProvider.generate.mockResolvedValue({
        reply:
          '{"score": 60, "errors": [{"text": "Hello", "correction": "Hello", "explanation": "Pronunciation needs work"}]}',
        emotion: 'neutral',
      });

      const result = await service.generateFeedback(
        transcript,
        wordConfidences,
      );

      expect(result.tips).toBeDefined();
      expect(result.tips.length).toBeGreaterThan(0);
      expect(result.pronunciation).toBe(55); // (0.5 + 0.6) / 2 * 100
    });

    it('should include detailed analysis', async () => {
      const transcript = 'Hello world';
      const wordConfidences: WordConfidence[] = [
        { word: 'Hello', confidence: 0.9, offset: 0, duration: 5000000 },
        { word: 'world', confidence: 0.8, offset: 6000000, duration: 5000000 },
      ];
      const duration = 2;

      mockGeminiProvider.generate.mockResolvedValue({
        reply: '{"score": 90, "errors": []}',
        emotion: 'neutral',
      });

      const result = await service.generateFeedback(
        transcript,
        wordConfidences,
        duration,
      );

      expect(result.detailedAnalysis).toBeDefined();
      expect(result.detailedAnalysis?.wordsPerMinute).toBeGreaterThan(0);
      expect(result.detailedAnalysis?.pauseCount).toBeGreaterThanOrEqual(0);
      expect(result.detailedAnalysis?.lowConfidenceWords).toBeDefined();
    });
  });
});
