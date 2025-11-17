import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Param,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ProgressService } from './progress.service';
import { SaveProgressDto } from './dto/save-progress.dto';
import { ProgressResponseDto, ProgressStatsDto } from './dto/progress-response.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('progress')
@Controller('progress')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Post()
  @ApiOperation({ summary: 'Save lesson progress' })
  async saveProgress(
    @CurrentUser() user: User,
    @Body() dto: SaveProgressDto,
  ): Promise<ProgressResponseDto> {
    return this.progressService.saveProgress(user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all user progress' })
  async getProgress(@CurrentUser() user: User): Promise<ProgressResponseDto[]> {
    return this.progressService.getProgress(user.id);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get aggregated progress statistics' })
  async getStats(@CurrentUser() user: User): Promise<ProgressStatsDto> {
    return this.progressService.getStats(user.id);
  }

  @Get('lesson/:lessonId')
  @ApiOperation({ summary: 'Get progress for a specific lesson' })
  async getProgressByLesson(
    @CurrentUser() user: User,
    @Param('lessonId', ParseIntPipe) lessonId: number,
  ): Promise<ProgressResponseDto | null> {
    return this.progressService.getProgressByLesson(user.id, lessonId);
  }
}
