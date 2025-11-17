import { Controller, Get } from '@nestjs/common';
import { HealthService } from './health.service';
import { Public } from '../../common/decorators/public.decorator';

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  services: {
    database: boolean;
    redis: boolean;
    azureSpeech: boolean;
    gemini: boolean;
    openai: boolean;
  };
  details?: {
    [key: string]: any;
  };
}

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Public()
  @Get()
  async check(): Promise<HealthStatus> {
    return this.healthService.checkHealth();
  }

  @Public()
  @Get('ready')
  async readiness(): Promise<{ ready: boolean }> {
    const health = await this.healthService.checkHealth();
    return {
      ready: health.status !== 'unhealthy',
    };
  }

  @Public()
  @Get('live')
  async liveness(): Promise<{ alive: boolean }> {
    return { alive: true };
  }
}
