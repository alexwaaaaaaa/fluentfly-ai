import { IsOptional, IsString, IsIn } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class LessonQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by skill level',
    enum: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
  })
  @IsOptional()
  @IsString()
  @IsIn(['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
  level?: string;

  @ApiPropertyOptional({
    description: 'Search by title or skill',
  })
  @IsOptional()
  @IsString()
  search?: string;
}
