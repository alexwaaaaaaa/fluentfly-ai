import { Controller, Get } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';

@Controller('metrics')
export class MetricsController {
  @Get()
  @Public()
  getMetrics() {
    // Prometheus metrics are exposed automatically by PrometheusModule
    // This endpoint is just for documentation
    return {
      message: 'Metrics are available at /metrics endpoint',
      prometheus: '/metrics',
    };
  }

  @Get('health')
  @Public()
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }
}
