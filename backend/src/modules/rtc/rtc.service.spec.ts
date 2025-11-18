import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RtcService } from './rtc.service';
import { VideoCallSession } from './entities/video-call-session.entity';
import { ConversationTurn } from './entities/conversation-turn.entity';

describe('RtcService', () => {
  let service: RtcService;
  let sessionRepository: Repository<VideoCallSession>;
  let turnRepository: Repository<ConversationTurn>;
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

  const mockSessionRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockTurnRepository = {
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RtcService,
        { provide: ConfigService, useValue: mockConfigService },
        {
          provide: getRepositoryToken(VideoCallSession),
          useValue: mockSessionRepository,
        },
        {
          provide: getRepositoryToken(ConversationTurn),
          useValue: mockTurnRepository,
        },
      ],
    }).compile();

    service = module.get<RtcService>(RtcService);
    sessionRepository = module.get<Repository<VideoCallSession>>(
      getRepositoryToken(VideoCallSession),
    );
    turnRepository = module.get<Repository<ConversationTurn>>(
      getRepositoryToken(ConversationTurn),
    );
    configService = module.get<ConfigService>(ConfigService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('generateRoomName', () => {
    it('should generate unique room name with lesson and user ID', () => {
      const lessonId = 5;
      const userId = 10;

      const roomName = service.generateRoomName(lessonId, userId);

      expect(roomName).toMatch(/^lesson-5-10-\d+$/);
    });

    it('should generate different room names for same user and lesson', async () => {
      const lessonId = 5;
      const userId = 10;

      const roomName1 = service.generateRoomName(lessonId, userId);
      // Wait 5ms to ensure different timestamp
      await new Promise((resolve) => setTimeout(resolve, 5));
      const roomName2 = service.generateRoomName(lessonId, userId);

      expect(roomName1).not.toEqual(roomName2);
    });
  });

  describe('createToken', () => {
    it('should create token with valid credentials', async () => {
      const userId = 1;
      const roomName = 'test-room';
      const lessonId = 5;

      const mockSession = {
        id: 1,
        userId,
        roomName,
        lessonId,
        startTime: new Date(),
      };

      mockSessionRepository.create.mockReturnValue(mockSession);
      mockSessionRepository.save.mockResolvedValue(mockSession);

      const result = await service.createToken(userId, roomName, lessonId);

      expect(result).toHaveProperty('token');
      expect(result).toHaveProperty('roomName', roomName);
      expect(result).toHaveProperty('expiresAt');
      expect(result).toHaveProperty('sessionId', 1);
      expect(result.token).toBeTruthy();
    });

    it('should throw error when LiveKit credentials not configured', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      await expect(service.createToken(1, 'test-room')).rejects.toThrow(
        'LiveKit API credentials not configured',
      );
    });
  });

  describe('startSession', () => {
    it('should create and save new session', async () => {
      const userId = 1;
      const roomName = 'test-room';
      const lessonId = 5;

      const mockSession = {
        id: 1,
        userId,
        roomName,
        lessonId,
        startTime: new Date(),
      };

      mockSessionRepository.create.mockReturnValue(mockSession);
      mockSessionRepository.save.mockResolvedValue(mockSession);

      const result = await service.startSession(userId, roomName, lessonId);

      expect(result).toEqual(mockSession);
      expect(mockSessionRepository.create).toHaveBeenCalledWith({
        userId,
        roomName,
        lessonId,
        startTime: expect.any(Date),
      });
      expect(mockSessionRepository.save).toHaveBeenCalled();
    });
  });

  describe('calculateAnalytics', () => {
    it('should calculate analytics correctly for conversation', () => {
      const turns = [
        {
          speaker: 'user' as const,
          text: 'Hello how are you today',
          timestamp: new Date('2024-01-01T10:00:00Z'),
        },
        {
          speaker: 'ai' as const,
          text: 'I am doing well thank you',
          timestamp: new Date('2024-01-01T10:00:05Z'),
        },
        {
          speaker: 'user' as const,
          text: 'That is great to hear',
          timestamp: new Date('2024-01-01T10:00:10Z'),
        },
      ];

      const analytics = service.calculateAnalytics(turns, 60);

      expect(analytics).toHaveProperty('totalSpeakingTime');
      expect(analytics).toHaveProperty('wordsPerMinute');
      expect(analytics).toHaveProperty('pauseCount');
      expect(analytics).toHaveProperty('averagePauseLength');
      expect(analytics).toHaveProperty('fluencyScore');
      expect(analytics).toHaveProperty('turnCount', 3);
      expect(analytics.fluencyScore).toBeGreaterThanOrEqual(0);
      expect(analytics.fluencyScore).toBeLessThanOrEqual(100);
    });

    it('should handle empty conversation', () => {
      const analytics = service.calculateAnalytics([], 60);

      expect(analytics.totalSpeakingTime).toBe(0);
      expect(analytics.wordsPerMinute).toBe(0);
      expect(analytics.pauseCount).toBe(0);
      expect(analytics.turnCount).toBe(0);
    });

    it('should calculate pauses correctly', () => {
      const turns = [
        {
          speaker: 'user' as const,
          text: 'First message',
          timestamp: new Date('2024-01-01T10:00:00Z'),
        },
        {
          speaker: 'user' as const,
          text: 'Second message after long pause',
          timestamp: new Date('2024-01-01T10:00:05Z'),
        },
      ];

      const analytics = service.calculateAnalytics(turns, 60);

      expect(analytics.pauseCount).toBe(1);
      expect(analytics.averagePauseLength).toBeGreaterThan(0);
    });
  });

  describe('endSession', () => {
    it('should end session and save analytics', async () => {
      const sessionId = 1;
      const mockSession = {
        id: sessionId,
        userId: 1,
        roomName: 'test-room',
        startTime: new Date(Date.now() - 60000), // 1 minute ago
      };

      const conversationTurns = [
        {
          speaker: 'user' as const,
          text: 'Hello',
          timestamp: new Date(),
        },
      ];

      mockSessionRepository.findOne.mockResolvedValue(mockSession);
      mockSessionRepository.save.mockResolvedValue({
        ...mockSession,
        endTime: new Date(),
        duration: 60,
      });
      mockTurnRepository.create.mockImplementation((turn) => turn);
      mockTurnRepository.save.mockResolvedValue([]);

      const result = await service.endSession(sessionId, conversationTurns);

      expect(result.endTime).toBeDefined();
      expect(result.duration).toBeGreaterThan(0);
      expect(mockSessionRepository.save).toHaveBeenCalled();
    });

    it('should throw error if session not found', async () => {
      mockSessionRepository.findOne.mockResolvedValue(null);

      await expect(service.endSession(999, [])).rejects.toThrow(
        'Session 999 not found',
      );
    });
  });

  describe('saveConversationTurns', () => {
    it('should save all conversation turns', async () => {
      const sessionId = 1;
      const turns = [
        {
          speaker: 'user' as const,
          text: 'Hello world',
          timestamp: new Date(),
        },
        {
          speaker: 'ai' as const,
          text: 'Hi there',
          timestamp: new Date(),
        },
      ];

      mockTurnRepository.create.mockImplementation((turn) => turn);
      mockTurnRepository.save.mockResolvedValue([]);

      await service.saveConversationTurns(sessionId, turns);

      expect(mockTurnRepository.create).toHaveBeenCalledTimes(2);
      expect(mockTurnRepository.save).toHaveBeenCalled();
    });
  });

  describe('getSession', () => {
    it('should retrieve session with relations', async () => {
      const sessionId = 1;
      const mockSession = {
        id: sessionId,
        userId: 1,
        roomName: 'test-room',
      };

      mockSessionRepository.findOne.mockResolvedValue(mockSession);

      const result = await service.getSession(sessionId);

      expect(result).toEqual(mockSession);
      expect(mockSessionRepository.findOne).toHaveBeenCalledWith({
        where: { id: sessionId },
        relations: ['conversationTurns', 'user', 'lesson'],
      });
    });

    it('should throw error if session not found', async () => {
      mockSessionRepository.findOne.mockResolvedValue(null);

      await expect(service.getSession(999)).rejects.toThrow(
        'Session 999 not found',
      );
    });
  });

  describe('getUserSessions', () => {
    it('should retrieve user sessions with limit', async () => {
      const userId = 1;
      const mockSessions = [
        { id: 1, userId, roomName: 'room1' },
        { id: 2, userId, roomName: 'room2' },
      ];

      mockSessionRepository.find.mockResolvedValue(mockSessions);

      const result = await service.getUserSessions(userId, 10);

      expect(result).toEqual(mockSessions);
      expect(mockSessionRepository.find).toHaveBeenCalledWith({
        where: { userId },
        order: { createdAt: 'DESC' },
        take: 10,
        relations: ['lesson'],
      });
    });
  });
});
