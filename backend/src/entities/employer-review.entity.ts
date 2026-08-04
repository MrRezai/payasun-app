import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Inquiry } from './inquiry.entity';
import { WelderProfile } from './welder-profile.entity';
import { User } from './user.entity';

@Entity('employer_reviews')
export class EmployerReview {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  inquiry_id: string;

  @ManyToOne(() => Inquiry, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'inquiry_id' })
  inquiry: Inquiry;

  @Column({ type: 'uuid' })
  welder_id: string;

  @ManyToOne(() => WelderProfile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'welder_id' })
  welder: WelderProfile;

  @Column({ type: 'uuid' })
  employer_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'employer_id' })
  employer: User;

  @Column({ type: 'decimal', precision: 3, scale: 2 })
  quality_score: number;

  @Column({ type: 'decimal', precision: 3, scale: 2 })
  punctuality_score: number;

  @Column({ type: 'decimal', precision: 3, scale: 2 })
  behavior_score: number;

  @Column({ type: 'decimal', precision: 3, scale: 2 })
  calculated_rating: number;

  @Column({ type: 'text', nullable: true })
  comment: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at: Date;
}
