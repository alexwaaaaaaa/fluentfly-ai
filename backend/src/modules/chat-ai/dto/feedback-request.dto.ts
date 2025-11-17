import { IsString, IsNotEmpty, IsArray, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class FeedbackRequestDto {
  @ApiProperty({
    description: 'Full transcript of the conversation',
    example: 'Hello, how are you? I am fine, thank you.',
  })
  @IsString()
  @IsNotEmpty()
  transcript: string;

  @ApiProperty({
    description: 'Audio file buffer for pronunciation analysis',
    type: 'string',
    format: 'binary',
    required: false,
  })
  @IsOptional()
  audioBuffer?: Buffer;

  @ApiProperty({
    description: 'Word-level confidence scores from STT',
    type: 'array',
    items: {
      type: 'object',
      properties: {
        word: { type: 'string' },
        confidence: { type: 'number' },
      },
    },
    required: false,
  })
  @IsOptional()
  @IsArray()
  wordConfidences?: Array<{ word: string; confidence: number }>;
}

export class GrammarError {
  @ApiProperty({
    description: 'Original text with error',
    example: 'I am go to school',
  })
  text: string;

  @ApiProperty({
    description: 'Corrected text',
    example: 'I am going to school',
  })
  correction: string;

  @ApiProperty({
    description: 'Explanation of the error',
    example: 'Use "going" (present continuous) instead of "go" after "am"',
  })
  explanation: string;
}

export class DetailedAnalysis {
  @ApiProperty({
    description: 'Speaking pace in words per minute',
    example: 120,
  })
  wordsPerMinute: number;

  @ApiProperty({
    description: 'Number of pauses detected',
    example: 5,
  })
  pauseCount: number;

  @ApiProperty({
    description: 'Words with low confidence scores',
    example: ['pronunciation', 'difficult'],
  })
  lowConfidenceWords: string[];

  @ApiProperty({
    description: 'Grammar errors found',
    type: [GrammarError],
  })
  grammarErrors: GrammarError[];
}

export class FeedbackResponse {
  @ApiProperty({
    description: 'Fluency score (0-100)',
    example: 85,
  })
  fluency: number;

  @ApiProperty({
    description: 'Pronunciation score (0-100)',
    example: 78,
  })
  pronunciation: number;

  @ApiProperty({
    description: 'Grammar score (0-100)',
    example: 92,
  })
  grammar: number;

  @ApiProperty({
    description: 'Actionable tips for improvement',
    example: [
      'Try to speak more smoothly without long pauses',
      'Practice the word "pronunciation" - it had low confidence',
    ],
  })
  tips: string[];

  @ApiProperty({
    description: 'Detailed analysis of the speech',
    type: DetailedAnalysis,
    required: false,
  })
  detailedAnalysis?: DetailedAnalysis;
}
