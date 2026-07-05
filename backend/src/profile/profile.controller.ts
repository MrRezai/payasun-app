import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ProfileService } from './profile.service';
import { UpdateEmployerProfileDto } from './dto/update-employer-profile.dto';
import { UpdateWelderProfileDto } from './dto/update-welder-profile.dto';
import { UpdateWelderPricesDto } from './dto/update-welder-prices.dto';

@ApiTags('Profile')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard)
@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  /**
   * GET /profile
   *
   * Returns the authenticated user's core data along with their
   * role-specific profile (EmployerProfile or WelderProfile).
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get My Profile',
    description:
      'Returns the full user record and the corresponding role-specific ' +
      'profile data (EmployerProfile or WelderProfile) based on the JWT payload.',
  })
  @ApiResponse({
    status: 200,
    description: 'User and profile data returned successfully.',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized — missing or invalid JWT token.',
  })
  @ApiResponse({
    status: 404,
    description: 'User or profile not found.',
  })
  async getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.profileService.getProfile(user.id, user.role);
  }

  /**
   * PATCH /profile/employer
   *
   * Partially updates the authenticated employer's profile.
   * Only provided fields will be overwritten.
   */
  @Patch('employer')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update Employer Profile',
    description:
      'Partially updates the employer profile. Only fields included in the ' +
      'request body will be modified. Requires the EMPLOYER role.',
  })
  @ApiBody({ type: UpdateEmployerProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Employer profile updated successfully.',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized — missing or invalid JWT token.',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden — user does not have the EMPLOYER role.',
  })
  @ApiResponse({
    status: 404,
    description: 'Employer profile not found.',
  })
  async updateEmployerProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateEmployerProfileDto,
  ) {
    return this.profileService.updateEmployerProfile(user.id, user.role, dto);
  }

  /**
   * PATCH /profile/welder
   *
   * Partially updates the authenticated welder's profile.
   * Only provided fields will be overwritten.
   */
  @Patch('welder')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update Welder Profile',
    description:
      'Partially updates the welder profile fields including full_name, ' +
      'home_city, active_cities array, and bio. Only fields included in ' +
      'the request body will be modified. Requires the WELDER role.',
  })
  @ApiBody({ type: UpdateWelderProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Welder profile updated successfully.',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized — missing or invalid JWT token.',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden — user does not have the WELDER role.',
  })
  @ApiResponse({
    status: 404,
    description: 'Welder profile not found.',
  })
  async updateWelderProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateWelderProfileDto,
  ) {
    return this.profileService.updateWelderProfile(user.id, user.role, dto);
  }

  /**
   * PUT /profile/welder/prices
   *
   * Initializes or fully replaces the welder's base price list
   * for future auto-pricing features.
   */
  @Put('welder/prices')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Set Welder Price List',
    description:
      'Initializes or completely replaces the welder\'s base_price_list. ' +
      'This is a PUT operation — the entire existing list is overwritten ' +
      'with the provided array. Requires the WELDER role.',
  })
  @ApiBody({ type: UpdateWelderPricesDto })
  @ApiResponse({
    status: 200,
    description: 'Welder price list updated successfully.',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized — missing or invalid JWT token.',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden — user does not have the WELDER role.',
  })
  @ApiResponse({
    status: 404,
    description: 'Welder profile not found.',
  })
  async updateWelderPrices(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateWelderPricesDto,
  ) {
    return this.profileService.updateWelderPrices(user.id, user.role, dto);
  }
}
