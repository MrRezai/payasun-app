import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Inquiry } from './inquiry.entity';
import { WelderProfile } from './welder-profile.entity';

export interface OfferItemPrice {
  title: string;
  price: number;
}

@Entity('offers')
export class Offer {
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
  @JoinColumn({ name: 'welder_id', referencedColumnName: 'id' })
  welder: WelderProfile;

  @Column({ type: 'jsonb', default: [] })
  items_prices: OfferItemPrice[];

  @Column({ type: 'bigint' })
  total_price: number;

  @Column({ type: 'boolean', default: false })
  scaffold_checked: boolean;

  @Column({ type: 'boolean', default: false })
  power_checked: boolean;

  @Column({ type: 'boolean', default: false })
  rod_checked: boolean;

  @Column({ type: 'boolean', default: false })
  delivery_checked: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at: Date;
}
