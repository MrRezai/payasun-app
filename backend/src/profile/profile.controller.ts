import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Put,
  UseGuards,
  Post,
  Delete,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Param,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { existsSync, mkdirSync } from 'fs';
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

  /**
   * POST /profile/picture
   *
   * Uploads and sets a new profile picture. Status is set to PENDING.
   */
  @Post('picture')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Upload Profile Picture',
    description: 'Uploads a profile picture. Sent to pending approval state.',
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const uploadPath = './uploads/profile-pictures';
          if (!existsSync(uploadPath)) {
            mkdirSync(uploadPath, { recursive: true });
          }
          cb(null, uploadPath);
        },
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          cb(null, `profile-${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, cb) => {
        if (!file.originalname.match(/\.(jpg|jpeg|png)$/)) {
          return cb(new Error('Only JPG, JPEG, and PNG images are allowed!'), false);
        }
        cb(null, true);
      },
    }),
  )
  async uploadProfilePicture(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Please provide an image file.');
    }
    return this.profileService.uploadProfilePicture(user.id, user.role, file);
  }

  /**
   * DELETE /profile/picture
   *
   * Removes current/pending profile picture.
   */
  @Delete('picture')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete Profile Picture',
    description: 'Removes the current and pending profile pictures.',
  })
  async deleteProfilePicture(@CurrentUser() user: AuthenticatedUser) {
    return this.profileService.deleteProfilePicture(user.id, user.role);
  }

  /**
   * GET /profile/skills
   * Returns a list of all skills configured in the platform.
   */
  @Get('skills')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get All Available Skills',
    description: 'Returns the full list of welding skills available for welders to select.',
  })
  async getAllSkills() {
    return this.profileService.getAllSkills();
  }

  /**
   * POST /profile/skills
   * Creates a new skill in the system.
   */
  @Post('skills')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a New Skill',
    description: 'Allows adding a new welding skill to the system.',
  })
  async createSkill(@Body('name') name: string) {
    if (!name || name.trim().length === 0) {
      throw new BadRequestException('Skill name is required.');
    }
    return this.profileService.createSkill(name.trim());
  }

  /**
   * PUT /profile/skills/:id
   * Updates an existing skill name.
   */
  @Put('skills/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update an Existing Skill',
    description: 'Allows renaming a welding skill.',
  })
  async updateSkill(@Param('id') id: number, @Body('name') name: string) {
    if (!name || name.trim().length === 0) {
      throw new BadRequestException('Skill name is required.');
    }
    return this.profileService.updateSkill(id, name.trim());
  }

  /**
   * DELETE /profile/skills/:id
   * Deletes a skill from the system.
   */
  @Delete('skills/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete a Skill',
    description: 'Allows deleting a welding skill by ID.',
  })
  async deleteSkill(@Param('id') id: number) {
    await this.profileService.deleteSkill(id);
    return { message: 'Skill deleted successfully.' };
  }
}
