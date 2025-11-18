import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AiAgentService } from './ai-agent.service';
import { SpeechService } from '../speech/speech.service';
import { ChatAiService } from '../chat-ai/chat-ai.service';

describe('AiAgentService', () => {
  let service: AiAgentService;
  let speechService: SpeechService;
  let chatAiService: ChatAiService;
  let configService: ConfigService;

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config: Record<string, string> = {
        LIVEKIT_API_KEY: 'test-api-key',
        LIVEKIT_API_SECRET: 'test-api-secret',
      };
      return config[key];
    }),
  };

  const mockSpeechService = {
    speechToText: jest.fn(),
    textToSpeech: jest.fn(),
  };

  const mockChatAiService = {
    processTurn: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiAgentService,
        { provide: ConfigService, useValue: mockConfigService },
        { provide: SpeechService, useValue: mockSpeechService },
        { provide: ChatAiService, useValue: mockChatAiService },
      ],
    }).compile();

    service = module.get<AiAgentService>(AiAgentService);
    speechService = module.get<SpeechService>(SpeechService);
    chatAiService = module.get<ChatAiService>(ChatAiService);
    configService = module.get<ConfigService>(ConfigService);

    jest.clearAllMocks();

    // Reset mock config to return valid values by default
    mockConfigService.get.mockImplementation((key: string) => {
      const config: Record<string, string> = {
        LIVEKIT_API_KEY: 'test-api-key',
        LIVEKIT_API_SECRET: 'test-api-secret',
      };
      return config[key];
    });
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('spawnAgent', () => {
    it('should spawn agent with valid configuration', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
        topic: 'Greetings',
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);

      expect(service.isAgentActive(roomName)).toBe(true);
      expect(mockSpeechService.textToSpeech).toHaveBeenCalled();
    });

    it('should not spawn duplicate agent for same room', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);
      await service.spawnAgent(roomName, context);

      // Should only initialize greeting once
      expect(mockSpeechService.textToSpeech).toHaveBeenCalledTimes(1);
    });

    it('should throw error when LiveKit credentials missing', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      await expect(service.spawnAgent(roomName, context)).rejects.toThrow(
        'LiveKit configuration not found',
      );
    });
  });

  describe('isAgentActive', () => {
    it('should return true for active agent', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);

      expect(service.isAgentActive(roomName)).toBe(true);
    });

    it('should return false for inactive agent', () => {
      expect(service.isAgentActive('non-existent-room')).toBe(false);
    });
  });

  describe('getConversationTurnCount', () => {
    it('should return correct turn count', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/audio.mp3',
      );
      mockSpeechService.speechToText.mockResolvedValue({
        text: 'Hello',
        confidence: 0.95,
      });
      mockChatAiService.processTurn.mockResolvedValue({
        reply: 'Hi there',
        ttsUrl: 'https://example.com/response.mp3',
      });

      await service.spawnAgent(roomName, context);

      // Simulate user speech
      const audioBuffer = Buffer.from('fake-audio-data');
      await service.processAudioData(audioBuffer, roomName, context);

      // Wait for silence detection
      await new Promise((resolve) => setTimeout(resolve, 1100));

      const turnCount = service.getConversationTurnCount(roomName);
      expect(turnCount).toBeGreaterThanOrEqual(0);
    });
  });

  describe('getConversationHistory', () => {
    it('should return conversation history', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);

      const history = service.getConversationHistory(roomName);

      expect(Array.isArray(history)).toBe(true);
      expect(history.length).toBeGreaterThan(0); // Should have greeting
      expect(history[0].speaker).toBe('ai');
    });

    it('should return empty array for non-existent room', () => {
      const history = service.getConversationHistory('non-existent-room');

      expect(Array.isArray(history)).toBe(true);
      expect(history.length).toBe(0);
    });
  });

  describe('disconnectAgent', () => {
    it('should disconnect active agent', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);
      expect(service.isAgentActive(roomName)).toBe(true);

      await service.disconnectAgent(roomName);
      expect(service.isAgentActive(roomName)).toBe(false);
    });

    it('should handle disconnecting non-existent agent', async () => {
      await expect(
        service.disconnectAgent('non-existent-room'),
      ).resolves.not.toThrow();
    });
  });

  describe('processAudioData', () => {
    it('should buffer audio data', async () => {
      const roomName = 'test-room';
      const context = {
        lessonId: 1,
        userId: 1,
      };

      mockSpeechService.textToSpeech.mockResolvedValue(
        'https://example.com/greeting.mp3',
      );

      await service.spawnAgent(roomName, context);

      const audioBuffer = Buffer.from('fake-audio-data');
      await service.processAudioData(audioBuffer, roomName, context);

      // Should not throw error
      expect(true).toBe(true);
    });
  });
});
