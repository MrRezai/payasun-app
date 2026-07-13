import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { join } from 'path';
import { existsSync, unlinkSync } from 'fs';

import { User } from '../entities/user.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Skill } from '../entities/skill.entity';
import { Role } from '../common/enums/role.enum';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto';
import { UpdateWelderProfileDto } from './dto/update-welder-profile.dto';
import { UpdateWelderPricesDto } from './dto/update-welder-prices.dto';

@Injectable()
export class ProfileService implements OnModuleInit {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(EmployerProfile)
    private readonly employerProfileRepository: Repository<EmployerProfile>,

    @InjectRepository(WelderProfile)
    private readonly welderProfileRepository: Repository<WelderProfile>,

    @InjectRepository(Skill)
    private readonly skillRepository: Repository<Skill>,
  ) {}

  async onModuleInit() {
    await this.seedSkills();
  }

  private async seedSkills() {
    try {
      const count = await this.skillRepository.count();
      if (count === 0) {
        this.logger.log('Seeding default skills...');
        const defaultSkills = [
          'جوشکاری لوله گاز (خانگی / صنعتی)',
          'جوشکاری آرگون (TIG)',
          'جوشکاری CO2 (MIG/MAG)',
          'جوشکاری اسکلت و سازه‌های فلزی',
          'جوشکاری درب و پنجره و نرده',
          'برشکاری و خم‌کاری فلزات',
        ];
        for (const name of defaultSkills) {
          const skill = this.skillRepository.create({ name });
          await this.skillRepository.save(skill);
        }
        this.logger.log('Default skills seeded successfully!');
      }
    } catch (e) {
      this.logger.error(`Failed to seed skills: ${e.message}`);
    }
  }

  /**
   * Returns the authenticated user's core data together with their
   * role-specific profile (EmployerProfile or WelderProfile).
   *
   * @param userId - The UUID of the authenticated user
   * @param role   - The user's role from the JWT payload
   */
  async getProfile(
    userId: string,
    role: Role,
  ): Promise<{ user: User; profile: EmployerProfile | WelderProfile }> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    let profile: EmployerProfile | WelderProfile | null;

    if (role === Role.EMPLOYER) {
      profile = await this.employerProfileRepository.findOne({
        where: { user_id: userId },
      });
    } else {
      profile = await this.welderProfileRepository.findOne({
        where: { user_id: userId },
        relations: ['skills'],
      });
    }

    if (!profile) {
      throw new NotFoundException('Profile not found. Please contact support.');
    }

    if (role === Role.WELDER) {
      const welderProfile = profile as WelderProfile;
      (welderProfile as any).full_name =
        `${welderProfile.first_name || ''} ${welderProfile.last_name || ''}`.trim();
    } else if (role === Role.EMPLOYER) {
      const employerProfile = profile as EmployerProfile;
      (employerProfile as any).full_name =
        `${employerProfile.first_name || ''} ${employerProfile.last_name || ''}`.trim();
    }

    return { user, profile };
  }

  /**
   * Partially updates the employer's profile. Only fields present in the
   * DTO will be overwritten; omitted fields remain unchanged.
   *
   * @param userId - The UUID of the authenticated user
   * @param role   - Must be EMPLOYER
   * @param dto    - The fields to update
   */
  async updateEmployerProfile(
    userId: string,
    role: Role,
    dto: UpdateEmployerProfileDto,
  ): Promise<EmployerProfile> {
    if (role !== Role.EMPLOYER) {
      throw new ForbiddenException(
        'Only users with the EMPLOYER role can update an employer profile.',
      );
    }

    const profile = await this.employerProfileRepository.findOne({
      where: { user_id: userId },
    });

    if (!profile) {
      throw new NotFoundException('Employer profile not found.');
    }

    if (dto.first_name !== undefined) {
      profile.first_name = dto.first_name;
    }
    if (dto.last_name !== undefined) {
      profile.last_name = dto.last_name;
    }
    if (dto.province !== undefined) {
      profile.province = dto.province;
    }
    if (dto.city !== undefined) {
      profile.city = dto.city;
    }
    if (dto.company_name !== undefined) {
      profile.company_name = dto.company_name;
    }
    if (dto.bio !== undefined) {
      profile.bio = dto.bio;
    }
    if (dto.is_setup_completed !== undefined) {
      profile.is_setup_completed = dto.is_setup_completed;
    }

    const updated = await this.employerProfileRepository.save(profile);
    (updated as any).full_name = `${updated.first_name || ''} ${updated.last_name || ''}`.trim();

    // Sync name to welder profile if exists
    const welderProfile = await this.welderProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (welderProfile) {
      if (updated.first_name !== null) welderProfile.first_name = updated.first_name;
      if (updated.last_name !== null) welderProfile.last_name = updated.last_name;
      await this.welderProfileRepository.save(welderProfile);
    }

    this.logger.log(`Employer profile updated for user ${userId}`);
    return updated;
  }

  /**
   * Partially updates the welder's profile. Only fields present in the
   * DTO will be overwritten; omitted fields remain unchanged.
   *
   * @param userId - The UUID of the authenticated user
   * @param role   - Must be WELDER
   * @param dto    - The fields to update
   */
  async updateWelderProfile(
    userId: string,
    role: Role,
    dto: UpdateWelderProfileDto,
  ): Promise<WelderProfile> {
    if (role !== Role.WELDER) {
      throw new ForbiddenException(
        'Only users with the WELDER role can update a welder profile.',
      );
    }

    const profile = await this.welderProfileRepository.findOne({
      where: { user_id: userId },
      relations: ['skills'],
    });

    if (!profile) {
      throw new NotFoundException('Welder profile not found.');
    }

    if (dto.first_name !== undefined) {
      profile.first_name = dto.first_name;
    }
    if (dto.last_name !== undefined) {
      profile.last_name = dto.last_name;
    }
    if (dto.home_city !== undefined) {
      profile.home_city = dto.home_city;
    }
    if (dto.home_province !== undefined) {
      profile.home_province = dto.home_province;
    }
    if (dto.active_province !== undefined) {
      profile.active_province = dto.active_province;
    }
    if (dto.active_cities !== undefined) {
      profile.active_cities = dto.active_cities;
    }
    if (dto.bio !== undefined) {
      profile.bio = dto.bio;
    }
    if (dto.is_setup_completed !== undefined) {
      profile.is_setup_completed = dto.is_setup_completed;
    }
    if (dto.skill_ids !== undefined) {
      if (dto.skill_ids && dto.skill_ids.length > 0) {
        const skills = await this.skillRepository.findBy({ id: In(dto.skill_ids) });
        profile.skills = skills;
      } else {
        profile.skills = [];
      }
    }

    const updated = await this.welderProfileRepository.save(profile);
    updated.skills = profile.skills;
    const fullNameVal = `${updated.first_name || ''} ${updated.last_name || ''}`.trim();
    (updated as any).full_name = fullNameVal;

    // Sync name to employer profile if exists
    const employerProfile = await this.employerProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (employerProfile) {
      if (updated.first_name !== null) employerProfile.first_name = updated.first_name;
      if (updated.last_name !== null) employerProfile.last_name = updated.last_name;
      await this.employerProfileRepository.save(employerProfile);
    }

    this.logger.log(`Welder profile updated for user ${userId}`);
    return updated;
  }

  /**
   * Replaces the welder's entire base price list (PUT semantics).
   * The old list is fully overwritten by the new one.
   *
   * @param userId - The UUID of the authenticated user
   * @param role   - Must be WELDER
   * @param dto    - Contains the complete new price list
   */
  async updateWelderPrices(
    userId: string,
    role: Role,
    dto: UpdateWelderPricesDto,
  ): Promise<WelderProfile> {
    if (role !== Role.WELDER) {
      throw new ForbiddenException(
        'Only users with the WELDER role can update the price list.',
      );
    }

    const profile = await this.welderProfileRepository.findOne({
      where: { user_id: userId },
    });

    if (!profile) {
      throw new NotFoundException('Welder profile not found.');
    }

    profile.base_price_list = dto.base_price_list;

    const updated = await this.welderProfileRepository.save(profile);

    this.logger.log(
      `Welder price list updated for user ${userId} (${dto.base_price_list.length} items)`,
    );
    return updated;
  }

  async uploadProfilePicture(
    userId: string,
    role: Role,
    file: Express.Multer.File,
  ): Promise<{ user: User; profile: EmployerProfile | WelderProfile }> {
    const profileData = await this.getProfile(userId, role);
    const profile = profileData.profile;

    const fileUrl = `/uploads/profile-pictures/${file.filename}`;

    // Clean up old pending picture if exists
    if (profile.pending_profile_picture_url) {
      this.deletePhysicalFile(profile.pending_profile_picture_url);
    }

    profile.pending_profile_picture_url = fileUrl;
    profile.profile_picture_status = 'PENDING';

    if (role === Role.EMPLOYER) {
      await this.employerProfileRepository.save(profile as EmployerProfile);
    } else {
      await this.welderProfileRepository.save(profile as WelderProfile);
    }

    this.logger.log(`Uploaded profile picture for user ${userId} to ${fileUrl}`);
    return this.getProfile(userId, role);
  }

  async deleteProfilePicture(
    userId: string,
    role: Role,
  ): Promise<{ user: User; profile: EmployerProfile | WelderProfile }> {
    const profileData = await this.getProfile(userId, role);
    const profile = profileData.profile;

    // Delete current and pending files
    if (profile.profile_picture_url) {
      this.deletePhysicalFile(profile.profile_picture_url);
    }
    if (profile.pending_profile_picture_url) {
      this.deletePhysicalFile(profile.pending_profile_picture_url);
    }

    profile.profile_picture_url = null;
    profile.pending_profile_picture_url = null;
    profile.profile_picture_status = 'NONE';

    if (role === Role.EMPLOYER) {
      await this.employerProfileRepository.save(profile as EmployerProfile);
    } else {
      await this.welderProfileRepository.save(profile as WelderProfile);
    }

    this.logger.log(`Deleted profile picture for user ${userId}`);
    return this.getProfile(userId, role);
  }

  private deletePhysicalFile(fileUrl: string) {
    try {
      const parts = fileUrl.split('/');
      const filename = parts[parts.length - 1];
      const filePath = join(process.cwd(), 'uploads', 'profile-pictures', filename);
      if (existsSync(filePath)) {
        unlinkSync(filePath);
      }
    } catch (e) {
      this.logger.error(`Error deleting physical file ${fileUrl}: ${e}`);
    }
  }

  async getAllSkills(): Promise<Skill[]> {
    return this.skillRepository.find({ order: { id: 'ASC' } });
  }

  async createSkill(name: string): Promise<Skill> {
    const existing = await this.skillRepository.findOne({ where: { name } });
    if (existing) {
      return existing;
    }
    const skill = this.skillRepository.create({ name });
    return this.skillRepository.save(skill);
  }

  async updateSkill(id: number, name: string): Promise<Skill> {
    const skill = await this.skillRepository.findOne({ where: { id } });
    if (!skill) {
      throw new NotFoundException('Skill not found.');
    }
    skill.name = name;
    return this.skillRepository.save(skill);
  }

  async deleteSkill(id: number): Promise<void> {
    const result = await this.skillRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Skill not found.');
    }
  }

  // Admin and profile list methods
  async getWeldersCount(): Promise<number> {
    return this.welderProfileRepository.count();
  }

  async getEmployersCount(): Promise<number> {
    return this.employerProfileRepository.count();
  }

  async getPendingVerifications(): Promise<any[]> {
    const welders = await this.welderProfileRepository.find({
      where: { profile_picture_status: 'PENDING' },
    });
    const employers = await this.employerProfileRepository.find({
      where: { profile_picture_status: 'PENDING' },
    });

    const pendingWelders = welders.map((w) => {
      const name = w.first_name || w.last_name 
        ? `${w.first_name || ''} ${w.last_name || ''}`.trim() 
        : 'نامشخص (جوشکار)';
      return {
        id: w.user_id,
        name,
        role: 'WELDER',
        pending_url: w.pending_profile_picture_url,
        bio: w.bio || 'توضیحات ندارد.',
        phone: 'ثبت شده در سیستم',
      };
    });

    const pendingEmployers = employers.map((e) => {
      const contact = e.first_name || e.last_name 
        ? `${e.first_name || ''} ${e.last_name || ''}`.trim() 
        : 'کارفرما';
      return {
        id: e.user_id,
        name: `${e.company_name || 'شخصی'} (${contact})`,
        role: 'EMPLOYER',
        pending_url: e.pending_profile_picture_url,
        bio: 'ثبت شده به عنوان کارفرما در پلتفرم جفت‌وجور.',
        phone: 'ثبت شده در سیستم',
      };
    });

    return [...pendingWelders, ...pendingEmployers];
  }

  async verifyPicture(userId: string, role: string, approve: boolean): Promise<void> {
    if (role === 'WELDER') {
      const profile = await this.welderProfileRepository.findOne({ where: { user_id: userId } });
      if (!profile) throw new NotFoundException('جوشکار یافت نشد.');
      profile.profile_picture_status = approve ? 'APPROVED' : 'REJECTED';
      if (approve && profile.pending_profile_picture_url) {
        profile.profile_picture_url = profile.pending_profile_picture_url;
      }
      profile.pending_profile_picture_url = null;
      await this.welderProfileRepository.save(profile);
    } else {
      const profile = await this.employerProfileRepository.findOne({ where: { user_id: userId } });
      if (!profile) throw new NotFoundException('کارفرما یافت نشد.');
      profile.profile_picture_status = approve ? 'APPROVED' : 'REJECTED';
      if (approve && profile.pending_profile_picture_url) {
        profile.profile_picture_url = profile.pending_profile_picture_url;
      }
      profile.pending_profile_picture_url = null;
      await this.employerProfileRepository.save(profile);
    }
  }

  async getUsersList(): Promise<any[]> {
    const users = await this.userRepository.find({ order: { created_at: 'DESC' } });
    const welders = await this.welderProfileRepository.find();
    const employers = await this.employerProfileRepository.find();

    const weldersMap = new Map(welders.map((w) => [w.user_id, w]));
    const employersMap = new Map(employers.map((e) => [e.user_id, e]));

    return users.map((user) => {
      const welder = weldersMap.get(user.id);
      const employer = employersMap.get(user.id);

      const name = user.role === Role.WELDER
        ? (welder?.first_name || welder?.last_name ? `${welder.first_name || ''} ${welder.last_name || ''}`.trim() : 'جوشکار بدون نام')
        : (employer?.company_name || (employer?.first_name || employer?.last_name ? `${employer.first_name || ''} ${employer.last_name || ''}`.trim() : 'کارفرما بدون نام'));

      return {
        id: user.id,
        phone_number: user.phone_number,
        role: user.role,
        roles: user.roles || [user.role],
        created_at: user.created_at,
        name,
        city: user.role === Role.WELDER ? welder?.home_city : employer?.city,
        province: user.role === Role.WELDER ? welder?.home_province : employer?.province,
        profile_picture_url: user.role === Role.WELDER ? welder?.profile_picture_url : employer?.profile_picture_url,
      };
    });
  }
}

