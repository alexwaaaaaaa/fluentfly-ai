import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('chat_sessions')
@Index(['userId'])
export class ChatSession {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', name: 'user_id' })
  userId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 255, nullable: true })
  topic: string;

  @Column({ type: 'jsonb', nullable: true })
  transcript: any[]; // Array of { role, text, timestamp }

  @Column({ type: 'jsonb', nullable: true })
  feedback: Record<string, any>; // { fluency, pronunciation, grammar, tips }

  @Column({ type: 'int', nullable: true })
  duration: number; // seconds

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
