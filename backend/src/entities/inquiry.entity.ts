import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Project } from './project.entity';

export enum InquiryStatus {
  DRAFT = 'DRAFT',
  PENDING_ESTIMATION = 'PENDING_ESTIMATION',
  ESTIMATED = 'ESTIMATED',
  BROADCASTED = 'BROADCASTED',
  DISPATCHED = 'DISPATCHED',
  AGREEMENT_PENDING_WELDER = 'AGREEMENT_PENDING_WELDER',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED_PENDING_EMPLOYER = 'COMPLETED_PENDING_EMPLOYER',
  COMPLETED = 'COMPLETED',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED',
}

export interface InquiryItem {
  title: string;
  unit: string;
  quantity: number;
  category?: 'GIRESH' | 'OTHER';
}

/**
 * Inquiry entity representing a job request created by an Employer under a parent Project.
 */
@Entity('inquiries')
export class Inquiry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', nullable: true })
  projectId: string | null;

  @ManyToOne(() => Project, (project) => project.inquiries, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'projectId' })
  project: Project | null;

  @Column({ type: 'uuid' })
  employerId: string;

  @Column({ type: 'varchar', length: 255 })
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'varchar', length: 100 })
  city: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  province: string | null;

  @Column({ type: 'text', nullable: true })
  address: string | null;

  @Column({ type: 'enum', enum: InquiryStatus, default: InquiryStatus.DRAFT })
  status: InquiryStatus;

  @Column({ type: 'varchar', length: 10, default: 'A' })
  tier: string;

  @Column({ type: 'int', nullable: true })
  floor_count: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  area_sqm: number | null;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  deposit_amount: number;

  @Column({ type: 'int', default: 0 })
  giresh_count: number;

  @Column({ type: 'int', default: 0 })
  other_installs_count: number;

  @Column({ type: 'boolean', default: false })
  is_re_dispatched: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  dispatched_at: Date | null;

  @Column({ type: 'boolean', default: false })
  has_blueprint: boolean;

  @Column({ type: 'varchar', length: 500, nullable: true })
  blueprint_url: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true, default: 'ROUGH' })
  estimation_type: string | null;

  @Column({ type: 'text', nullable: true })
  rejection_reason: string | null;

  /**
   * JSONB array of estimation items.
   * Example: [{ "title": "جوشکاری ستون", "unit": "عدد", "quantity": 12 }]
   */
  @Column({ type: 'jsonb', default: [] })
  items: InquiryItem[];

  @CreateDateColumn({ type: 'timestamptz' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at: Date;
}
