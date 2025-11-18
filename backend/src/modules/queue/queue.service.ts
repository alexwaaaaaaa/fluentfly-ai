import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { QUEUES, JOB_PRIORITY } from '../../config/queue.config';

@Injectable()
export class QueueService {
  constructor(
    @InjectQueue(QUEUES.AUDIO_PROCESSING) private audioQueue: Queue,
    @InjectQueue(QUEUES.SPEECH_SYNTHESIS) private speechQueue: Queue,
    @InjectQueue(QUEUES.AI_FEEDBACK) private feedbackQueue: Queue,
    @InjectQueue(QUEUES.ANALYTICS) private analyticsQueue: Queue,
    @InjectQueue(QUEUES.VIDEO_CALL_CLEANUP) private cleanupQueue: Queue,
  ) {}

  // Audio processing
  async processAudio(data: {
    audioUrl: string;
    userId: number;
    sessionId: number;
  }) {
    return this.audioQueue.add('process-audio', data, {
      priority: JOB_PRIORITY.HIGH,
      attempts: 3,
    });
  }

  // Speech synthesis
  async synthesizeSpeech(data: {
    text: string;
    voice: string;
    userId: number;
  }) {
    return this.speechQueue.add('synthesize', data, {
      priority: JOB_PRIORITY.NORMAL,
      attempts: 3,
    });
  }

  // AI feedback generation
  async generateFeedback(data: {
    transcription: string;
    expectedAnswer: string;
    userId: number;
    lessonId: number;
  }) {
    return this.feedbackQueue.add('generate-feedback', data, {
      priority: JOB_PRIORITY.HIGH,
      attempts: 2,
    });
  }

  // Analytics tracking
  async trackEvent(data: {
    userId: number;
    event: string;
    metadata: Record<string, any>;
  }) {
    return this.analyticsQueue.add('track-event', data, {
      priority: JOB_PRIORITY.LOW,
      attempts: 1,
      removeOnComplete: true,
    });
  }

  // Video call cleanup
  async cleanupVideoCall(data: { sessionId: number; roomName: string }) {
    return this.cleanupQueue.add('cleanup', data, {
      priority: JOB_PRIORITY.NORMAL,
      delay: 60000, // 1 minute delay
      attempts: 2,
    });
  }

  // Get queue stats
  async getQueueStats() {
    const queues = [
      { name: 'audio', queue: this.audioQueue },
      { name: 'speech', queue: this.speechQueue },
      { name: 'feedback', queue: this.feedbackQueue },
      { name: 'analytics', queue: this.analyticsQueue },
      { name: 'cleanup', queue: this.cleanupQueue },
    ];

    const stats = await Promise.all(
      queues.map(async ({ name, queue }) => {
        const [waiting, active, completed, failed] = await Promise.all([
          queue.getWaitingCount(),
          queue.getActiveCount(),
          queue.getCompletedCount(),
          queue.getFailedCount(),
        ]);

        return {
          name,
          waiting,
          active,
          completed,
          failed,
        };
      }),
    );

    return stats;
  }
}
