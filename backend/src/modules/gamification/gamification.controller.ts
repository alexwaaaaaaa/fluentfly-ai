import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { GamificationService } from './gamification.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { User } from '../users/entities/user.entity';
import { AwardXpDto } from './dto/award-xp.dto';
import { XpResponse } from './dto/xp-response.dto';
import { StreakResponse } from './dto/streak-response.dto';
import { LeaderboardQueryDto } from './dto/leaderboard-query.dto';
import { LeaderboardEntry } from './dto/leaderboard-entry.dto';
import { Badge } from './entities/badge.entity';

@ApiTags('gamification')
@Controller('gamification')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Post('award-xp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Award XP to the current user' })
  @ApiResponse({
    status: 200,
    description: 'XP awarded successfully',
    type: XpResponse,
  })
  async awardXp(
    @Body() dto: AwardXpDto,
    @CurrentUser() user: User,
  ): Promise<XpResponse> {
    return this.gamificationService.awardXp(user.id, dto.amount, dto.reason);
  }

  @Post('check-streak')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Check and update user daily streak' })
  @ApiResponse({
    status: 200,
    description: 'Streak checked successfully',
    type: StreakResponse,
  })
  async checkStreak(@CurrentUser() user: User): Promise<StreakResponse> {
    return this.gamificationService.checkStreak(user.id);
  }

  @Public()
  @Get('leaderboard')
  @ApiOperation({ summary: 'Get leaderboard rankings' })
  @ApiResponse({
    status: 200,
    description: 'Leaderboard retrieved successfully',
    type: [LeaderboardEntry],
  })
  async getLeaderboard(
    @Query() query: LeaderboardQueryDto,
  ): Promise<LeaderboardEntry[]> {
    return this.gamificationService.getLeaderboard(query.page, query.limit);
  }

  @Get('badges')
  @ApiOperation({ summary: 'Get user earned badges' })
  @ApiResponse({
    status: 200,
    description: 'User badges retrieved successfully',
    type: [Badge],
  })
  async getUserBadges(@CurrentUser() user: User): Promise<Badge[]> {
    return this.gamificationService.getUserBadges(user.id);
  }
}
