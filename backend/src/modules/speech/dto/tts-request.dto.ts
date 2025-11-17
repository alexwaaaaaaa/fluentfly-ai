import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

export class TtsRequestDto {
  @ApiProperty({
    description: 'Text to convert to speech',
    example: 'Hello, how are you?',
    maxLength: 500,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  text: string;
}
