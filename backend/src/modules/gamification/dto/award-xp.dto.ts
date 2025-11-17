import { IsInt, IsString, IsPositive, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AwardXpDto {
  @ApiProperty({ example: 10, description: 'Amount of XP to award' })
  @IsInt()
  @IsPositive()
  amount: number;

  @ApiProperty({ example: 'lesson_completed', description: 'Reason for XP award' })
  @IsString()
  @MaxLength(100)
  reason: string;
}
