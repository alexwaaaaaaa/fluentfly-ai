import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { VideoCallSession } from './entities/video-call-session.entity';
import { RedisService } from '../../common/redis/redis.service';

export interface ConnectionEvent {
  type: 'connect' | 'disconnect' | 'reconnect' | 'error';
  userId: number;
  roomName: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export interface ErrorMetrics {
  totalErrors: number;
  errorRate: number; // errors per hour
  errorsByType: Record<string, number>;
  recentErrors: Array<{
    type: string;
    message: string;
    timestamp: Date;
    userId?: number;
    roomName?: string;
  }>;
}

export interface PerformanceMetrics {
  averageAiResponseTime: number; // milliseconds
  p95ResponseTime: number; // milliseconds
  p99ResponseTime: number; // milliseconds
  slowestResponses: Array<{
    responseTime: number;
    timestamp: Date;
    roomName: string;
  }>;
}

export interface SystemHealth {
  status: 'healthy' | 'degraded' | 'unhealthy';
  activeCalls: number;
  errorRate: number;
  averageResponseTime: number;
  uptime: number; // seconds
  lastChecked: Date;
}

@Injectable()
export class MonitoringService {
  private readonly logger = new Logger(MonitoringService.name);
  private readonly startTime = Date.now();
  private readonly ERROR_RATE_THRESHOLD = 10; // errors per hour
  private readonly RESPONSE_TIME_THRESHOLD = 5000; // 5 seconds

  constructor(
    @InjectRepository(VideoCallSession)
    private sessionRepository: Repository<VideoCallSession>,
    private redisService: RedisService,
  ) {}

  /**
   * Log a connection event
   * @param event - Connection event details
   */
  async logConnectionEvent(event: ConnectionEvent): Promise<void> {
    const key = `rtc:events:${event.type}:${Date.now()}`;
    await this.redisService.set(
      key,
      JSON.stringify(event),
      3600 * 24 * 7, // Keep for 7 days
    );

    this.logger.log(
      `Connection event: ${event.type} - User: ${event.userId}, Room: ${event.roomName}`,
    );

    // Track event count
    const countKey = `rtc:events:count:${event.type}`;
    const count = (await this.redisService.get<number>(countKey)) || 0;
    await this.redisService.set(countKey, count + 1, 3600 * 24); // Reset daily
  }

  /**
   * Log an error event
   * @param type - Error type
   * @param message - Error message
   * @param metadata - Additional error metadata
   */
  async logError(
    type: string,
    message: string,
    metadata?: Record<string, any>,
  ): Promise<void> {
    const error = {
      type,
      message,
      timestamp: new Date(),
      ...metadata,
    };

    const key = `rtc:errors:${Date.now()}`;
    await this.redisService.set(
      key,
      JSON.stringify(error),
      3600 * 24 * 7, // Keep for 7 days
    );

    this.logger.error(
      `RTC Error [${type}]: ${message}`,
      metadata ? JSON.stringify(metadata) : '',
    );

    // Increment error counter
    const countKey = `rtc:errors:count`;
    const count = (await this.redisService.get<number>(countKey)) || 0;
    await this.redisService.set(countKey, count + 1, 3600); // Reset hourly

    // Check if error rate is too high
    await this.checkErrorRate(count + 1);
  }

  /**
   * Check if error rate exceeds threshold and log alert
   * @param currentCount - Current error count
   */
  private async checkErrorRate(currentCount: number): Promise<void> {
    if (currentCount >= this.ERROR_RATE_THRESHOLD) {
      this.logger.warn(
        `⚠️ HIGH ERROR RATE ALERT: ${currentCount} errors in the last hour (threshold: ${this.ERROR_RATE_THRESHOLD})`,
      );

      // Store alert
      const alertKey = `rtc:alerts:high-error-rate:${Date.now()}`;
      await this.redisService.set(
        alertKey,
        JSON.stringify({
          type: 'high_error_rate',
          count: currentCount,
          threshold: this.ERROR_RATE_THRESHOLD,
          timestamp: new Date(),
        }),
        3600 * 24, // Keep for 24 hours
      );
    }
  }

