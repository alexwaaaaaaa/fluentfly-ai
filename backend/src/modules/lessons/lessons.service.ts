import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Lesson } from './entities/lesson.entity';
import { Exercise } from './entities/exercise.entity';
import { RedisService } from '../../common/redis/redis.service';
import { LessonQueryDto } from './dto/lesson-query.dto';

@Injectable()
export class LessonsService {
  private readonly logger = new Logger(LessonsService.name);
  private readonly CACHE_TTL = 3600; // 1 hour

  constructor(
    @InjectRepository(Lesson)
    private readonly lessonRepository: Repository<Lesson>,
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    private readonly redisService: RedisService,
  ) {}

  async findAll(query: LessonQueryDto): Promise<Lesson[]> {
    const cacheKey = `lessons:${JSON.stringify(query)}`;

    // Try cache first
    const cached = await this.redisService.get<Lesson[]>(cacheKey);
    if (cached) {
      this.logger.log(`Cache hit for lessons query: ${cacheKey}`);
      return cached;
    }

    // Build query
    const queryBuilder = this.lessonRepository
      .createQueryBuilder('lesson')
      .orderBy('lesson.orderIndex', 'ASC');

    // Apply filters
    if (query.level) {
      queryBuilder.andWhere('lesson.level = :level', { level: query.level });
    }

    if (query.search) {
      queryBuilder.andWhere(
        '(lesson.title ILIKE :search OR lesson.skill ILIKE :search)',
        { search: `%${query.search}%` },
      );
    }

    const lessons = await queryBuilder.getMany();

    // Cache for 1 hour
    await this.redisService.set(cacheKey, lessons, this.CACHE_TTL);
    this.logger.log(`Cached lessons query: ${cacheKey}`);

    return lessons;
  }

  async findOne(id: number): Promise<Lesson> {
    const cacheKey = `lesson:${id}`;

    // Try cache first
    const cached = await this.redisService.get<Lesson>(cacheKey);
    if (cached) {
      this.logger.log(`Cache hit for lesson: ${id}`);
      return cached;
    }

    const lesson = await this.lessonRepository.findOne({
      where: { id },
    });

    if (!lesson) {
      throw new NotFoundException(`Lesson with ID ${id} not found`);
    }

    // Cache for 1 hour
    await this.redisService.set(cacheKey, lesson, this.CACHE_TTL);
    this.logger.log(`Cached lesson: ${id}`);

    return lesson;
  }

  async findOneWithExercises(id: number): Promise<Lesson> {
    const cacheKey = `lesson:${id}:exercises`;

    // Try cache first
    const cached = await this.redisService.get<Lesson>(cacheKey);
    if (cached) {
      this.logger.log(`Cache hit for lesson with exercises: ${id}`);
      return cached;
    }

    const lesson = await this.lessonRepository.findOne({
      where: { id },
      relations: ['exercises'],
    });

    if (!lesson) {
      throw new NotFoundException(`Lesson with ID ${id} not found`);
    }

    // Sort exercises by orderIndex
    if (lesson.exercises) {
      lesson.exercises.sort(
        (a, b) => (a.orderIndex || 0) - (b.orderIndex || 0),
      );
    }

    // Cache for 1 hour
    await this.redisService.set(cacheKey, lesson, this.CACHE_TTL);
    this.logger.log(`Cached lesson with exercises: ${id}`);

    return lesson;
  }

  async getExercises(lessonId: number): Promise<Exercise[]> {
    const cacheKey = `lesson:${lessonId}:exercises-only`;

    // Try cache first
    const cached = await this.redisService.get<Exercise[]>(cacheKey);
    if (cached) {
      this.logger.log(`Cache hit for exercises: ${lessonId}`);
      return cached;
    }

    // Verify lesson exists
    const lesson = await this.lessonRepository.findOne({
      where: { id: lessonId },
    });

    if (!lesson) {
      throw new NotFoundException(`Lesson with ID ${lessonId} not found`);
    }

    const exercises = await this.exerciseRepository.find({
      where: { lessonId },
      order: { orderIndex: 'ASC' },
    });

    // Cache for 1 hour
    await this.redisService.set(cacheKey, exercises, this.CACHE_TTL);
    this.logger.log(`Cached exercises for lesson: ${lessonId}`);

    return exercises;
  }

  async invalidateCache(lessonId?: number): Promise<void> {
    if (lessonId) {
      await this.redisService.del(`lesson:${lessonId}`);
      await this.redisService.del(`lesson:${lessonId}:exercises`);
      await this.redisService.del(`lesson:${lessonId}:exercises-only`);
      this.logger.log(`Invalidated cache for lesson: ${lessonId}`);
    }

    // Invalidate all lessons queries
    await this.redisService.invalidate('lessons:*');
    this.logger.log('Invalidated all lessons cache');
  }
}
