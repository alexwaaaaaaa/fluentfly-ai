import { ApiProperty } from '@nestjs/swagger';

export class WordConfidence {
  @ApiProperty({ description: 'Recognized word' })
  word: string;

  @ApiProperty({ description: 'Confidence score (0-1)' })
  confidence: number;

  @ApiProperty({ description: 'Offset in milliseconds' })
  offset: number;

  @ApiProperty({ description: 'Duration in milliseconds' })
  duration: number;
}

export class SttResponseDto {
  @ApiProperty({ description: 'Transcribed text' })
  text: string;

  @ApiProperty({ description: 'Overall confidence score (0-1)' })
  confidence: number;

  @ApiProperty({ description: 'Word-level confidence scores', type: [WordConfidence] })
  words: WordConfidence[];
}