  /**
   * Log AI response time
   * @param roomName - Room name
   * @param responseTime - Response time in milliseconds
   */
  async logAiResponseTime(roomName: string, responseTime: number): Promise<void> {
    const key = `rtc:response-times:${Date.now()}`;
    await this.redisService.set(
      key,
      JSON.stringify({
        roomName,
        responseTime,
        timestamp: new Date(),
      }),
      3600 * 24, // Keep for 24 hours
    );

    // Log slow responses
    if (responseTime > this.RESPONSE_TIME_THRESHOLD) {
      this.logger.warn(
        `⚠️ SLOW AI RESPONSE: ${responseTime}ms in room ${roomName} (threshold: ${this.RESPONSE_TIME_THRESHOLD}ms)`,
      );
    }

    // Track average response time
    const avgKey = 'rtc:response-times:average';
    const currentAvg = (await this.redisService.get<number>(avgKey)) || 0;
    const countKey = 'rtc:response-times:count';
    const count = (await this.redisService.get<number>(countKey)) || 0;

    const newAvg = (currentAvg * count + responseTime) / (count + 1);
    await this.redisService.set(avgKey, newAvg, 3600); // Reset hourly
    await this.redisService.set(countKey, count + 1, 3600);
  }

  /**
   * Get error metrics
   * @returns Error metrics including total errors, error rate, and recent errors
   */
  async getErrorMetrics(): Promise<ErrorMetrics> {
    // Get error count from last hour
    const countKey = 'rtc:errors:count';
    const totalErrors = (await this.redisService.get<number>(countKey)) || 0;

    // Get all error keys from Redis
    const errorKeys = await this.getAllKeysWithPrefix('rtc:errors:');
    const errors = await Promise.all(
      errorKeys.map(async (key) => {
        const data = await this.redisService.get<string>(key);
        return data ? JSON.parse(data) : null;
      }),
    );

    const validErrors = errors.filter((e) => e !== null);

    // Group errors by type
    const errorsByType: Record<string, number> = {};
    validErrors.forEach((error) => {
      errorsByType[error.type] = (errorsByType[error.type] || 0) + 1;
    });

    // Get recent errors (last 10)
    const recentErrors = validErrors
      .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
      .slice(0, 10)
      .map((e) => ({
        type: e.type,
        message: e.message,
        timestamp: new Date(e.timestamp),
        userId: e.userId,
        roomName: e.roomName,
      }));

    return {
      totalErrors,
      errorRate: totalErrors, // errors per hour
      errorsByType,
      recentErrors,
    };
  }

  /**
   * Get performance metrics
   * @returns Performance metrics including response times
   */
  async getPerformanceMetrics(): Promise<PerformanceMetrics> {
    // Get all response time keys
    const responseKeys = await this.getAllKeysWithPrefix('rtc:response-times:');
    const responses = await Promise.all(
      responseKeys.map(async (key) => {
        const data = await this.redisService.get<string>(key);
        return data ? JSON.parse(data) : null;
      }),
    );

    const validResponses = responses.filter((r) => r !== null && r.responseTime);

    if (validResponses.length === 0) {
      return {
        averageAiResponseTime: 0,
        p95ResponseTime: 0,
        p99ResponseTime: 0,
        slowestResponses: [],
      };
    }

    // Calculate average
    const responseTimes = validResponses.map((r) => r.responseTime);
    const averageAiResponseTime =
      responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length;

    // Calculate percentiles
    const sortedTimes = [...responseTimes].sort((a, b) => a - b);
    const p95Index = Math.floor(sortedTimes.length * 0.95);
    const p99Index = Math.floor(sortedTimes.length * 0.99);
    const p95ResponseTime = sortedTimes[p95Index] || 0;
    const p99ResponseTime = sortedTimes[p99Index] || 0;

    // Get slowest responses
    const slowestResponses = validResponses
      .sort((a, b) => b.responseTime - a.responseTime)
      .slice(0, 5)
      .map((r) => ({
        responseTime: r.responseTime,
        timestamp: new Date(r.timestamp),
        roomName: r.roomName,
      }));

    return {
      averageAiResponseTime: Math.round(averageAiResponseTime),
      p95ResponseTime: Math.round(p95ResponseTime),
      p99ResponseTime: Math.round(p99ResponseTime),
      slowestResponses,
    };
  }

