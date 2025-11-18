import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RtcController } from './rtc.controller';
import { RtcService } from './rtc.service';
import { AiAgentService } from './ai-agent.service';
import { AnalyticsService } from './analytics.service';
import { MonitoringService } from './monitoring.service';
import { LessonsModule } from '../lessons/lessons.module';
import { RedisModule } from '../../common/redis/redis.module';
import { SpeechModule } from '../speech/speech.module';
import { ChatAiModule } from '../chat-ai/chat-ai.module';
import { VideoCallSession } from './entities/video-call-session.entity';
import { ConversationTurn } from './entities/conversation-turn.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([VideoCallSession, ConversationTurn]),
    LessonsModule,
    RedisModule,
    SpeechModule,
    ChatAiModule,
  ],
  controllers: [RtcController],
  providers: [
    RtcService,
    AiAgentService,
    AnalyticsService,
    MonitoringService,
    {
      provide: 'AI_AGENT_MONITORING_SETUP',
      useFactory: (
        aiAgentService: AiAgentService,
        monitoringService: MonitoringService,
      ) => {
        aiAgentService.setMonitoringService(monitoringService);
        return true;
      },
      inject: [AiAgentService, MonitoringService],
    },
  ],
  exports: [RtcService, AiAgentService, AnalyticsService, MonitoringService],
})
export class RtcModule {}
