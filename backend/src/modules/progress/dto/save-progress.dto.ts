import { IsInt, IsBoolean, IsObject, IsOptional, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SaveProgressDto {
  @ApiProperty({ description: 'Lesson ID' })
  @IsInt()
  lessonId: number;

  @ApiProperty({
    description: 'Exercise scores',
    example: { correct: 8, total: 10, percentage: 80 },
  })
  @IsObject()
  score: Record<string, any>;

  @ApiProperty({ description: 'Whether the lesson is completed' })
  @IsBoolean()
  completed: boolean;

  @ApiProperty({ description: 'Time spent in seconds', required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  timeSpent?: number;
}
