import { ApiProperty } from '@nestjs/swagger';

export class StreakResponse {
  @ApiProperty({ example: 7, description: 'Current streak count' })
  streak: number;

  @ApiProperty({
    example: true,
    description: 'Whether streak was incremented today',
  })
  streakIncremented: boolean;

  @ApiProperty({ example: 35, description: 'Bonus XP earned from streak' })
  bonusXp: number;
}
