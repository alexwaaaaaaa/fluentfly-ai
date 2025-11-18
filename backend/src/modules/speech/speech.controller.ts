import {
  Controller,
  Post,
  Body,
  UseInterceptors,
  UploadedFile,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
} from '@nestjs/swagger';
import { SpeechService } from './speech.service';
import { TtsRequestDto } from './dto/tts-request.dto';
import { SttResponseDto } from './dto/stt-response.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('speech')
@Controller('speech')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SpeechController {
  constructor(private readonly speechService: SpeechService) {}

  @Post('tts')
  @ApiOperation({ summary: 'Convert text to speech' })
  @ApiResponse({
    status: 200,
    description: 'Returns audio URL',
    schema: {
      type: 'object',
      properties: {
        audioUrl: {
          type: 'string',
          example: 'https://cdn.example.com/audio/abc123.mp3',
        },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async textToSpeech(
    @Body() dto: TtsRequestDto,
  ): Promise<{ audioUrl: string }> {
    const audioUrl = await this.speechService.textToSpeech(dto.text);
    return { audioUrl };
  }

  @Post('stt')
  @ApiOperation({ summary: 'Convert speech to text' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({
    status: 200,
    description: 'Returns transcribed text with confidence scores',
    type: SttResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid audio file' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseInterceptors(FileInterceptor('audio'))
  async speechToText(
    @UploadedFile() file: Express.Multer.File,
  ): Promise<SttResponseDto> {
    if (!file) {
      throw new BadRequestException('Audio file is required');
    }

    return this.speechService.speechToText(file.buffer);
  }
}
