import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum InquiryStatus {
  DRAFT = 'DRAFT',
  PENDING_ESTIMATION = 'PENDING_ESTIMATION',
  ESTIMATED = 'ESTIMATED',
  BROADCASTED = 'BROADCASTED',
  REJECTED = 'REJECTED',
}

export interface InquiryItem {
  title: string;
  unit: string;
  quantity: number;
}

/**
 * Inquiry entity representing a project or job request created by an Employer.
 * It can either contain a manual list of items or a uploaded architectural blueprint plan
 * which will be estimated by the service (admin/welder).
 */
@Entity('inquiries')
export class Inquiry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

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

  @Column({ type: 'enum', enum: InquiryStatus, default: InquiryStatus.DRAFT })
  status: InquiryStatus;

  @Column({ type: 'boolean', default: false })
  has_blueprint: boolean;

  @Column({ type: 'varchar', length: 500, nullable: true })
  blueprint_url: string | null;

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
