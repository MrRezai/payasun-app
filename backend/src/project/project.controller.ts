import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags, ApiConsumes } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { existsSync, mkdirSync } from 'fs';

import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ProjectService, CreateProjectDto, UpdateProjectDto } from './project.service';
import { Project } from '../entities/project.entity';

const UPLOAD_DIR = './uploads/projects';
if (!existsSync(UPLOAD_DIR)) {
  mkdirSync(UPLOAD_DIR, { recursive: true });
}

@ApiTags('Project')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard)
@Controller('project')
export class ProjectController {
  constructor(private readonly projectService: ProjectService) {}

  /**
   * POST /project
   * Create a new project (Employer only)
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'ایجاد پروژه جدید بدون نیاز به تایید مدیریت' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateProjectDto,
  ): Promise<Project> {
    return this.projectService.create(user.id, dto);
  }

  /**
   * PATCH /project/:id
   * Update an existing project
   */
  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'ویرایش مشخصات پروژه' })
  async update(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProjectDto,
  ): Promise<Project> {
    return this.projectService.update(id, user.id, dto);
  }

  /**
   * DELETE /project/:id
   * Delete a project and all its inquiries
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'حذف کامل پروژه و استعلام‌های مربوطه' })
  async remove(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ message: string }> {
    await this.projectService.remove(id, user.id);
    return { message: 'پروژه با موفقیت حذف شد.' };
  }

  /**
   * POST /project/:id/images
   * Upload image for project (up to 10 max)
   */
  @Post(':id/images')
  @HttpCode(HttpStatus.OK)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: UPLOAD_DIR,
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          callback(null, `project-${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, callback) => {
        const allowedExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
        const ext = extname(file.originalname).toLowerCase();
        if (!allowedExtensions.includes(ext)) {
          return callback(
            new BadRequestException('فرمت تصویر نامعتبر است. فقط PNG، JPG و WEBP مجاز هستند.'),
            false,
          );
        }
        callback(null, true);
      },
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
      },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'آپلود تصویر برای پروژه (حداکثر ۱۰ تصویر)' })
  async uploadImage(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Project> {
    if (!file) {
      throw new BadRequestException('تصویری ارسال نشده است.');
    }
    const fileUrl = `/uploads/projects/${file.filename}`;
    return this.projectService.addImage(id, user.id, fileUrl);
  }

  /**
   * GET /project/my
   * Get all projects of the logged-in Employer
   */
  @Get('my')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'دریافت پروژه‌های کارفرما به همراه استعلام‌های متصل به آن‌ها' })
  async getMyProjects(@CurrentUser() user: AuthenticatedUser): Promise<Project[]> {
    return this.projectService.findByEmployer(user.id);
  }

  /**
   * GET /project/:id
   * Get project details
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'دریافت اطلاعات یک پروژه' })
  async getOneProject(@Param('id') id: string): Promise<Project> {
    return this.projectService.findOne(id);
  }
}
