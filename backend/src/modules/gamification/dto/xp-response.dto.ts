import { ApiProperty } from '@nestjs/swagger';

export class XpResponse {
  @ApiProperty({ example: 15, description: 'Total XP awarded including bonuses' })
  xpAwarded: number;

  @ApiProperty({ example: 125, description: 'User total XP after award' })
  totalXp: number;

  @ApiProperty({ example: true, description: 'Whether user leveled up' })
  leveledUp: boolean;

  @ApiProperty({ example: 'A2', description: 'Current user level' })
  newLevel: string;

  @ApiProperty({ 
    example: [{ id: 1, name: 'Streak Starter', description: '7 day streak' }], 
    description: 'Newly earned badges' 
  })
  newBadges: Array<{ id: number; name: string; description: string }>;
}
