import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

/**
 * Profile entity for users with the EMPLOYER role.
 * Created automatically upon first successful OTP verification
 * and populated later via the profile update endpoints.
 */
@Entity('employer_profiles')
export class EmployerProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  user_id: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 255, nullable: true })
  full_name: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  province: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  city: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  company_name: string | null;

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  @Column({ type: 'boolean', default: false })
  is_setup_completed: boolean;
}
