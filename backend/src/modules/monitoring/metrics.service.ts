import { Injectable } from '@nestjs/common';
import { InjectMetric } from '@willsoto/nestjs-prometheus';
import { Counter, Histogram, Gauge } from 'prom-client';

@Injectable()
export class MetricsService {
  constructor(
    @InjectMetric('http_requests_total')
    private readonly httpRequestsCounter: Counter,
    
    @InjectMetric('http_request_duration_seconds')
    private readonly httpRequestDuration: Histogram,
    
    @InjectMetric('active_users')
    private readonly activeUsersGauge: Gauge,
    
    @InjectMetric('video_calls_active')
    private readonly videoCallsGauge: Gauge,
    
    @InjectMetric('database_connections')
    private readonly dbConnectionsGauge: Gauge,
    
    @InjectMetric('cache_hits_total')
    private readonly cacheHitsCounter: Counter,
    
    @InjectMetric('cache_misses_total')
    private readonly cacheMissesCounter: Counter,
    
    @InjectMetric('queue_jobs_total')
    private readonly queueJobsCounter: Counter,
    
    @InjectMetric('queue_jobs_failed_total')
    private readonly queueJobsFailedCounter: Counter,
  ) {}

  // HTTP Metrics
  incrementHttpRequests(method: string, route: string, statusCode: number) {
    this.httpRequestsCounter.inc({
      method,
      route,
      status_code: statusCode,
    });
  }

  recordHttpDuration(method: string, route: string, duration: number) {
    this.httpRequestDuration.observe(
      {
        method,
        route,
      },
      duration,
    );
  }

  // User Metrics
  setActiveUsers(count: number) {
    this.activeUsersGauge.set(count);
  }

  // Video Call Metrics
  setActiveVideoCalls(count: number) {
    this.videoCallsGauge.set(count);
  }

  // Database Metrics
  setDatabaseConnections(count: number) {
    this.dbConnectionsGauge.set(count);
  }

  // Cache Metrics
  incrementCacheHits(key: string) {
    this.cacheHitsCounter.inc({ key });
  }

  incrementCacheMisses(key: string) {
    this.cacheMissesCounter.inc({ key });
  }

  // Queue Metrics
  incrementQueueJobs(queue: string, job: string) {
    this.queueJobsCounter.inc({ queue, job });
  }

  incrementQueueJobsFailed(queue: string, job: string, error: string) {
    this.queueJobsFailedCounter.inc({ queue, job, error });
  }
}
