import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Lesson } from '../../lessons/entities/lesson.entity';
import { ConversationTurn } from './conversation-turn.entity';

@Entity('video_call_sessions')
@Index(['userId'])
@Index(['lessonId'])
@Index(['userId', 'lessonId'])
export class VideoCallSession {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', name: 'user_id' })
  userId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'int', name: 'lesson_id', nullable: true })
  lessonId: number | null;

  @ManyToOne(() => Lesson, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'lesson_id' })
  lesson: Lesson;

  @Column({ type: 'varchar', length: 255, name: 'room_name' })
  roomName: string;

  @Column({ type: 'timestamp', name: 'start_time' })
  startTime: Date;

  @Column({ type: 'timestamp', name: 'end_time', nullable: true })
  endTime: Date;

  @Column({ type: 'int', nullable: true })
  duration: number; // seconds

  @Column({ type: 'jsonb', nullable: true })
  analytics: {
    totalSpeakingTime: number; // seconds
    wordsPerMinute: number;
    pauseCount: number;
    averagePauseLength: number; // seconds
    fluencyScore: number; // 0-100
    turnCount: number;
  };

  @OneToMany(() => ConversationTurn, (turn) => turn.session)
  conversationTurns: ConversationTurn[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
