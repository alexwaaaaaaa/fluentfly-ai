import { ApiProperty } from '@nestjs/swagger';

export class LeaderboardEntry {
  @ApiProperty({ example: 1, description: 'User rank position' })
  rank: number;

  @ApiProperty({ example: 123, description: 'User ID' })
  userId: number;

  @ApiProperty({ example: 'John Doe', description: 'User name' })
  name: string;

  @ApiProperty({ example: 1250, description: 'Total XP' })
  xp: number;

  @ApiProperty({ example: 'A2', description: 'User level' })
  level: string;

  @ApiProperty({ example: 15, description: 'Current streak' })
  streak: number;

  @ApiProperty({ 
    example: 'https://example.com/avatar.jpg', 
    description: 'Profile image URL',
    nullable: true 
  })
  profileImageUrl: string | null;
}