  /**
   * Get system health status
   * @returns System health information
   */
  async getSystemHealth(): Promise<SystemHealth> {
    // Get active calls (sessions without end time in last hour)
    const oneHourAgo = new Date(Date.now() - 3600000);
    const activeSessions = await this.sessionRepository
      .createQueryBuilder('session')
      .where('session.startTime > :oneHourAgo', { oneHourAgo })
      .andWhere('session.endTime IS NULL')
      .getCount();

    // Get error rate
    const errorMetrics = await this.getErrorMetrics();
    const errorRate = errorMetrics.errorRate;

    // Get average response time
    const performanceMetrics = await this.getPerformanceMetrics();
    const averageResponseTime = performanceMetrics.averageAiResponseTime;

    // Calculate uptime
    const uptime = Math.floor((Date.now() - this.startTime) / 1000);

    // Determine health status
    let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
    if (
      errorRate > this.ERROR_RATE_THRESHOLD ||
      averageResponseTime > this.RESPONSE_TIME_THRESHOLD
    ) {
      status = 'degraded';
    }
    if (
      errorRate > this.ERROR_RATE_THRESHOLD * 2 ||
      averageResponseTime > this.RESPONSE_TIME_THRESHOLD * 2
    ) {
      status = 'unhealthy';
    }

    return {
      status,
      activeCalls: activeSessions,
      errorRate,
      averageResponseTime,
      uptime,
      lastChecked: new Date(),
    };
  }

  /**
   * Get all Redis keys with a specific prefix
   * @param prefix - Key prefix
   * @returns Array of matching keys
   */
  private async getAllKeysWithPrefix(prefix: string): Promise<string[]> {
    // Note: This is a simplified implementation
    // In production, you might want to use Redis SCAN for better performance
    try {
      // Try to get keys from a set we maintain
      const keysSetName = `${prefix}:keys`;
      const keys = await this.redisService.get<string[]>(keysSetName);
      return keys || [];
    } catch (error) {
      this.logger.warn(`Failed to get keys with prefix ${prefix}: ${error.message}`);
      return [];
    }
  }

  /**
   * Track a key for later retrieval
   * @param key - Redis key to track
   */
  async trackKey(key: string): Promise<void> {
    const prefix = key.split(':').slice(0, 2).join(':');
    const keysSetName = `${prefix}:keys`;
    const existingKeys = (await this.redisService.get<string[]>(keysSetName)) || [];
    
    if (!existingKeys.includes(key)) {
      existingKeys.push(key);
      await this.redisService.set(keysSetName, existingKeys, 3600 * 24 * 7);
    }
  }

  /**
   * Get connection event statistics
   * @returns Connection event counts by type
   */
  async getConnectionStats(): Promise<Record<string, number>> {
    const types = ['connect', 'disconnect', 'reconnect', 'error'];
    const stats: Record<string, number> = {};

    for (const type of types) {
      const countKey = `rtc:events:count:${type}`;
      stats[type] = (await this.redisService.get<number>(countKey)) || 0;
    }

    return stats;
  }

  /**
   * Clear old metrics data
   * This should be called periodically to prevent memory buildup
   */
  async clearOldMetrics(): Promise<void> {
    this.logger.log('Clearing old metrics data...');
    
    // Reset hourly counters
    await this.redisService.set('rtc:errors:count', 0, 3600);
    await this.redisService.set('rtc:response-times:count', 0, 3600);
    await this.redisService.set('rtc:response-times:average', 0, 3600);

    this.logger.log('Old metrics data cleared');
  }
}
