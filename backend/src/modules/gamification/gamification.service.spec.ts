import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GamificationService } from './gamification.service';
import { User } from '../users/entities/user.entity';
import { Badge } from './entities/badge.entity';
import { UserBadge } from './entities/user-badge.entity';
import { RedisService } from '../../common/redis/redis.service';

describe('GamificationService', () => {
  let service: GamificationService;
  let userRepository: Repository<User>;
  let badgeRepository: Repository<Badge>;
  let userBadgeRepository: Repository<UserBadge>;
  let redisService: RedisService;

  const mockUser: User = {
    id: 1,
    email: 'test@example.com',
    phone: null,
    name: 'Test User',
    xp: 50,
    streak: 3,
    level: 'A1',
    lastActiveDate: new Date('2024-01-01'),
    profileImageUrl: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockBadge: Badge = {
    id: 1,
    name: 'Streak Starter',
    description: 'Complete 7 days streak',
    iconUrl: 'https://example.com/badge.png',
    criteria: { type: 'streak', value: 7 },
    createdAt: new Date(),
  };

  const mockUserRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    save: jest.fn(),
  };

  const mockBadgeRepository = {
    find: jest.fn(),
  };

  const mockUserBadgeRepository = {
    find: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationService,
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        { provide: getRepositoryToken(Badge), useValue: mockBadgeRepository },
        { provide: getRepositoryToken(UserBadge), useValue: mockUserBadgeRepository },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<GamificationService>(GamificationService);
    userRepository = module.get<Repository<User>>(getRepositoryToken(User));
    badgeRepository = module.get<Repository<Badge>>(getRepositoryToken(Badge));
    userBadgeRepository = module.get<Repository<UserBadge>>(getRepositoryToken(UserBadge));
    redisService = module.get<RedisService>(RedisService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('awardXp', () => {
    it('should award XP without streak bonus', async () => {
      const userWithoutStreak = { ...mockUser, streak: 0 };
      mockUserRepository.findOne.mockResolvedValue(userWithoutStreak);
      mockUserRepository.save.mockResolvedValue({ ...userWithoutStreak, xp: 60 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);
      mockRedisService.del.mockResolvedValue(1);

      const result = await service.awardXp(1, 10, 'lesson_complete');

      expect(result.xpAwarded).toBe(10);
      expect(result.totalXp).toBe(60);
      expect(mockUserRepository.save).toHaveBeenCalled();
    });

    it('should award XP with streak bonus', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue({ ...mockUser, xp: 65 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);
      mockRedisService.del.mockResolvedValue(1);

      const result = await service.awardXp(1, 10, 'lesson_complete');

      expect(result.xpAwarded).toBe(25); // 10 + (3 * 5)
      expect(result.totalXp).toBe(75); // 50 + 25
    });

    it('should detect level up', async () => {
      const userNearLevelUp = { ...mockUser, xp: 95, level: 'A1' };
      mockUserRepository.findOne.mockResolvedValue(userNearLevelUp);
      mockUserRepository.save.mockResolvedValue({ ...userNearLevelUp, xp: 110, level: 'A2' });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);
      mockRedisService.del.mockResolvedValue(1);

      const result = await service.awardXp(1, 10, 'lesson_complete');

      expect(result.leveledUp).toBe(true);
      expect(result.newLevel).toBe('A2');
    });

    it('should not level up if threshold not reached', async () => {
      const userWithoutStreak = { ...mockUser, streak: 0, xp: 50 };
      mockUserRepository.findOne.mockResolvedValue(userWithoutStreak);
      mockUserRepository.save.mockImplementation((user) => Promise.resolve(user));
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);
      mockRedisService.del.mockResolvedValue(1);

      const result = await service.awardXp(1, 10, 'lesson_complete');

      expect(result.leveledUp).toBe(false);
      expect(result.newLevel).toBe('A1');
      expect(result.totalXp).toBe(60); // 50 + 10
    });

    it('should invalidate leaderboard cache', async () => {
      mockUserRepository.findOne.mockResolvedValue(mockUser);
      mockUserRepository.save.mockResolvedValue({ ...mockUser, xp: 75 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);
      mockRedisService.del.mockResolvedValue(1);

      await service.awardXp(1, 10, 'lesson_complete');

      expect(mockRedisService.del).toHaveBeenCalledWith('leaderboard:*');
    });
  });

  describe('calculateLevel', () => {
    it('should return A1 for XP 0-99', () => {
      expect(service.calculateLevel(0)).toBe('A1');
      expect(service.calculateLevel(50)).toBe('A1');
      expect(service.calculateLevel(99)).toBe('A1');
    });

    it('should return A2 for XP 100-299', () => {
      expect(service.calculateLevel(100)).toBe('A2');
      expect(service.calculateLevel(200)).toBe('A2');
      expect(service.calculateLevel(299)).toBe('A2');
    });

    it('should return B1 for XP 300-599', () => {
      expect(service.calculateLevel(300)).toBe('B1');
      expect(service.calculateLevel(450)).toBe('B1');
      expect(service.calculateLevel(599)).toBe('B1');
    });

    it('should return B2 for XP 600-999', () => {
      expect(service.calculateLevel(600)).toBe('B2');
      expect(service.calculateLevel(800)).toBe('B2');
      expect(service.calculateLevel(999)).toBe('B2');
    });

    it('should return C1 for XP 1000-1499', () => {
      expect(service.calculateLevel(1000)).toBe('C1');
      expect(service.calculateLevel(1250)).toBe('C1');
      expect(service.calculateLevel(1499)).toBe('C1');
    });

    it('should return C2 for XP 1500+', () => {
      expect(service.calculateLevel(1500)).toBe('C2');
      expect(service.calculateLevel(2000)).toBe('C2');
      expect(service.calculateLevel(10000)).toBe('C2');
    });
  });

  describe('checkStreak', () => {
    it('should initialize streak for first-time user', async () => {
      const newUser = { ...mockUser, streak: 0, lastActiveDate: null };
      mockUserRepository.findOne.mockResolvedValue(newUser);
      mockUserRepository.save.mockResolvedValue({ ...newUser, streak: 1 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);

      const result = await service.checkStreak(1);

      expect(result.streak).toBe(1);
      expect(result.streakIncremented).toBe(true);
    });

    it('should increment streak for consecutive day', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const userWithYesterdayActivity = { ...mockUser, lastActiveDate: yesterday };

      mockUserRepository.findOne.mockResolvedValue(userWithYesterdayActivity);
      mockUserRepository.save.mockResolvedValue({ ...userWithYesterdayActivity, streak: 4 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);

      const result = await service.checkStreak(1);

      expect(result.streak).toBe(4);
      expect(result.streakIncremented).toBe(true);
      expect(result.bonusXp).toBe(20); // 4 * 5
    });

    it('should not increment streak if already active today', async () => {
      const today = new Date();
      const userActiveToday = { ...mockUser, lastActiveDate: today };

      mockUserRepository.findOne.mockResolvedValue(userActiveToday);
      mockUserRepository.save.mockResolvedValue(userActiveToday);

      const result = await service.checkStreak(1);

      expect(result.streakIncremented).toBe(false);
    });

    it('should reset streak if broken', async () => {
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
      const userWithBrokenStreak = { ...mockUser, streak: 5, lastActiveDate: threeDaysAgo };

      mockUserRepository.findOne.mockResolvedValue(userWithBrokenStreak);
      mockUserRepository.save.mockResolvedValue({ ...userWithBrokenStreak, streak: 1 });
      mockBadgeRepository.find.mockResolvedValue([]);
      mockUserBadgeRepository.find.mockResolvedValue([]);

      const result = await service.checkStreak(1);

      expect(result.streak).toBe(1);
      expect(result.streakIncremented).toBe(true);
    });
  });

  describe('getLeaderboard', () => {
    it('should return cached leaderboard if available', async () => {
      const cachedLeaderboard = [
        { rank: 1, userId: 1, name: 'User 1', xp: 1000, level: 'C1', streak: 10, profileImageUrl: null },
        { rank: 2, userId: 2, name: 'User 2', xp: 800, level: 'B2', streak: 5, profileImageUrl: null },
      ];

      mockRedisService.get.mockResolvedValue(cachedLeaderboard);

      const result = await service.getLeaderboard(1, 100);

      expect(result).toEqual(cachedLeaderboard);
      expect(mockUserRepository.find).not.toHaveBeenCalled();
    });

    it('should fetch and cache leaderboard from database', async () => {
      const users = [
        { ...mockUser, id: 1, xp: 1000 },
        { ...mockUser, id: 2, xp: 800 },
      ];

      mockRedisService.get.mockResolvedValue(null);
      mockUserRepository.find.mockResolvedValue(users);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.getLeaderboard(1, 100);

      expect(result).toHaveLength(2);
      expect(result[0].rank).toBe(1);
      expect(result[1].rank).toBe(2);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        'leaderboard:1:100',
        expect.any(Array),
        60,
      );
    });

    it('should handle pagination correctly', async () => {
      const users = [
        { ...mockUser, id: 101, xp: 500 },
        { ...mockUser, id: 102, xp: 450 },
      ];

      mockRedisService.get.mockResolvedValue(null);
      mockUserRepository.find.mockResolvedValue(users);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.getLeaderboard(2, 100);

      expect(result[0].rank).toBe(101); // (2-1) * 100 + 1
      expect(result[1].rank).toBe(102);
    });
  });

  describe('getUserBadges', () => {
    it('should return user badges', async () => {
      const userBadges = [
        { id: 1, userId: 1, badgeId: 1, badge: mockBadge, earnedAt: new Date() },
      ];

      mockUserBadgeRepository.find.mockResolvedValue(userBadges);

      const result = await service.getUserBadges(1);

      expect(result).toHaveLength(1);
      expect(result[0]).toEqual(mockBadge);
    });
  });
});
