import { ApiProperty } from '@nestjs/swagger';

export class TokenResponseDto {
  @ApiProperty({
    description: 'LiveKit JWT access token',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  token: string;

  @ApiProperty({
    description: 'LiveKit server WebSocket URL',
    example: 'ws://localhost:7880',
  })
  url: string;

  @ApiProperty({
    description: 'Unique room name for the video call session',
    example: 'lesson-1-123-1699564800000',
  })
  roomName: string;

  @ApiProperty({
    description: 'Token expiration timestamp',
    example: '2024-11-14T12:00:00.000Z',
  })
  expiresAt: Date;

  @ApiProperty({
    description: 'Video call session ID',
    example: 1,
  })
  sessionId: number;
}
