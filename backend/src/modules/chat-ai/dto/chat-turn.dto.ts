import { IsString, IsNotEmpty, MaxLength, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ChatTurnDto {
  @ApiProperty({
    description: 'User text input',
    example: 'Hello, how are you?',
    maxLength: 500,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  text: string;

  @ApiProperty({
    description: 'Optional session ID for conversation continuity',
    example: 'session-123',
    required: false,
  })
  @IsOptional()
  @IsString()
  sessionId?: string;
}

export class ChatResponse {
  @ApiProperty({
    description: 'AI tutor reply text',
    example: 'Hello! I am doing great, thank you for asking!',
  })
  reply: string;

  @ApiProperty({
    description: 'Emotion state of the AI tutor',
    enum: ['happy', 'neutral', 'encouraging'],
    example: 'happy',
  })
  emotion: 'happy' | 'neutral' | 'encouraging';

  @ApiProperty({
    description: 'Optional hint for the learner',
    example: 'Try using "How are you?" to ask about someone\'s well-being',
    required: false,
  })
  hint?: string;

  @ApiProperty({
    description: 'URL of the TTS audio file',
    example: 'https://cdn.fluentfly.app/audio/abc123.mp3',
  })
  ttsUrl: string;
}
