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
import { InquiryDispatchService } from '../dispatch/inquiry-dispatch.service';
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
  constructor(
    private readonly inquiryService: InquiryService,
    private readonly dispatchService: InquiryDispatchService,
  ) {}

  /**
   * POST /inquiry/:id/start-agreement
   * Employer initiates agreement with winning welder (Step 1 of Agreement)
   */
  @Post(':id/start-agreement')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'ثبت اولیه توافق و انتخاب جوشکار توسط کارفرما' })
  async startAgreement(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body('welderId') welderId: string,
  ): Promise<Inquiry> {
    if (!welderId) throw new BadRequestException('شناسه جوشکار الزامی است.');
    return this.inquiryService.startAgreement(id, user.id, welderId);
  }

  /**
   * POST /inquiry/:id/confirm-agreement
   * Welder accepts agreement (Step 2 of Agreement -> IN_PROGRESS)
   */
  @Post(':id/confirm-agreement')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'تایید نهایی توافق شروع کار توسط جوشکار' })
  async confirmAgreementByWelder(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<Inquiry> {
    return this.inquiryService.confirmAgreementByWelder(id, user.id);
  }

  /**
   * POST /inquiry/:id/finish-job
   * Welder marks project finished (Step 1 of Completion)
   */
  @Post(':id/finish-job')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'اعلام اتمام پروژه توسط جوشکار' })
  async finishJobByWelder(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<Inquiry> {
    return this.inquiryService.finishJobByWelder(id, user.id);
  }

  /**
   * POST /inquiry/:id/confirm-completion
   * Employer confirms completion & submits 3-part rating (Step 2 of Completion)
   */
  @Post(':id/confirm-completion')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'تایید اتمام کار و ثبت امتیاز ۳ گانه توسط کارفرما' })
  async confirmCompletionByEmployer(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { welderId: string; qualityScore: number; punctualityScore: number; behaviorScore: number; comment?: string },
  ): Promise<Inquiry> {
    if (
      !body.welderId ||
      typeof body.qualityScore !== 'number' ||
      typeof body.punctualityScore !== 'number' ||
      typeof body.behaviorScore !== 'number'
    ) {
      throw new BadRequestException('امتیازهای کیفیت، خوش‌قولی و رفتار حرفه‌ای الزامی هستند.');
    }

    if (
      body.qualityScore < 1 || body.qualityScore > 5 ||
      body.punctualityScore < 1 || body.punctualityScore > 5 ||
      body.behaviorScore < 1 || body.behaviorScore > 5
    ) {
      throw new BadRequestException('امتیازها باید عددی بین ۱ تا ۵ باشند.');
    }
    return this.inquiryService.confirmCompletionByEmployer(
      id,
      user.id,
      body.welderId,
      body.qualityScore,
      body.punctualityScore,
      body.behaviorScore,
      body.comment,
    );
  }

  /**
   * POST /inquiry/:id/re-dispatch
   * Employer pays fee to re-dispatch 5 new candidate welders after 72h expiration
   */
  @Post(':id/re-dispatch')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'ارسال مجدد استعلام به ۵ جوشکار جدید پس از ۷۲ ساعت انقضا' })
  async reDispatch(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<any> {
    return this.dispatchService.reDispatchInquiry(id, user.id);
  }

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
   * POST /inquiry/:id/link-blueprint
   * Link an existing file URL to the inquiry
   */
  @Post(':id/link-blueprint')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'لینک کردن یک فایل موجود به استعلام در هنگام ویرایش' })
  async linkExistingBlueprint(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body('fileUrl') fileUrl: string,
  ): Promise<Inquiry> {
    if (!fileUrl) {
      throw new BadRequestException('آدرس فایل الزامی است.');
    }
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
    description: 'اقلام تایید شده از روی نقشه را ثبت کرده و وضعیت استعلام را به ESTIMATED تغییر می‌دهد.',
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
    description: 'اقلام تایید شده را تأیید یا ویرایش نهایی کرده و وضعیت استعلام را به BROADCASTED تغییر می‌دهد.',
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
