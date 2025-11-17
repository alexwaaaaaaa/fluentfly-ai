import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Progress } from './entities/progress.entity';
import { SaveProgressDto } from './dto/save-progress.dto';
import { ProgressResponseDto, ProgressStatsDto } from './dto/progress-response.dto';

@Injectable()
export class ProgressService {
  constructor(
    @InjectRepository(Progress)
    private readonly progressRepository: Repository<Progress>,
  ) {}

  async saveProgress(
    userId: number,
    dto: SaveProgressDto,
  ): Promise<ProgressResponseDto> {
    // Check if progress already exists for this user and lesson
    let progress = await this.progressRepository.findOne({
      where: { userId, lessonId: dto.lessonId },
    });

    if (progress) {
      // Update existing progress
      progress.score = dto.score;
      progress.completed = dto.completed;
      progress.timeSpent = dto.timeSpent || progress.timeSpent;
      if (dto.completed && !progress.completedAt) {
        progress.completedAt = new Date();
      }
    } else {
      // Create new progress entry
      progress = this.progressRepository.create({
        userId,
        lessonId: dto.lessonId,
        score: dto.score,
        completed: dto.completed,
        timeSpent: dto.timeSpent,
        completedAt: dto.completed ? new Date() : undefined,
      });
    }

    const saved = await this.progressRepository.save(progress);
    return this.toResponseDto(saved);
  }

  async getProgress(userId: number): Promise<ProgressResponseDto[]> {
    const progress = await this.progressRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return progress.map((p) => this.toResponseDto(p));
  }

  async getProgressByLesson(
    userId: number,
    lessonId: number,
  ): Promise<ProgressResponseDto | null> {
    const progress = await this.progressRepository.findOne({
      where: { userId, lessonId },
    });

    return progress ? this.toResponseDto(progress) : null;
  }

  async getStats(userId: number): Promise<ProgressStatsDto> {
    const allProgress = await this.progressRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    const completed = allProgress.filter((p) => p.completed);
    const inProgress = allProgress.filter((p) => !p.completed);

    // Calculate total time spent
    const totalTimeSpent = allProgress.reduce(
      (sum, p) => sum + (p.timeSpent || 0),
      0,
    );

    // Calculate average score
    const scoresWithPercentage = allProgress.filter(
      (p) => p.score && typeof p.score.percentage === 'number',
    );
    const averageScore =
      scoresWithPercentage.length > 0
        ? scoresWithPercentage.reduce(
            (sum, p) => sum + p.score.percentage,
            0,
          ) / scoresWithPercentage.length
        : 0;

    // Calculate total XP (25 XP per completed lesson)
    const totalXpEarned = completed.length * 25;

    // Get recent progress (last 10 entries)
    const recentProgress = allProgress
      .slice(0, 10)
      .map((p) => this.toResponseDto(p));

    return {
      totalLessonsCompleted: completed.length,
      totalTimeSpent,
      averageScore: Math.round(averageScore * 10) / 10,
      lessonsInProgress: inProgress.length,
      totalXpEarned,
      recentProgress,
    };
  }

  private toResponseDto(progress: Progress): ProgressResponseDto {
    return {
      id: progress.id,
      userId: progress.userId,
      lessonId: progress.lessonId,
      score: progress.score,
      completed: progress.completed,
      timeSpent: progress.timeSpent,
      completedAt: progress.completedAt,
      createdAt: progress.createdAt,
    };
  }
}
