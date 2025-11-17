import { ApiProperty } from '@nestjs/swagger';

export class ProgressResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty()
  lessonId: number;

  @ApiProperty()
  score: Record<string, any>;

  @ApiProperty()
  completed: boolean;

  @ApiProperty()
  timeSpent: number;

  @ApiProperty()
  completedAt: Date;

  @ApiProperty()
  createdAt: Date;
}

export class ProgressStatsDto {
  @ApiProperty({ description: 'Total lessons completed' })
  totalLessonsCompleted: number;

  @ApiProperty({ description: 'Total time spent in seconds' })
  totalTimeSpent: number;

  @ApiProperty({ description: 'Average score percentage' })
  averageScore: number;

  @ApiProperty({ description: 'Lessons in progress' })
  lessonsInProgress: number;

  @ApiProperty({ description: 'Total XP earned from lessons' })
  totalXpEarned: number;

  @ApiProperty({ description: 'Recent progress entries' })
  recentProgress: ProgressResponseDto[];
}
