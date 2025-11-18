import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';
import { LessonsService } from './lessons.service';
import { Lesson } from './entities/lesson.entity';
import { Exercise } from './entities/exercise.entity';
import { RedisService } from '../../common/redis/redis.service';

describe('LessonsService', () => {
  let service: LessonsService;
  let lessonRepository: Repository<Lesson>;
  let exerciseRepository: Repository<Exercise>;
  let redisService: RedisService;

  const mockLesson: Lesson = {
    id: 1,
    skill: 'Speaking',
    title: 'Basic Greetings',
    level: 'A1',
    audioUrl: 'https://example.com/audio.mp3',
    description: 'Learn basic greetings',
    meta: { duration: 10 },
    orderIndex: 1,
    exercises: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockExercise: Exercise = {
    id: 1,
    lessonId: 1,
    type: 'mcq',
    question: 'What is hello in English?',
    options: ['Hello', 'Goodbye', 'Thanks'],
    answer: 'Hello',
    audioUrl: null,
    orderIndex: 1,
    createdAt: new Date(),
  };

  const mockLessonRepository = {
    findOne: jest.fn(),
    find: jest.fn(),
    createQueryBuilder: jest.fn(),
  };

  const mockExerciseRepository = {
    find: jest.fn(),
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    invalidate: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LessonsService,
        { provide: getRepositoryToken(Lesson), useValue: mockLessonRepository },
        {
          provide: getRepositoryToken(Exercise),
          useValue: mockExerciseRepository,
        },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<LessonsService>(LessonsService);
    lessonRepository = module.get<Repository<Lesson>>(
      getRepositoryToken(Lesson),
    );
    exerciseRepository = module.get<Repository<Exercise>>(
      getRepositoryToken(Exercise),
    );
    redisService = module.get<RedisService>(RedisService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should return cached lessons if available', async () => {
      const cachedLessons = [mockLesson];
      mockRedisService.get.mockResolvedValue(cachedLessons);

      const result = await service.findAll({});

      expect(result).toEqual(cachedLessons);
      expect(mockRedisService.get).toHaveBeenCalled();
      expect(mockLessonRepository.createQueryBuilder).not.toHaveBeenCalled();
    });

    it('should fetch and cache lessons from database', async () => {
      const lessons = [mockLesson];
      const queryBuilder = {
        orderBy: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(lessons),
      };

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.createQueryBuilder.mockReturnValue(queryBuilder);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.findAll({});

      expect(result).toEqual(lessons);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        expect.any(String),
        lessons,
        3600,
      );
    });

    it('should filter lessons by level', async () => {
      const queryBuilder = {
        orderBy: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockLesson]),
      };

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.createQueryBuilder.mockReturnValue(queryBuilder);
      mockRedisService.set.mockResolvedValue('OK');

      await service.findAll({ level: 'A1' });

      expect(queryBuilder.andWhere).toHaveBeenCalledWith(
        'lesson.level = :level',
        { level: 'A1' },
      );
    });

    it('should filter lessons by search term', async () => {
      const queryBuilder = {
        orderBy: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockLesson]),
      };

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.createQueryBuilder.mockReturnValue(queryBuilder);
      mockRedisService.set.mockResolvedValue('OK');

      await service.findAll({ search: 'greeting' });

      expect(queryBuilder.andWhere).toHaveBeenCalledWith(
        '(lesson.title ILIKE :search OR lesson.skill ILIKE :search)',
        { search: '%greeting%' },
      );
    });
  });

  describe('findOne', () => {
    it('should return cached lesson if available', async () => {
      mockRedisService.get.mockResolvedValue(mockLesson);

      const result = await service.findOne(1);

      expect(result).toEqual(mockLesson);
      expect(mockLessonRepository.findOne).not.toHaveBeenCalled();
    });

    it('should fetch and cache lesson from database', async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(mockLesson);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.findOne(1);

      expect(result).toEqual(mockLesson);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        'lesson:1',
        mockLesson,
        3600,
      );
    });

    it('should throw NotFoundException if lesson not found', async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(null);

      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
      await expect(service.findOne(999)).rejects.toThrow(
        'Lesson with ID 999 not found',
      );
    });
  });

  describe('findOneWithExercises', () => {
    it('should return cached lesson with exercises', async () => {
      const lessonWithExercises = { ...mockLesson, exercises: [mockExercise] };
      mockRedisService.get.mockResolvedValue(lessonWithExercises);

      const result = await service.findOneWithExercises(1);

      expect(result).toEqual(lessonWithExercises);
      expect(mockLessonRepository.findOne).not.toHaveBeenCalled();
    });

    it('should fetch lesson with exercises and sort by orderIndex', async () => {
      const exercise1 = { ...mockExercise, id: 1, orderIndex: 2 };
      const exercise2 = { ...mockExercise, id: 2, orderIndex: 1 };
      const lessonWithExercises = {
        ...mockLesson,
        exercises: [exercise1, exercise2],
      };

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(lessonWithExercises);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.findOneWithExercises(1);

      expect(result.exercises[0].orderIndex).toBe(1);
      expect(result.exercises[1].orderIndex).toBe(2);
    });

    it('should throw NotFoundException if lesson not found', async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(null);

      await expect(service.findOneWithExercises(999)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getExercises', () => {
    it('should return cached exercises if available', async () => {
      const exercises = [mockExercise];
      mockRedisService.get.mockResolvedValue(exercises);

      const result = await service.getExercises(1);

      expect(result).toEqual(exercises);
      expect(mockLessonRepository.findOne).not.toHaveBeenCalled();
    });

    it('should fetch and cache exercises from database', async () => {
      const exercises = [mockExercise];

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(mockLesson);
      mockExerciseRepository.find.mockResolvedValue(exercises);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.getExercises(1);

      expect(result).toEqual(exercises);
      expect(mockRedisService.set).toHaveBeenCalledWith(
        'lesson:1:exercises-only',
        exercises,
        3600,
      );
    });

    it('should throw NotFoundException if lesson not found', async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(null);

      await expect(service.getExercises(999)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should order exercises by orderIndex', async () => {
      const exercises = [mockExercise];

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(mockLesson);
      mockExerciseRepository.find.mockResolvedValue(exercises);
      mockRedisService.set.mockResolvedValue('OK');

      await service.getExercises(1);

      expect(mockExerciseRepository.find).toHaveBeenCalledWith({
        where: { lessonId: 1 },
        order: { orderIndex: 'ASC' },
      });
    });
  });

  describe('invalidateCache', () => {
    it('should invalidate specific lesson cache', async () => {
      mockRedisService.del.mockResolvedValue(1);
      mockRedisService.invalidate.mockResolvedValue(undefined);

      await service.invalidateCache(1);

      expect(mockRedisService.del).toHaveBeenCalledWith('lesson:1');
      expect(mockRedisService.del).toHaveBeenCalledWith('lesson:1:exercises');
      expect(mockRedisService.del).toHaveBeenCalledWith(
        'lesson:1:exercises-only',
      );
      expect(mockRedisService.invalidate).toHaveBeenCalledWith('lessons:*');
    });

    it('should invalidate all lessons cache when no ID provided', async () => {
      mockRedisService.invalidate.mockResolvedValue(undefined);

      await service.invalidateCache();

      expect(mockRedisService.invalidate).toHaveBeenCalledWith('lessons:*');
      expect(mockRedisService.del).not.toHaveBeenCalled();
    });
  });

  describe('caching behavior', () => {
    it('should use different cache keys for different queries', async () => {
      const queryBuilder = {
        orderBy: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([mockLesson]),
      };

      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.createQueryBuilder.mockReturnValue(queryBuilder);
      mockRedisService.set.mockResolvedValue('OK');

      await service.findAll({ level: 'A1' });
      const firstCacheKey = mockRedisService.set.mock.calls[0][0];

      jest.clearAllMocks();
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.createQueryBuilder.mockReturnValue(queryBuilder);
      mockRedisService.set.mockResolvedValue('OK');

      await service.findAll({ level: 'A2' });
      const secondCacheKey = mockRedisService.set.mock.calls[0][0];

      expect(firstCacheKey).not.toBe(secondCacheKey);
    });

    it('should cache with 1 hour TTL', async () => {
      mockRedisService.get.mockResolvedValue(null);
      mockLessonRepository.findOne.mockResolvedValue(mockLesson);
      mockRedisService.set.mockResolvedValue('OK');

      await service.findOne(1);

      expect(mockRedisService.set).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(Object),
        3600,
      );
    });
  });
});
