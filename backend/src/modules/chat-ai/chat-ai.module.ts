import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatAiController } from './chat-ai.controller';
import { ChatAiService } from './chat-ai.service';
import { GeminiProvider } from './providers/gemini.provider';
import { OpenAiProvider } from './providers/openai.provider';
import { ChatSession } from './entities/chat-session.entity';
import { RedisModule } from '../../common/redis/redis.module';
import { SpeechModule } from '../speech/speech.module';

@Module({
  imports: [TypeOrmModule.forFeature([ChatSession]), RedisModule, SpeechModule],
  controllers: [ChatAiController],
  providers: [ChatAiService, GeminiProvider, OpenAiProvider],
  exports: [ChatAiService],
})
export class ChatAiModule {}
