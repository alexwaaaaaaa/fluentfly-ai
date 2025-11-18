import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  NotFoundException,
  Logger,
  ParseIntPipe,
  ForbiddenException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { RtcService } from './rtc.service';
import { AiAgentService } from './ai-agent.service';
import { AnalyticsService } from './analytics.service';
import { MonitoringService } from './monitoring.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { TokenResponseDto } from './dto/token-response.dto';
import { LessonsService } from '../lessons/lessons.service';
import { RedisService } from '../../common/redis/redis.service';
import { ConfigService } from '@nestjs/config';

@ApiTags('rtc')
@Controller('rtc')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class RtcController {
  private readonly logger = new Logger(RtcController.name);
  private readonly MAX_TOKENS_PER_DAY = 100;
  private readonly RATE_LIMIT_TTL = 86400; // 24 hours in seconds

  constructor(
    private readonly rtcService: RtcService,
    private readonly aiAgentService: AiAgentService,
    private readonly analyticsService: AnalyticsService,
    private readonly monitoringService: MonitoringService,
    private readonly lessonsService: LessonsService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {}

  @Get('token')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute
  @ApiOperation({
    summary: 'Generate LiveKit access token for video call session',
    description:
      'Creates a secure token for joining a video call room. Requires authentication and validates lesson access.',
  })
  @ApiQuery({
    name: 'lessonId',
    required: true,
    description:
      'ID of the lesson for the video call session (use 0 for free conversation mode)',
    example: 1,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Successfully generated LiveKit token',
    type: TokenResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid lesson ID' })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  @ApiResponse({ status: 403, description: 'Forbidden - rate limit exceeded' })
  @ApiResponse({ status: 404, description: 'Lesson not found' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async getToken(
    @CurrentUser() user: any,
    @Query('lessonId') lessonIdParam: string,
  ): Promise<TokenResponseDto> {
    const userId = user.id;

    // Parse and validate lessonId (allow 0 for free conversation)
    const lessonId = parseInt(lessonIdParam, 10);
    if (isNaN(lessonId) || lessonId < 0) {
      throw new NotFoundException(
        'Invalid lesson ID - must be a non-negative number',
      );
    }

    // Log token generation request for security audit
    this.logger.log(
      `Token generation requested - User: ${userId}, Lesson: ${lessonId}, IP: ${user.ip || 'unknown'}`,
    );

    // Validate lesson exists (skip validation for lessonId 0 which is free conversation)
    if (lessonId !== 0) {
      try {
        await this.lessonsService.findOne(lessonId);
      } catch (error) {
        this.logger.warn(
          `Token generation failed - Lesson ${lessonId} not found for user ${userId}`,
        );
        throw new NotFoundException(`Lesson with ID ${lessonId} not found`);
      }
    }

    // Check rate limit (max 10 tokens per user per day)
    await this.checkRateLimit(userId);

    // Generate unique room name
    const roomName = this.rtcService.generateRoomName(lessonId, userId);

    // Create LiveKit token and start session
    const result = await this.rtcService.createToken(
      userId,
      roomName,
      lessonId,
    );

    // Increment rate limit counter
    await this.incrementRateLimit(userId);

    // Get LiveKit URL from config
    const livekitUrl =
      this.configService.get<string>('LIVEKIT_URL') || 'ws://localhost:7880';

    // Log successful token generation
    this.logger.log(
      `Token generated successfully - User: ${userId}, Lesson: ${lessonId}, Room: ${roomName}, Session: ${result.sessionId}`,
    );

    // Log connection event to monitoring
    await this.monitoringService.logConnectionEvent({
      type: 'connect',
      userId,
      roomName,
      timestamp: new Date(),
      metadata: { lessonId, sessionId: result.sessionId },
    });

    return {
      token: result.token,
      url: livekitUrl,
      roomName: result.roomName,
      expiresAt: result.expiresAt,
      sessionId: result.sessionId,
    };
  }

  /**
   * Check if user has exceeded daily token generation limit
   * @param userId - The user's ID
   * @throws ForbiddenException if rate limit exceeded
   */
  private async checkRateLimit(userId: number): Promise<void> {
    // TODO: Re-enable rate limiting in production
    // Temporarily disabled for testing
    return;

    /* const rateLimitKey = `rtc:token:ratelimit:${userId}`;
    const count = await this.redisService.get<number>(rateLimitKey);

    if (count && count >= this.MAX_TOKENS_PER_DAY) {
      this.logger.warn(
        `Rate limit exceeded for user ${userId} - ${count}/${this.MAX_TOKENS_PER_DAY} tokens used today`
      );
      throw new ForbiddenException(
        `Daily token generation limit exceeded. Maximum ${this.MAX_TOKENS_PER_DAY} tokens per day.`
      );
    } */
  }

  /**
   * Increment the rate limit counter for a user
   * @param userId - The user's ID
   */
  private async incrementRateLimit(userId: number): Promise<void> {
    const rateLimitKey = `rtc:token:ratelimit:${userId}`;
    const count = await this.redisService.get<number>(rateLimitKey);

    if (count) {
      await this.redisService.set(rateLimitKey, count + 1, this.RATE_LIMIT_TTL);
    } else {
      await this.redisService.set(rateLimitKey, 1, this.RATE_LIMIT_TTL);
    }
  }

  @Post('agent')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests per minute
  @ApiOperation({
    summary: 'Spawn AI agent in video call room',
    description:
      'Creates an AI agent participant that joins the video call room and interacts with the user.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['roomName', 'lessonId'],
      properties: {
        roomName: {
          type: 'string',
          description: 'Name of the LiveKit room',
          example: 'lesson-1-123-1699564800000',
        },
        lessonId: {
          type: 'number',
          description: 'ID of the lesson',
          example: 1,
        },
        topic: {
          type: 'string',
          description: 'Optional topic for the conversation',
          example: 'Ordering food at a restaurant',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'AI agent successfully spawned',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'AI agent spawned successfully' },
        roomName: { type: 'string', example: 'lesson-1-123-1699564800000' },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  @ApiResponse({ status: 404, description: 'Lesson not found' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async spawnAgent(
    @CurrentUser() user: any,
    @Body() body: { roomName: string; lessonId: number; topic?: string },
  ): Promise<{ success: boolean; message: string; roomName: string }> {
    const userId = user.id;
    const { roomName, lessonId, topic } = body;

    this.logger.log(
      `AI agent spawn requested - User: ${userId}, Room: ${roomName}, Lesson: ${lessonId}`,
    );

    // Validate lesson exists (skip validation for lessonId 0 - free conversation)
    if (lessonId !== 0) {
      try {
        await this.lessonsService.findOne(lessonId);
      } catch (error) {
        this.logger.warn(
          `AI agent spawn failed - Lesson ${lessonId} not found for user ${userId}`,
        );
        throw new NotFoundException(`Lesson with ID ${lessonId} not found`);
      }
    } else {
      this.logger.log(`Free conversation mode - Lesson ID 0, User: ${userId}`);
    }

    // Spawn the AI agent
    await this.aiAgentService.spawnAgent(roomName, {
      lessonId,
      userId,
      topic,
      sessionId: roomName,
    });

    this.logger.log(
      `AI agent spawned successfully - Room: ${roomName}, User: ${userId}`,
    );

    return {
      success: true,
      message: 'AI agent spawned successfully',
      roomName,
    };
  }

  @Post('agent/disconnect')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({
    summary: 'Disconnect AI agent from room',
    description: 'Disconnects the AI agent from the specified video call room.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['roomName'],
      properties: {
        roomName: {
          type: 'string',
          description: 'Name of the LiveKit room',
          example: 'lesson-1-123-1699564800000',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'AI agent successfully disconnected',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: {
          type: 'string',
          example: 'AI agent disconnected successfully',
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async disconnectAgent(
    @CurrentUser() user: any,
    @Body() body: { roomName: string },
  ): Promise<{ success: boolean; message: string }> {
    const { roomName } = body;

    this.logger.log(
      `AI agent disconnect requested - User: ${user.id}, Room: ${roomName}`,
    );

    await this.aiAgentService.disconnectAgent(roomName);

    this.logger.log(`AI agent disconnected - Room: ${roomName}`);

    return {
      success: true,
      message: 'AI agent disconnected successfully',
    };
  }

  @Get('conversation-history')
  @ApiOperation({
    summary: 'Get conversation history for a room',
    description:
      'Retrieves the conversation history between user and AI agent.',
  })
  @ApiQuery({
    name: 'roomName',
    required: true,
    description: 'Name of the LiveKit room',
    example: 'lesson-1-123-1699564800000',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Conversation history retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        roomName: { type: 'string', example: 'lesson-1-123-1699564800000' },
        turns: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              speaker: {
                type: 'string',
                enum: ['user', 'ai'],
                example: 'user',
              },
              text: { type: 'string', example: 'Hello, how are you?' },
              timestamp: { type: 'string', format: 'date-time' },
              audioUrl: {
                type: 'string',
                example: 'https://cdn.example.com/audio.mp3',
              },
            },
          },
        },
        turnCount: { type: 'number', example: 5 },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getConversationHistory(
    @CurrentUser() user: any,
    @Query('roomName') roomName: string,
  ): Promise<{
    roomName: string;
    turns: any[];
    turnCount: number;
  }> {
    this.logger.log(
      `Conversation history requested - User: ${user.id}, Room: ${roomName}`,
    );

    const turns = this.aiAgentService.getConversationHistory(roomName);
    const turnCount = this.aiAgentService.getConversationTurnCount(roomName);

    return {
      roomName,
      turns,
      turnCount,
    };
  }

  @Post('session/end')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({
    summary: 'End video call session',
    description:
      'Ends a video call session, saves conversation history, and calculates analytics.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['sessionId', 'roomName'],
      properties: {
        sessionId: {
          type: 'number',
          description: 'ID of the session',
          example: 1,
        },
        roomName: {
          type: 'string',
          description: 'Name of the LiveKit room',
          example: 'lesson-1-123-1699564800000',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Session ended successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        sessionId: { type: 'number', example: 1 },
        duration: { type: 'number', example: 300 },
        analytics: {
          type: 'object',
          properties: {
            totalSpeakingTime: { type: 'number', example: 180 },
            wordsPerMinute: { type: 'number', example: 120 },
            pauseCount: { type: 'number', example: 5 },
            averagePauseLength: { type: 'number', example: 2.5 },
            fluencyScore: { type: 'number', example: 75 },
            turnCount: { type: 'number', example: 10 },
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  @ApiResponse({ status: 404, description: 'Session not found' })
  async endSession(
    @CurrentUser() user: any,
    @Body() body: { sessionId: number; roomName: string },
  ): Promise<{
    success: boolean;
    sessionId: number;
    duration: number;
    analytics: any;
  }> {
    const { sessionId, roomName } = body;

    this.logger.log(
      `Session end requested - User: ${user.id}, Session: ${sessionId}, Room: ${roomName}`,
    );

    // Get conversation history from AI agent service
    const turns = this.aiAgentService.getConversationHistory(roomName);

    // End session and calculate analytics
    const session = await this.rtcService.endSession(sessionId, turns);

    // Disconnect AI agent
    await this.aiAgentService.disconnectAgent(roomName);

    this.logger.log(
      `Session ended successfully - Session: ${sessionId}, Duration: ${session.duration}s`,
    );

    // Log disconnect event to monitoring
    await this.monitoringService.logConnectionEvent({
      type: 'disconnect',
      userId: user.id,
      roomName,
      timestamp: new Date(),
      metadata: { sessionId, duration: session.duration },
    });

    return {
      success: true,
      sessionId: session.id,
      duration: session.duration,
      analytics: session.analytics,
    };
  }

  @Get('session/:id')
  @ApiOperation({
    summary: 'Get session details',
    description:
      'Retrieves details of a video call session including conversation history and analytics.',
  })
  @ApiResponse({
    status: 200,
    description: 'Session details retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  @ApiResponse({ status: 404, description: 'Session not found' })
  async getSession(
    @CurrentUser() user: any,
    @Query('id', new ParseIntPipe()) sessionId: number,
  ) {
    this.logger.log(
      `Session details requested - User: ${user.id}, Session: ${sessionId}`,
    );

    const session = await this.rtcService.getSession(sessionId);

    // Verify user owns this session
    if (session.userId !== user.id) {
      throw new ForbiddenException('You do not have access to this session');
    }

    return session;
  }

  @Get('sessions')
  @ApiOperation({
    summary: 'Get user sessions',
    description:
      'Retrieves all video call sessions for the authenticated user.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Maximum number of sessions to return',
    example: 10,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Sessions retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getUserSessions(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
  ) {
    this.logger.log(`User sessions requested - User: ${user.id}`);

    const sessions = await this.rtcService.getUserSessions(
      user.id,
      limit || 10,
    );

    return {
      sessions,
      count: sessions.length,
    };
  }

  @Get('analytics/user')
  @ApiOperation({
    summary: 'Get user analytics',
    description:
      'Retrieves comprehensive analytics for the authenticated user including call stats and fluency metrics.',
  })
  @ApiResponse({
    status: 200,
    description: 'User analytics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        userId: { type: 'number', example: 1 },
        totalCalls: { type: 'number', example: 15 },
        averageCallDuration: { type: 'number', example: 300 },
        totalSpeakingTime: { type: 'number', example: 2700 },
        totalListeningTime: { type: 'number', example: 1800 },
        averageWordsPerMinute: { type: 'number', example: 120 },
        averageFluencyScore: { type: 'number', example: 75 },
        fluencyImprovement: { type: 'number', example: 15.5 },
        lastCallDate: { type: 'string', format: 'date-time' },
        firstCallDate: { type: 'string', format: 'date-time' },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getUserAnalytics(@CurrentUser() user: any) {
    this.logger.log(`User analytics requested - User: ${user.id}`);
    return this.analyticsService.getUserAnalytics(user.id);
  }

  @Get('analytics/fluency-trend')
  @ApiOperation({
    summary: 'Get fluency trend',
    description:
      'Retrieves fluency score trend over time for the authenticated user.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Maximum number of data points to return',
    example: 20,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Fluency trend retrieved successfully',
    schema: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          date: { type: 'string', format: 'date-time' },
          fluencyScore: { type: 'number', example: 75 },
          wordsPerMinute: { type: 'number', example: 120 },
          callDuration: { type: 'number', example: 300 },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getFluencyTrend(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
  ) {
    this.logger.log(`Fluency trend requested - User: ${user.id}`);
    return this.analyticsService.getFluencyTrend(user.id, limit || 20);
  }

  @Get('analytics/conversation-stats')
  @ApiOperation({
    summary: 'Get conversation statistics',
    description:
      'Retrieves conversation statistics for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Conversation statistics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        totalTurns: { type: 'number', example: 150 },
        averageTurnsPerCall: { type: 'number', example: 10 },
        averageWordsPerTurn: { type: 'number', example: 12.5 },
        totalWords: { type: 'number', example: 1875 },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getConversationStats(@CurrentUser() user: any) {
    this.logger.log(`Conversation stats requested - User: ${user.id}`);
    return this.analyticsService.getConversationStats(user.id);
  }

  @Get('analytics/period')
  @ApiOperation({
    summary: 'Get period analytics',
    description: 'Retrieves analytics for a specific time period.',
  })
  @ApiQuery({
    name: 'startDate',
    required: true,
    description: 'Start date of the period (ISO 8601 format)',
    example: '2024-01-01T00:00:00Z',
    type: String,
  })
  @ApiQuery({
    name: 'endDate',
    required: true,
    description: 'End date of the period (ISO 8601 format)',
    example: '2024-01-31T23:59:59Z',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Period analytics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        period: { type: 'string', example: '2024-01-01 to 2024-01-31' },
        totalCalls: { type: 'number', example: 150 },
        totalDuration: { type: 'number', example: 45000 },
        averageDuration: { type: 'number', example: 300 },
        uniqueUsers: { type: 'number', example: 25 },
        averageFluencyScore: { type: 'number', example: 72 },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getPeriodAnalytics(
    @CurrentUser() user: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    this.logger.log(
      `Period analytics requested - User: ${user.id}, Period: ${startDate} to ${endDate}`,
    );
    return this.analyticsService.getPeriodAnalytics(
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('analytics/daily')
  @ApiOperation({
    summary: 'Get daily analytics',
    description: 'Retrieves daily analytics for the last N days.',
  })
  @ApiQuery({
    name: 'days',
    required: false,
    description: 'Number of days to include',
    example: 30,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Daily analytics retrieved successfully',
    schema: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          period: { type: 'string', example: '2024-01-15' },
          totalCalls: { type: 'number', example: 5 },
          totalDuration: { type: 'number', example: 1500 },
          averageDuration: { type: 'number', example: 300 },
          uniqueUsers: { type: 'number', example: 3 },
          averageFluencyScore: { type: 'number', example: 75 },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getDailyAnalytics(
    @CurrentUser() user: any,
    @Query('days') days?: number,
  ) {
    this.logger.log(
      `Daily analytics requested - User: ${user.id}, Days: ${days || 30}`,
    );
    return this.analyticsService.getDailyAnalytics(days || 30);
  }

  @Get('analytics/top-users/calls')
  @ApiOperation({
    summary: 'Get top users by call count',
    description: 'Retrieves the top users ranked by total number of calls.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Maximum number of users to return',
    example: 10,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Top users retrieved successfully',
    schema: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          userId: { type: 'number', example: 1 },
          callCount: { type: 'number', example: 25 },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getTopUsersByCalls(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
  ) {
    this.logger.log(`Top users by calls requested - User: ${user.id}`);
    return this.analyticsService.getTopUsersByCalls(limit || 10);
  }

  @Get('analytics/top-users/fluency')
  @ApiOperation({
    summary: 'Get top users by fluency score',
    description: 'Retrieves the top users ranked by average fluency score.',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    description: 'Maximum number of users to return',
    example: 10,
    type: Number,
  })
  @ApiResponse({
    status: 200,
    description: 'Top users retrieved successfully',
    schema: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          userId: { type: 'number', example: 1 },
          averageFluencyScore: { type: 'number', example: 85 },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getTopUsersByFluency(
    @CurrentUser() user: any,
    @Query('limit') limit?: number,
  ) {
    this.logger.log(`Top users by fluency requested - User: ${user.id}`);
    return this.analyticsService.getTopUsersByFluency(limit || 10);
  }

  @Get('monitoring/health')
  @ApiOperation({
    summary: 'Get system health status',
    description:
      'Retrieves current system health including active calls, error rate, and response times.',
  })
  @ApiResponse({
    status: 200,
    description: 'System health retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: ['healthy', 'degraded', 'unhealthy'],
          example: 'healthy',
        },
        activeCalls: { type: 'number', example: 5 },
        errorRate: { type: 'number', example: 2 },
        averageResponseTime: { type: 'number', example: 1500 },
        uptime: { type: 'number', example: 86400 },
        lastChecked: { type: 'string', format: 'date-time' },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getSystemHealth(@CurrentUser() user: any) {
    this.logger.log(`System health requested - User: ${user.id}`);
    return this.monitoringService.getSystemHealth();
  }

  @Get('monitoring/errors')
  @ApiOperation({
    summary: 'Get error metrics',
    description:
      'Retrieves error metrics including total errors, error rate, and recent errors.',
  })
  @ApiResponse({
    status: 200,
    description: 'Error metrics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        totalErrors: { type: 'number', example: 5 },
        errorRate: { type: 'number', example: 5 },
        errorsByType: {
          type: 'object',
          example: { connection_failed: 3, timeout: 2 },
        },
        recentErrors: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              type: { type: 'string', example: 'connection_failed' },
              message: {
                type: 'string',
                example: 'Failed to connect to LiveKit',
              },
              timestamp: { type: 'string', format: 'date-time' },
              userId: { type: 'number', example: 1 },
              roomName: {
                type: 'string',
                example: 'lesson-1-123-1699564800000',
              },
            },
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getErrorMetrics(@CurrentUser() user: any) {
    this.logger.log(`Error metrics requested - User: ${user.id}`);
    return this.monitoringService.getErrorMetrics();
  }

  @Get('monitoring/performance')
  @ApiOperation({
    summary: 'Get performance metrics',
    description: 'Retrieves performance metrics including AI response times.',
  })
  @ApiResponse({
    status: 200,
    description: 'Performance metrics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        averageAiResponseTime: { type: 'number', example: 1500 },
        p95ResponseTime: { type: 'number', example: 2500 },
        p99ResponseTime: { type: 'number', example: 3500 },
        slowestResponses: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              responseTime: { type: 'number', example: 4500 },
              timestamp: { type: 'string', format: 'date-time' },
              roomName: {
                type: 'string',
                example: 'lesson-1-123-1699564800000',
              },
            },
          },
        },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getPerformanceMetrics(@CurrentUser() user: any) {
    this.logger.log(`Performance metrics requested - User: ${user.id}`);
    return this.monitoringService.getPerformanceMetrics();
  }

  @Get('monitoring/connections')
  @ApiOperation({
    summary: 'Get connection statistics',
    description: 'Retrieves connection event statistics.',
  })
  @ApiResponse({
    status: 200,
    description: 'Connection statistics retrieved successfully',
    schema: {
      type: 'object',
      properties: {
        connect: { type: 'number', example: 50 },
        disconnect: { type: 'number', example: 45 },
        reconnect: { type: 'number', example: 5 },
        error: { type: 'number', example: 3 },
      },
    },
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - authentication required',
  })
  async getConnectionStats(@CurrentUser() user: any) {
    this.logger.log(`Connection stats requested - User: ${user.id}`);
    return this.monitoringService.getConnectionStats();
  }
}
