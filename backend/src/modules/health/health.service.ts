import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { RedisService } from '../../common/redis/redis.service';
import { HealthStatus } from './health.controller';

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly redisService: RedisService,
  ) {}

  async checkHealth(): Promise<HealthStatus> {
    const checks = await Promise.allSettled([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkAzureSpeech(),
      this.checkGemini(),
      this.checkOpenAI(),
    ]);

    const services = {
      database: checks[0].status === 'fulfilled' && checks[0].value,
      redis: checks[1].status === 'fulfilled' && checks[1].value,
      azureSpeech: checks[2].status === 'fulfilled' && checks[2].value,
      gemini: checks[3].status === 'fulfilled' && checks[3].value,
      openai: checks[4].status === 'fulfilled' && checks[4].value,
    };

    // Determine overall status
    const criticalServices = [services.database, services.redis];
    const allCriticalHealthy = criticalServices.every((s) => s);
    const anyServiceUnhealthy = Object.values(services).some((s) => !s);

    let status: 'healthy' | 'degraded' | 'unhealthy';
    if (!allCriticalHealthy) {
      status = 'unhealthy';
    } else if (anyServiceUnhealthy) {
      status = 'degraded';
    } else {
      status = 'healthy';
    }

    const healthStatus: HealthStatus = {
      status,
      timestamp: new Date().toISOString(),
      services,
    };

    // Log unhealthy services
    if (status !== 'healthy') {
      this.logger.warn(`Health check status: ${status}`, services);
    }

    return healthStatus;
  }

  private async checkDatabase(): Promise<boolean> {
    try {
      await this.userRepository.query('SELECT 1');
      return true;
    } catch (error) {
      this.logger.error('Database health check failed', error.message);
      return false;
    }
  }

  private async checkRedis(): Promise<boolean> {
    try {
      await this.redisService.set('health:check', 'ok', 10);
      const value = await this.redisService.get('health:check');
      return value === 'ok';
    } catch (error) {
      this.logger.error('Redis health check failed', error.message);
      return false;
    }
  }

  private async checkAzureSpeech(): Promise<boolean> {
    try {
      // Check if Azure Speech is configured
      const isConfigured = !!process.env.AZURE_SPEECH_KEY;
      if (!isConfigured) {
        this.logger.warn('Azure Speech not configured');
      }
      return isConfigured;
    } catch (error) {
      this.logger.error('Azure Speech health check failed', error.message);
      return false;
    }
  }

  private async checkGemini(): Promise<boolean> {
    try {
      // Check if Gemini is configured
      const isConfigured = !!process.env.GEMINI_API_KEY;
      if (!isConfigured) {
        this.logger.warn('Gemini API not configured');
      }
      return isConfigured;
    } catch (error) {
      this.logger.error('Gemini health check failed', error.message);
      return false;
    }
  }

  private async checkOpenAI(): Promise<boolean> {
    try {
      // Check if OpenAI is configured
      const isConfigured = !!process.env.OPENAI_API_KEY;
      if (!isConfigured) {
        this.logger.warn('OpenAI API not configured');
      }
      return isConfigured;
    } catch (error) {
      this.logger.error('OpenAI health check failed', error.message);
      return false;
    }
  }
}
