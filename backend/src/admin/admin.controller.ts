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
}
