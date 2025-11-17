import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { VideoCallSession } from './video-call-session.entity';

@Entity('conversation_turns')
@Index(['sessionId'])
export class ConversationTurn {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', name: 'session_id' })
  sessionId: number;

  @ManyToOne(() => VideoCallSession, (session) => session.conversationTurns, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'session_id' })
  session: VideoCallSession;

  @Column({ type: 'varchar', length: 10 })
  speaker: 'user' | 'ai';

  @Column({ type: 'text' })
  text: string;

  @Column({ type: 'timestamp' })
  timestamp: Date;

  @Column({ type: 'text', name: 'audio_url', nullable: true })
  audioUrl: string;

  @Column({ type: 'int', name: 'word_count', nullable: true })
  wordCount: number;

  @Column({ type: 'int', name: 'duration_ms', nullable: true })
  durationMs: number; // milliseconds

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
