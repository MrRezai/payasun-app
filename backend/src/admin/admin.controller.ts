import { Controller, Get, Patch, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { AdminGuard } from './guards/admin.guard';
import { ProfileService } from '../profile/profile.service';
import { InquiryService } from '../inquiry/inquiry.service';

@Controller('admin')
@UseGuards(AdminGuard)
export class AdminController {
  constructor(
    private readonly profileService: ProfileService,
    private readonly inquiryService: InquiryService,
  ) {}

  @Get('welders-count')
  async getWeldersCount() {
    const count = await this.profileService.getWeldersCount();
    return { count };
  }

  @Get('employers-count')
  async getEmployersCount() {
    const count = await this.profileService.getEmployersCount();
    return { count };
  }

  @Get('pending-verifications')
  async getPendingVerifications() {
    return this.profileService.getPendingVerifications();
  }

  @Patch('verify-picture/:userId')
  async verifyPicture(
    @Param('userId') userId: string,
    @Body('role') role: string,
    @Body('approve') approve: boolean,
  ) {
    await this.profileService.verifyPicture(userId, role, approve);
    return { message: 'وضعیت تصویر پروفایل با موفقیت تغییر کرد.' };
  }

  @Get('inquiries')
  async getInquiries() {
    return this.inquiryService.findAll();
  }

  @Patch('inquiry/:id/estimate')
  async estimateInquiry(@Param('id') id: string, @Body('items') items: any[]) {
    return this.inquiryService.estimate(id, { items });
  }

  @Patch('inquiry/:id/reject')
  async rejectInquiry(@Param('id') id: string, @Body('reason') reason: string) {
    return this.inquiryService.reject(id, reason);
  }

  @Get('skills')
  async getSkills() {
    return this.profileService.getAllSkills();
  }

  @Post('skills')
  async createSkill(@Body('name') name: string) {
    return this.profileService.createSkill(name);
  }

  @Put('skills/:id')
  async updateSkill(@Param('id') id: number, @Body('name') name: string) {
    return this.profileService.updateSkill(id, name);
  }

  @Delete('skills/:id')
  async deleteSkill(@Param('id') id: number) {
    await this.profileService.deleteSkill(id);
    return { message: 'تخصص با موفقیت حذف شد.' };
  }

  @Get('users')
  async getUsers() {
    return this.profileService.getUsersList();
  }

  @Get('users/:id')
  async getUserHistory(@Param('id') id: string) {
    const profileData = await this.profileService.getUserProfiles(id);
    const inquiries = await this.inquiryService.findByEmployer(id);
    const offers = profileData.welder
      ? await this.inquiryService.findOffersByWelder(profileData.welder.id)
      : [];

    return {
      user: profileData.user,
      welderProfile: profileData.welder,
      employerProfile: profileData.employer,
      inquiries,
      offers,
    };
  }

  @Delete('inquiry/:id')
  async deleteInquiry(@Param('id') id: string) {
    await this.inquiryService.deleteInquiry(id);
    return { message: 'پروژه با موفقیت حذف شد.' };
  }

  @Patch('offer/:id/toggle-visibility')
  async toggleOfferVisibility(
    @Param('id') id: string,
    @Body('isHidden') isHidden: boolean,
  ) {
    return this.inquiryService.toggleOfferVisibility(id, isHidden);
  }

  @Patch('users/:id/toggle-block')
  async toggleBlockUser(
    @Param('id') id: string,
    @Body('isBlocked') isBlocked: boolean,
  ) {
    return this.profileService.toggleBlockUser(id, isBlocked);
  }

  @Delete('users/:id')
  async deleteUser(@Param('id') id: string) {
    // 1. Clean up user's inquiries and offers
    await this.inquiryService.deleteInquiriesAndOffersByUser(id);
    // 2. Delete user and their cascade profiles
    await this.profileService.deleteUser(id);
    return { message: 'کاربر با موفقیت به همراه تمامی اطلاعات مرتبط حذف شد.' };
  }
}

