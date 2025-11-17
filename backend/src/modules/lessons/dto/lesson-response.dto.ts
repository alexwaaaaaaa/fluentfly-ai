import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ExerciseResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  lessonId: number;

  @ApiProperty()
  type: string;

  @ApiProperty()
  question: string;

  @ApiPropertyOptional()
  options?: any[];

  @ApiPropertyOptional()
  answer?: Record<string, any>;

  @ApiPropertyOptional()
  audioUrl?: string;

  @ApiPropertyOptional()
  orderIndex?: number;
}

export class LessonResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  skill: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  level: string;

  @ApiPropertyOptional()
  audioUrl?: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  meta?: Record<string, any>;

  @ApiPropertyOptional()
  orderIndex?: number;

  @ApiPropertyOptional({ type: [ExerciseResponseDto] })
  exercises?: ExerciseResponseDto[];
}
