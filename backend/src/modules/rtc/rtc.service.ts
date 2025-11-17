import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AccessToken } from 'livekit-server-sdk';
import { ConfigService } from '@nestjs/config';
import { VideoCallSession } from './entities/video-call-session.entity';
import { ConversationTurn } from './entities/conversation-turn.entity';

export interface TokenGenerationResult {
  token: string;
  roomName: string;
  expiresAt: Date;
  sessionId: number;
}

export interface SessionAnalytics {
  totalSpeakingTime: number;
  wordsPerMinute: number;
  pauseCount: number;
  averagePauseLength: number;
  fluencyScore: number;
  turnCount: number;
}

@Injectable()
export class RtcService {
  private readonly logger = new Logger(RtcService.name);
  private readonly TOKEN_TTL_SECONDS = 3600; // 1 hour

  constructor(
    private configService: ConfigService,
    @InjectRepository(VideoCallSession)
    private sessionRepository: Repository<VideoCallSession>,
    @InjectRepository(ConversationTurn)
    private turnRepository: Repository<ConversationTurn>,
  ) {}

  /**
   * Generate a unique room name for a video call session
   * @param lessonId - The lesson ID
   * @param userId - The user's ID
   * @returns Unique room name
   */
  generateRoomName(lessonId: number, userId: number): string {
    const timestamp = Date.now();
    return `lesson-${lessonId}-${userId}-${timestamp}`;
  }

  /**
   * Create a LiveKit access token for a user to join a room
   * @param userId - The user's ID
   * @param roomName - The name of the room to join
   * @param lessonId - Optional lesson ID for the session
   * @returns Token generation result with token, room name, expiration, and session ID
   */
  async createToken(
    userId: number,
    roomName: string,
    lessonId?: number,
  ): Promise<TokenGenerationResult> {
    const apiKey = this.configService.get<string>('LIVEKIT_API_KEY');
    const apiSecret = this.configService.get<string>('LIVEKIT_API_SECRET');

    if (!apiKey || !apiSecret) {
      this.logger.error('LiveKit API credentials not configured');
      throw new Error('LiveKit API credentials not configured');
    }

    const at = new AccessToken(apiKey, apiSecret, {
      identity: `user_${userId}`,
      ttl: '1h',
    });

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const token = await at.toJwt();
    const expiresAt = new Date(Date.now() + this.TOKEN_TTL_SECONDS * 1000);

    // Create session record
    const session = await this.startSession(userId, roomName, lessonId);

    this.logger.log(
      `Generated LiveKit token for user ${userId} in room ${roomName}, session ${session.id}`,
    );

    return {
      token,
      roomName,
      expiresAt,
      sessionId: session.id,
    };
  }

  /**
   * Start a new video call session
   * @param userId - The user's ID
   * @param roomName - The room name
   * @param lessonId - Optional lesson ID
   * @returns Created session
   */
  async startSession(
    userId: number,
    roomName: string,
    lessonId?: number,
  ): Promise<VideoCallSession> {
    const session = this.sessionRepository.create({
      userId,
      roomName,
      lessonId: lessonId === 0 ? null : lessonId, // Set to null for free conversation
      startTime: new Date(),
    });

    const savedSession = await this.sessionRepository.save(session);
    this.logger.log(`Started video call session ${savedSession.id} for user ${userId}`);

    return savedSession;
  }

