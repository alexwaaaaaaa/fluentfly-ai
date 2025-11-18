import { BullModuleOptions } from '@nestjs/bull';
import { ConfigService } from '@nestjs/config';

export const getQueueConfig = (
  configService: ConfigService,
): BullModuleOptions => {
  const redisUrl = configService.get<string>('REDIS_URL');

  if (!redisUrl) {
    throw new Error('REDIS_URL is required for queue system');
  }

  // Parse Redis URL
  const url = new URL(redisUrl);

  return {
    redis: {
      host: url.hostname,
      port: parseInt(url.port) || 6379,
      password: url.password || undefined,
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      retryStrategy: (times: number) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
    },
    defaultJobOptions: {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
      removeOnComplete: 100, // Keep last 100 completed jobs
      removeOnFail: 500, // Keep last 500 failed jobs
    },
  };
};

// Queue names
export const QUEUES = {
  AUDIO_PROCESSING: 'audio-processing',
  SPEECH_SYNTHESIS: 'speech-synthesis',
  AI_FEEDBACK: 'ai-feedback',
  NOTIFICATIONS: 'notifications',
  ANALYTICS: 'analytics',
  VIDEO_CALL_CLEANUP: 'video-call-cleanup',
} as const;

// Job priorities
export const JOB_PRIORITY = {
  CRITICAL: 1,
  HIGH: 2,
  NORMAL: 3,
  LOW: 4,
} as const;
