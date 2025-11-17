import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { VideoCallSession } from './entities/video-call-session.entity';
import { ConversationTurn } from './entities/conversation-turn.entity';

export interface UserAnalytics {
  userId: number;
  totalCalls: number;
  averageCallDuration: number; // seconds
  totalSpeakingTime: number; // seconds
  totalListeningTime: number; // seconds
  averageWordsPerMinute: number;
  averageFluencyScore: number;
  fluencyImprovement: number; // percentage change
  lastCallDate: Date | null;
  firstCallDate: Date | null;
}

export interface PeriodAnalytics {
  period: string;
  totalCalls: number;
  totalDuration: number; // seconds
  averageDuration: number; // seconds
  uniqueUsers: number;
  averageFluencyScore: number;
}

export interface FluencyTrend {
  date: Date;
  fluencyScore: number;
  wordsPerMinute: number;
  callDuration: number;
}

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    @InjectRepository(VideoCallSession)
    private sessionRepository: Repository<VideoCallSession>,
    @InjectRepository(ConversationTurn)
    private turnRepository: Repository<ConversationTurn>,
  ) {}

  /**
   * Get comprehensive analytics for a specific user
   * @param userId - The user's ID
   * @returns User analytics including call stats and fluency metrics
   */
  async getUserAnalytics(userId: number): Promise<UserAnalytics> {
    const sessions = await this.sessionRepository.find({
      where: { userId },
      order: { startTime: 'ASC' },
    });

    if (sessions.length === 0) {
      return {
        userId,
        totalCalls: 0,
        averageCallDuration: 0,
        totalSpeakingTime: 0,
        totalListeningTime: 0,
        averageWordsPerMinute: 0,
        averageFluencyScore: 0,
        fluencyImprovement: 0,
        lastCallDate: null,
        firstCallDate: null,
      };
    }

    // Calculate total calls
    const totalCalls = sessions.length;

    // Calculate average call duration
    const totalDuration = sessions.reduce((sum, s) => sum + (s.duration || 0), 0);
    const averageCallDuration = totalDuration / totalCalls;

    // Calculate total speaking and listening time
    const totalSpeakingTime = sessions.reduce(
      (sum, s) => sum + (s.analytics?.totalSpeakingTime || 0),
      0,
    );
    const totalListeningTime = totalDuration - totalSpeakingTime;

    // Calculate average WPM
    const wpmValues = sessions
      .filter((s) => s.analytics?.wordsPerMinute)
      .map((s) => s.analytics.wordsPerMinute);
    const averageWordsPerMinute =
      wpmValues.length > 0
        ? wpmValues.reduce((sum, wpm) => sum + wpm, 0) / wpmValues.length
        : 0;

    // Calculate average fluency score
    const fluencyScores = sessions
      .filter((s) => s.analytics?.fluencyScore)
      .map((s) => s.analytics.fluencyScore);
    const averageFluencyScore =
      fluencyScores.length > 0
        ? fluencyScores.reduce((sum, score) => sum + score, 0) / fluencyScores.length
        : 0;

    // Calculate fluency improvement (compare first 3 calls vs last 3 calls)
    const fluencyImprovement = this.calculateFluencyImprovement(fluencyScores);

    // Get first and last call dates
    const firstCallDate = sessions[0].startTime;
    const lastCallDate = sessions[sessions.length - 1].startTime;

    this.logger.log(
      `Generated analytics for user ${userId}: ${totalCalls} calls, avg fluency ${averageFluencyScore.toFixed(1)}`,
    );

    return {
      userId,
      totalCalls,
      averageCallDuration: Math.round(averageCallDuration),
      totalSpeakingTime: Math.round(totalSpeakingTime),
      totalListeningTime: Math.round(totalListeningTime),
      averageWordsPerMinute: Math.round(averageWordsPerMinute),
      averageFluencyScore: Math.round(averageFluencyScore),
      fluencyImprovement: Math.round(fluencyImprovement * 10) / 10,
      lastCallDate,
      firstCallDate,
    };
  }

  /**
   * Calculate fluency improvement percentage
   * Compares first 3 calls vs last 3 calls
   * @param fluencyScores - Array of fluency scores in chronological order
   * @returns Percentage improvement (positive = improvement, negative = decline)
   */
  private calculateFluencyImprovement(fluencyScores: number[]): number {
    if (fluencyScores.length < 2) {
      return 0;
    }

    const sampleSize = Math.min(3, Math.floor(fluencyScores.length / 2));
    
    // Get first N scores
    const firstScores = fluencyScores.slice(0, sampleSize);
    const firstAvg =
      firstScores.reduce((sum, score) => sum + score, 0) / firstScores.length;

    // Get last N scores
    const lastScores = fluencyScores.slice(-sampleSize);
    const lastAvg =
      lastScores.reduce((sum, score) => sum + score, 0) / lastScores.length;

    // Calculate percentage change
    if (firstAvg === 0) {
      return 0;
    }

    return ((lastAvg - firstAvg) / firstAvg) * 100;
  }

  /**
   * Get fluency trend over time for a user
   * @param userId - The user's ID
   * @param limit - Maximum number of data points to return
   * @returns Array of fluency trend data points
   */
  async getFluencyTrend(userId: number, limit = 20): Promise<FluencyTrend[]> {
    const sessions = await this.sessionRepository.find({
      where: { userId },
      order: { startTime: 'ASC' },
      take: limit,
    });

    return sessions
      .filter((s) => s.analytics?.fluencyScore)
      .map((s) => ({
        date: s.startTime,
        fluencyScore: s.analytics.fluencyScore,
        wordsPerMinute: s.analytics.wordsPerMinute || 0,
        callDuration: s.duration || 0,
      }));
  }

  /**
   * Get analytics for a specific time period
   * @param startDate - Start of the period
   * @param endDate - End of the period
   * @returns Period analytics
   */
  async getPeriodAnalytics(
    startDate: Date,
    endDate: Date,
  ): Promise<PeriodAnalytics> {
    const sessions = await this.sessionRepository.find({
      where: {
        startTime: Between(startDate, endDate),
      },
    });

    if (sessions.length === 0) {
      return {
        period: `${startDate.toISOString()} to ${endDate.toISOString()}`,
        totalCalls: 0,
        totalDuration: 0,
        averageDuration: 0,
        uniqueUsers: 0,
        averageFluencyScore: 0,
      };
    }

    const totalCalls = sessions.length;
    const totalDuration = sessions.reduce((sum, s) => sum + (s.duration || 0), 0);
    const averageDuration = totalDuration / totalCalls;

    // Count unique users
    const uniqueUsers = new Set(sessions.map((s) => s.userId)).size;

    // Calculate average fluency score
    const fluencyScores = sessions
      .filter((s) => s.analytics?.fluencyScore)
      .map((s) => s.analytics.fluencyScore);
    const averageFluencyScore =
      fluencyScores.length > 0
        ? fluencyScores.reduce((sum, score) => sum + score, 0) / fluencyScores.length
        : 0;

    return {
      period: `${startDate.toISOString()} to ${endDate.toISOString()}`,
      totalCalls,
      totalDuration: Math.round(totalDuration),
      averageDuration: Math.round(averageDuration),
      uniqueUsers,
      averageFluencyScore: Math.round(averageFluencyScore),
    };
  }

  /**
   * Get daily analytics for the last N days
   * @param days - Number of days to include
   * @returns Array of daily analytics
   */
  async getDailyAnalytics(days = 30): Promise<PeriodAnalytics[]> {
    const results: PeriodAnalytics[] = [];
    const now = new Date();

    for (let i = 0; i < days; i++) {
      const endDate = new Date(now);
      endDate.setDate(endDate.getDate() - i);
      endDate.setHours(23, 59, 59, 999);

      const startDate = new Date(endDate);
      startDate.setHours(0, 0, 0, 0);

      const analytics = await this.getPeriodAnalytics(startDate, endDate);
      results.push({
        ...analytics,
        period: startDate.toISOString().split('T')[0], // Just the date
      });
    }

    return results.reverse(); // Return in chronological order
  }

  /**
   * Get top users by total calls
   * @param limit - Maximum number of users to return
   * @returns Array of user IDs and their call counts
   */
  async getTopUsersByCalls(
    limit = 10,
  ): Promise<Array<{ userId: number; callCount: number }>> {
    const result = await this.sessionRepository
      .createQueryBuilder('session')
      .select('session.userId', 'userId')
      .addSelect('COUNT(*)', 'callCount')
      .groupBy('session.userId')
      .orderBy('callCount', 'DESC')
      .limit(limit)
      .getRawMany();

    return result.map((r) => ({
      userId: r.userId,
      callCount: parseInt(r.callCount, 10),
    }));
  }

  /**
   * Get top users by fluency score
   * @param limit - Maximum number of users to return
   * @returns Array of user IDs and their average fluency scores
   */
  async getTopUsersByFluency(
    limit = 10,
  ): Promise<Array<{ userId: number; averageFluencyScore: number }>> {
    const sessions = await this.sessionRepository.find({
      where: {},
      order: { startTime: 'DESC' },
    });

    // Group by user and calculate average fluency
    const userFluency = new Map<number, number[]>();

    sessions.forEach((session) => {
      if (session.analytics?.fluencyScore) {
        if (!userFluency.has(session.userId)) {
          userFluency.set(session.userId, []);
        }
        const scores = userFluency.get(session.userId);
        if (scores) {
          scores.push(session.analytics.fluencyScore);
        }
      }
    });

    // Calculate averages and sort
    const results = Array.from(userFluency.entries())
      .map(([userId, scores]) => ({
        userId,
        averageFluencyScore:
          scores.reduce((sum, score) => sum + score, 0) / scores.length,
      }))
      .sort((a, b) => b.averageFluencyScore - a.averageFluencyScore)
      .slice(0, limit);

    return results.map((r) => ({
      userId: r.userId,
      averageFluencyScore: Math.round(r.averageFluencyScore),
    }));
  }

  /**
   * Get conversation statistics for a user
   * @param userId - The user's ID
   * @returns Conversation statistics
   */
  async getConversationStats(userId: number): Promise<{
    totalTurns: number;
    averageTurnsPerCall: number;
    averageWordsPerTurn: number;
    totalWords: number;
  }> {
    const sessions = await this.sessionRepository.find({
      where: { userId },
      relations: ['conversationTurns'],
    });

    if (sessions.length === 0) {
      return {
        totalTurns: 0,
        averageTurnsPerCall: 0,
        averageWordsPerTurn: 0,
        totalWords: 0,
      };
    }

    let totalTurns = 0;
    let totalWords = 0;

    sessions.forEach((session) => {
      const userTurns = session.conversationTurns.filter(
        (turn) => turn.speaker === 'user',
      );
      totalTurns += userTurns.length;
      totalWords += userTurns.reduce((sum, turn) => sum + (turn.wordCount || 0), 0);
    });

    const averageTurnsPerCall = totalTurns / sessions.length;
    const averageWordsPerTurn = totalTurns > 0 ? totalWords / totalTurns : 0;

    return {
      totalTurns,
      averageTurnsPerCall: Math.round(averageTurnsPerCall * 10) / 10,
      averageWordsPerTurn: Math.round(averageWordsPerTurn * 10) / 10,
      totalWords,
    };
  }
}
