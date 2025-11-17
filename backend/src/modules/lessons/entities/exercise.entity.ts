import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Lesson } from './lesson.entity';

@Entity('exercises')
export class Exercise {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', name: 'lesson_id' })
  lessonId: number;

  @ManyToOne(() => Lesson, (lesson) => lesson.exercises, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'lesson_id' })
  lesson: Lesson;

  @Column({ type: 'varchar', length: 50 })
  type: string; // 'mcq', 'fill_blank', 'speaking', 'listening', 'vocabulary'

  @Column({ type: 'text' })
  question: string;

  @Column({ type: 'jsonb', nullable: true })
  options: any[];

  @Column({ type: 'jsonb', nullable: true })
  answer: Record<string, any>;

  @Column({ type: 'text', nullable: true, name: 'audio_url' })
  audioUrl: string;

  @Column({ type: 'int', nullable: true, name: 'order_index' })
  orderIndex: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