  /**
   * End a video call session and calculate analytics
   * @param sessionId - The session ID
   * @param conversationTurns - Array of conversation turns
   * @returns Updated session with analytics
   */
  async endSession(
    sessionId: number,
    conversationTurns: Array<{
      speaker: 'user' | 'ai';
      text: string;
      timestamp: Date;
      audioUrl?: string;
    }>,
  ): Promise<VideoCallSession> {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
    });

    if (!session) {
      throw new Error(`Session ${sessionId} not found`);
    }

    const endTime = new Date();
    const duration = Math.floor(
      (endTime.getTime() - session.startTime.getTime()) / 1000,
    );

    // Save conversation turns
    await this.saveConversationTurns(sessionId, conversationTurns);

    // Calculate analytics
    const analytics = this.calculateAnalytics(conversationTurns, duration);

    // Update session
    session.endTime = endTime;
    session.duration = duration;
    session.analytics = analytics;

    const updatedSession = await this.sessionRepository.save(session);
    this.logger.log(`Ended video call session ${sessionId}, duration: ${duration}s`);

    return updatedSession;
  }

  /**
   * Save conversation turns to database
   * @param sessionId - The session ID
   * @param turns - Array of conversation turns
   */
  async saveConversationTurns(
    sessionId: number,
    turns: Array<{
      speaker: 'user' | 'ai';
      text: string;
      timestamp: Date;
      audioUrl?: string;
    }>,
  ): Promise<void> {
    const turnEntities = turns.map((turn) => {
      const wordCount = turn.text.split(/\s+/).filter((w) => w.length > 0).length;
      return this.turnRepository.create({
        sessionId,
        speaker: turn.speaker,
        text: turn.text,
        timestamp: turn.timestamp,
        audioUrl: turn.audioUrl,
        wordCount,
      });
    });

    await this.turnRepository.save(turnEntities);
    this.logger.log(`Saved ${turnEntities.length} conversation turns for session ${sessionId}`);
  }

  /**
   * Calculate analytics for a video call session
   * @param turns - Array of conversation turns
   * @param totalDuration - Total call duration in seconds
   * @returns Session analytics
   */
  calculateAnalytics(
    turns: Array<{
      speaker: 'user' | 'ai';
      text: string;
      timestamp: Date;
    }>,
    totalDuration: number,
  ): SessionAnalytics {
    const userTurns = turns.filter((t) => t.speaker === 'user');
    const turnCount = turns.length;

    // Calculate total words spoken by user
    const totalWords = userTurns.reduce((sum, turn) => {
      const words = turn.text.split(/\s+/).filter((w) => w.length > 0).length;
      return sum + words;
    }, 0);

    // Estimate speaking time (assume average speaking rate of 150 WPM)
    const estimatedSpeakingTime = totalWords > 0 ? (totalWords / 150) * 60 : 0;
    const totalSpeakingTime = Math.min(estimatedSpeakingTime, totalDuration);

    // Calculate words per minute
    const wordsPerMinute =
      totalSpeakingTime > 0 ? (totalWords / totalSpeakingTime) * 60 : 0;

    // Calculate pauses (gaps between user turns)
    let pauseCount = 0;
    let totalPauseLength = 0;

    for (let i = 1; i < userTurns.length; i++) {
      const prevTurn = userTurns[i - 1];
      const currentTurn = userTurns[i];
      const gap =
        (currentTurn.timestamp.getTime() - prevTurn.timestamp.getTime()) / 1000;

      // Consider gaps > 2 seconds as pauses
      if (gap > 2) {
        pauseCount++;
        totalPauseLength += gap;
      }
    }

    const averagePauseLength = pauseCount > 0 ? totalPauseLength / pauseCount : 0;

    // Calculate fluency score (0-100)
    // Based on: WPM (40%), pause frequency (30%), turn count (30%)
    const wpmScore = Math.min((wordsPerMinute / 150) * 100, 100);
    const pauseScore = Math.max(100 - (pauseCount / userTurns.length) * 100, 0);
    const turnScore = Math.min((turnCount / 10) * 100, 100);

    const fluencyScore = Math.round(
      wpmScore * 0.4 + pauseScore * 0.3 + turnScore * 0.3,
    );

    return {
      totalSpeakingTime: Math.round(totalSpeakingTime),
      wordsPerMinute: Math.round(wordsPerMinute),
      pauseCount,
      averagePauseLength: Math.round(averagePauseLength * 10) / 10,
      fluencyScore,
      turnCount,
    };
  }

  /**
   * Get session by ID with conversation turns
   * @param sessionId - The session ID
   * @returns Session with conversation turns
   */
  async getSession(sessionId: number): Promise<VideoCallSession> {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
      relations: ['conversationTurns', 'user', 'lesson'],
    });

    if (!session) {
      throw new Error(`Session ${sessionId} not found`);
    }

    return session;
  }

  /**
   * Get all sessions for a user
   * @param userId - The user's ID
   * @param limit - Maximum number of sessions to return
   * @returns Array of sessions
   */
  async getUserSessions(userId: number, limit = 10): Promise<VideoCallSession[]> {
    return this.sessionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
      relations: ['lesson'],
    });
  }
}
