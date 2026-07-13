import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { InquiryService } from './inquiry.service';
import { CreateInquiryDto } from './dto/create-inquiry.dto';
import { EstimateInquiryDto } from './dto/estimate-inquiry.dto';
import { ConfirmInquiryDto } from './dto/confirm-inquiry.dto';
import { SubmitOfferDto } from './dto/submit-offer.dto';
import { Inquiry } from '../entities/inquiry.entity';

// Ensure uploads directory exists
const UPLOAD_DIR = './uploads/blueprints';
if (!existsSync(UPLOAD_DIR)) {
  mkdirSync(UPLOAD_DIR, { recursive: true });
}

@ApiTags('Inquiry')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard)
@Controller('inquiry')
export class InquiryController {
  constructor(private readonly inquiryService: InquiryService) {}

  /**
   * POST /inquiry
   * Create a new inquiry (Employer only)
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'ایجاد استعلام جدید',
    description: 'یک استعلام جدید توسط کارفرما ایجاد می‌کند. می‌تواند شامل اقلام دستی یا پرچم نیاز به پلان باشد.',
  })
  @ApiBody({ type: CreateInquiryDto })
  @ApiResponse({ status: 201, description: 'استعلام با موفقیت ایجاد شد.', type: Inquiry })
  @ApiResponse({ status: 401, description: 'کاربر احراز هویت نشده است.' })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateInquiryDto,
  ): Promise<Inquiry> {
    return this.inquiryService.create(user.id, dto);
  }

  /**
   * PATCH /inquiry/:id
   * Update and resubmit inquiry (Employer only)
   */
  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'ویرایش و ارسال مجدد استعلام',
    description: 'استعلام را ویرایش کرده و در صورت رد شدن، مجدداً برای بررسی ادمین ارسال می‌کند.',
  })
  async update(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateInquiryDto,
  ): Promise<Inquiry> {
    return this.inquiryService.update(id, user.id, dto);
  }

  /**
   * POST /inquiry/:id/blueprint
   * Upload blueprint file (Employer only)
   */
  @Post(':id/blueprint')
  @HttpCode(HttpStatus.OK)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: UPLOAD_DIR,
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          callback(null, `blueprint-${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (req, file, callback) => {
        const allowedExtensions = ['.pdf', '.png', '.jpg', '.jpeg', '.dwg'];
        const ext = extname(file.originalname).toLowerCase();
        if (!allowedExtensions.includes(ext)) {
          return callback(new BadRequestException('فرمت فایل نامعتبر است. فقط فایلهای PDF، تصاویر و DWG مجاز هستند.'), false);
        }
        callback(null, true);
      },
      limits: {
        fileSize: 15 * 1024 * 1024, // 15MB limit
      },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'آپلود فایل نقشه/پلان ساختمان برای استعلام',
    description: 'یک فایل نقشه (تصویر، PDF یا DWG) را آپلود کرده و به استعلام پیوند می‌دهد.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'نقشه با موفقیت آپلود و ذخیره شد.', type: Inquiry })
  @ApiResponse({ status: 400, description: 'فایل نامعتبر یا بسیار بزرگ است.' })
  async uploadBlueprint(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<Inquiry> {
    if (!file) {
      throw new BadRequestException('فایلی ارسال نشده است.');
    }
    // Return relative URL to download/view the file
    const fileUrl = `/uploads/blueprints/${file.filename}`;
    return this.inquiryService.uploadBlueprint(id, user.id, fileUrl);
  }

  /**
   * PATCH /inquiry/:id/estimate
   * Admin/Welder fills the estimation items
   */
  @Patch(':id/estimate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'ثبت برآورد اقلام استعلام (مخصوص ادمین / کارشناس)',
    description: 'اقلام برآورد شده از روی نقشه را ثبت کرده و وضعیت استعلام را به ESTIMATED تغییر می‌دهد.',
  })
  @ApiBody({ type: EstimateInquiryDto })
  @ApiResponse({ status: 200, description: 'برآورد با موفقیت ثبت شد.', type: Inquiry })
  @ApiResponse({ status: 400, description: 'استعلام در وضعیت انتظار برای برآورد قرار ندارد.' })
  async estimate(
    @Param('id') id: string,
    @Body() dto: EstimateInquiryDto,
  ): Promise<Inquiry> {
    return this.inquiryService.estimate(id, dto);
  }

  /**
   * PATCH /inquiry/:id/confirm
   * Employer confirms / finalizes estimated items to broadcast
   */
  @Patch(':id/confirm')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'تأیید نهایی و انتشار استعلام توسط کارفرما',
    description: 'اقلام برآورد شده را تأیید یا ویرایش نهایی کرده و وضعیت استعلام را به BROADCASTED تغییر می‌دهد.',
  })
  @ApiBody({ type: ConfirmInquiryDto })
  @ApiResponse({ status: 200, description: 'استعلام با موفقیت تأیید و در سیستم منتشر شد.', type: Inquiry })
  async confirm(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ConfirmInquiryDto,
  ): Promise<Inquiry> {
    return this.inquiryService.confirm(id, user.id, dto);
  }

  /**
   * GET /inquiry/my
   * Get inquiries of the authenticated Employer
   */
  @Get('my')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'مشاهده استعلام‌های من',
    description: 'لیست تمام استعلام‌های ثبت شده توسط کارفرمای لاگین شده را باز می‌گرداند.',
  })
  @ApiResponse({ status: 200, description: 'لیست استعلام‌ها.', type: [Inquiry] })
  async getMyInquiries(@CurrentUser() user: AuthenticatedUser): Promise<Inquiry[]> {
    return this.inquiryService.findByEmployer(user.id);
  }

  /**
   * GET /inquiry
   * Get all inquiries (accessible to welders to view jobs)
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'مشاهده همه استعلام‌ها',
    description: 'لیست کل استعلام‌های موجود در سیستم را باز می‌گرداند (مخصوص جوشکاران جهت بررسی پروژه‌ها).',
  })
  @ApiResponse({ status: 200, description: 'لیست کل استعلام‌ها.', type: [Inquiry] })
  async getAllInquiries(): Promise<Inquiry[]> {
    return this.inquiryService.findAll();
  }

  /**
   * GET /inquiry/:id
   * Get single inquiry details
   */
  @Get(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'مشاهده جزئیات یک استعلام',
    description: 'جزئیات کامل یک استعلام را با شناسه آن باز می‌گرداند.',
  })
  @ApiResponse({ status: 200, description: 'اطلاعات استعلام.', type: Inquiry })
  @ApiResponse({ status: 404, description: 'استعلام یافت نشد.' })
  async getOneInquiry(@Param('id') id: string): Promise<Inquiry> {
    return this.inquiryService.findOne(id);
  }

  /**
   * POST /inquiry/:id/offer
   * Submit an offer on inquiry (Welder only)
   */
  @Post(':id/offer')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'ثبت پیشنهاد قیمت توسط جوشکار روی استعلام',
    description: 'پیشنهاد قیمت جوشکار برای تک‌تک اقلام به همراه چک‌باکس تعهدات را ذخیره می‌کند.',
  })
  @ApiBody({ type: SubmitOfferDto })
  async submitOffer(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SubmitOfferDto,
  ): Promise<any> {
    return this.inquiryService.submitOffer(id, user.id, dto);
  }

  /**
   * GET /inquiry/:id/offers
   * Get all offers submitted for an inquiry (Employer/Owner only)
   */
  @Get(':id/offers')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'دریافت پیشنهادهای قیمت ثبت شده برای یک استعلام',
    description: 'لیست تمام پیشنهادهای قیمت جوشکاران را باز می‌گرداند (برای کارفرمای مالک پروژه).',
  })
  async getOffers(@Param('id') id: string): Promise<any[]> {
    return this.inquiryService.getOffers(id);
  }
}
