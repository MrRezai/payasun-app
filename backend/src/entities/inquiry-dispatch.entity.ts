import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Inquiry } from './inquiry.entity';
import { WelderProfile } from './welder-profile.entity';

export enum DispatchType {
  TOP_SCORE = 'TOP_SCORE',
  NEWCOMER = 'NEWCOMER',
  RANDOM = 'RANDOM',
  REPLACEMENT = 'REPLACEMENT',
}

export enum DispatchStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  DECLINED = 'DECLINED',
  TIMED_OUT = 'TIMED_OUT',
  REPLACED = 'REPLACED',
}

@Entity('inquiry_dispatches')
export class InquiryDispatch {
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

  @Column({ type: 'enum', enum: DispatchType, default: DispatchType.TOP_SCORE })
  dispatch_type: DispatchType;

  @Column({ type: 'int', default: 1 })
  dispatch_round: number;

  @Column({ type: 'enum', enum: DispatchStatus, default: DispatchStatus.PENDING })
  status: DispatchStatus;

  @CreateDateColumn({ type: 'timestamptz' })
  dispatched_at: Date;

  @Column({ type: 'timestamptz', nullable: true })
  responded_at: Date | null;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at: Date;
}
