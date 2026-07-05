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

    if (dto.full_name !== undefined) {
      profile.full_name = dto.full_name;
    }
    if (dto.city !== undefined) {
      profile.city = dto.city;
    }

    const updated = await this.employerProfileRepository.save(profile);

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

    if (dto.full_name !== undefined) {
      profile.full_name = dto.full_name;
    }
    if (dto.home_city !== undefined) {
      profile.home_city = dto.home_city;
    }
    if (dto.active_cities !== undefined) {
      profile.active_cities = dto.active_cities;
    }
    if (dto.bio !== undefined) {
      profile.bio = dto.bio;
    }

    const updated = await this.welderProfileRepository.save(profile);

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
