import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User } from '../entities/user.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Role } from '../common/enums/role.enum';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto';
import { UpdateWelderProfileDto } from './dto/update-welder-profile.dto';
import { UpdateWelderPricesDto } from './dto/update-welder-prices.dto';

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,

    @InjectRepository(EmployerProfile)
    private readonly employerProfileRepository: Repository<EmployerProfile>,

    @InjectRepository(WelderProfile)
    private readonly welderProfileRepository: Repository<WelderProfile>,
  ) {}

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

    const updated = await this.welderProfileRepository.save(profile);
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
}
