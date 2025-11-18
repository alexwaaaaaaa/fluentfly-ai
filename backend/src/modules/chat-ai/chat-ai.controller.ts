import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
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
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ChatAiService } from './chat-ai.service';
import { ChatTurnDto, ChatResponse } from './dto/chat-turn.dto';
import {
  FeedbackRequestDto,
  FeedbackResponse,
} from './dto/feedback-request.dto';
import { SpeechService } from '../speech/speech.service';

@ApiTags('chat')
@Controller('chat')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatAiController {
  constructor(
    private readonly chatAiService: ChatAiService,
    private readonly speechService: SpeechService,
  ) {}

  @Post('turn')
  @ApiOperation({
    summary: 'Process a chat turn with AI tutor',
    description:
      'Send user text to the AI tutor and receive a response with TTS audio. Uses Gemini as primary provider with OpenAI fallback.',
  })
  @ApiResponse({
    status: 200,
    description: 'Chat turn processed successfully',
    type: ChatResponse,
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid input',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async processTurn(
    @Body() dto: ChatTurnDto,
    @CurrentUser() user: any,
  ): Promise<ChatResponse> {
    return this.chatAiService.processTurn(dto.text, user.id, dto.sessionId);
  }

  @Post('feedback')
  @ApiOperation({
    summary: 'Generate feedback for speech performance',
    description:
      'Analyze pronunciation, fluency, and grammar from user speech and provide actionable feedback.',
  })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('audio'))
  @ApiResponse({
    status: 200,
    description: 'Feedback generated successfully',
    type: FeedbackResponse,
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid input or missing audio file',
  })
  async generateFeedback(
    @Body() dto: FeedbackRequestDto,
    @UploadedFile() audioFile?: Express.Multer.File,
  ): Promise<FeedbackResponse> {
    // If audio file is provided, process it with STT
    let wordConfidences: any[] = [];
    let transcript = dto.transcript;
    let duration: number | undefined;

    if (audioFile) {
      try {
        const sttResult = await this.speechService.speechToText(
          audioFile.buffer,
        );
        transcript = sttResult.text;
        wordConfidences = sttResult.words;

        // Calculate duration from word timings
        if (wordConfidences.length > 0) {
          const lastWord = wordConfidences[wordConfidences.length - 1];
          duration = (lastWord.offset + lastWord.duration) / 10000000; // Convert to seconds
        }
      } catch (error) {
        throw new BadRequestException(
          `Failed to process audio: ${error.message}`,
        );
      }
    } else if (dto.wordConfidences) {
      // Convert simple word confidences to full WordConfidence format
      wordConfidences = dto.wordConfidences.map((wc, index) => ({
        word: wc.word,
        confidence: wc.confidence,
        offset: index * 1000000, // Dummy offset
        duration: 1000000, // Dummy duration
      }));
    }

    if (!transcript) {
      throw new BadRequestException(
        'Either transcript or audio file must be provided',
      );
    }

    return this.chatAiService.generateFeedback(
      transcript,
      wordConfidences,
      duration,
    );
  }
}
