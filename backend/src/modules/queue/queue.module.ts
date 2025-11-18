import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { getQueueConfig, QUEUES } from '../../config/queue.config';
import { AudioProcessingProcessor } from './processors/audio-processing.processor';
import { SpeechSynthesisProcessor } from './processors/speech-synthesis.processor';
import { AiFeedbackProcessor } from './processors/ai-feedback.processor';
import { AnalyticsProcessor } from './processors/analytics.processor';
import { QueueService } from './queue.service';

@Module({
  imports: [
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: getQueueConfig,
      inject: [ConfigService],
    }),
    BullModule.registerQueue(
      { name: QUEUES.AUDIO_PROCESSING },
      { name: QUEUES.SPEECH_SYNTHESIS },
      { name: QUEUES.AI_FEEDBACK },
      { name: QUEUES.ANALYTICS },
      { name: QUEUES.VIDEO_CALL_CLEANUP },
    ),
  ],
  providers: [
    QueueService,
    AudioProcessingProcessor,
    SpeechSynthesisProcessor,
    AiFeedbackProcessor,
    AnalyticsProcessor,
  ],
  exports: [QueueService, BullModule],
})
export class QueueModule {}
