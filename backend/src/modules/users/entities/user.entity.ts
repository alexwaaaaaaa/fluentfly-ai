import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('users')
@Index(['xp'])
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255, unique: true, nullable: true })
  email: string;

  @Column({ type: 'varchar', length: 20, unique: true, nullable: true })
  phone: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'int', default: 0 })
  xp: number;

  @Column({ type: 'int', default: 0 })
  streak: number;

  @Column({ type: 'varchar', length: 10, default: 'A1' })
  level: string;

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
    name: 'learning_purpose',
  })
  learningPurpose: string;

  @Column({
    type: 'varchar',
    length: 50,
    nullable: true,
    name: 'english_level',
  })
  englishLevel: string;

  @Column({ type: 'date', nullable: true, name: 'last_active_date' })
  lastActiveDate: Date;

  @Column({ type: 'text', nullable: true, name: 'profile_image_url' })
  profileImageUrl: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
