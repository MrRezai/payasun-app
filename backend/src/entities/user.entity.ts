import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { Role } from '../common/enums/role.enum';

/**
 * Core user entity representing any registered user in the Payasun platform.
 * Users are identified by their unique phone number and assigned a single role
 * (EMPLOYER or WELDER) upon first OTP verification.
 */
@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 15, unique: true })
  phone_number: string;

  @Column({ type: 'enum', enum: Role })
  role: Role;

  @Column({ type: 'enum', enum: Role, nullable: true })
  initial_role: Role;

  @Column({ type: 'jsonb', default: [] })
  roles: Role[];
  @Column({ type: 'boolean', default: false })
  is_authenticated: boolean;

  @Column({ type: 'boolean', default: false })
  is_blocked: boolean;
  @CreateDateColumn({ type: 'timestamptz' })
  created_at: Date;
}
