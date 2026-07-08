import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { User } from './user.entity';
import { Skill } from './skill.entity';

/**
 * Represents a single item in the welder's pre-configured pricing list.
 * Stored as JSONB in the base_price_list column.
 */
export interface BasePriceItem {
  /** Descriptive title of the service (e.g., "Argon Welding per Joint") */
  title: string;
  /** Measurement unit (e.g., "per joint", "per meter", "per hour") */
  unit: string;
  /** Price per unit in Rials */
  price_per_unit: number;
}

/**
 * Profile entity for users with the WELDER role.
 * Contains operational details, city coverage, biographical info,
 * auto-pricing configuration, and performance metrics.
 *
 * Created automatically upon first successful OTP verification
 * and enriched via profile update endpoints.
 */
@Entity('welder_profiles')
export class WelderProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  user_id: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 150, nullable: true })
  first_name: string | null;

  @Column({ type: 'varchar', length: 150, nullable: true })
  last_name: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  home_city: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  home_province: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  active_province: string | null;

  /**
   * JSONB array of city names where the welder is willing to operate.
   * Example: ["کرمان", "بم", "رفسنجان", "جیرفت"]
   */
  @Column({ type: 'jsonb', default: [] })
  active_cities: string[];

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  /**
   * JSONB array of pre-configured pricing items for automatic quoting.
   * Each item has a title, unit, and price_per_unit.
   */
  @Column({ type: 'jsonb', default: [] })
  base_price_list: BasePriceItem[];

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 0 })
  total_score: number;

  @Column({ type: 'int', default: 0 })
  completed_jobs_count: number;

  @Column({ type: 'boolean', default: false })
  is_setup_completed: boolean;

  @Column({ type: 'varchar', length: 500, nullable: true })
  profile_picture_url: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  pending_profile_picture_url: string | null;

  @Column({ type: 'varchar', length: 50, default: 'NONE' })
  profile_picture_status: string;

  @ManyToMany(() => Skill, { onDelete: 'CASCADE' })
  @JoinTable({
    name: 'welder_skills',
    joinColumn: { name: 'welder_profile_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'skill_id', referencedColumnName: 'id' },
  })
  skills: Skill[];
}
