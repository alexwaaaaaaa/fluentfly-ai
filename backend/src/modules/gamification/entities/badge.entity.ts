import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('badges')
export class Badge {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 100, unique: true })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text', nullable: true, name: 'icon_url' })
  iconUrl: string;

  @Column({ type: 'jsonb', nullable: true })
  criteria: Record<string, any>; // { type: 'streak', value: 7 }

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
