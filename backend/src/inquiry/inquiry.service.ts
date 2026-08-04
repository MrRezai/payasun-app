import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inquiry, InquiryStatus } from '../entities/inquiry.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Offer } from '../entities/offer.entity';
import { AppSetting } from '../entities/app-setting.entity';
import { User } from '../entities/user.entity';
import { EmployerReview } from '../entities/employer-review.entity';
import { SmsService } from '../sms/sms.service';
import { WelderScoringService } from '../scoring/welder-scoring.service';
import { WelderLevelingService } from '../leveling/welder-leveling.service';
import { CreateInquiryDto } from './dto/create-inquiry.dto';
import { EstimateInquiryDto } from './dto/estimate-inquiry.dto';
import { ConfirmInquiryDto } from './dto/confirm-inquiry.dto';
import { SubmitOfferDto } from './dto/submit-offer.dto';

@Injectable()
export class InquiryService {
  private readonly DEFAULT_SMS_SETTINGS = {
    admin_phone_numbers: [],
    sms_tpl_admin_new_inquiry: 'یک استعلام جدید با عنوان "{title}" در شهر {city} ثبت شد و نیازمند بررسی است.',
    sms_tpl_employer_inquiry_approved: 'کارفرمای گرامی، استعلام "{title}" شما بررسی و برآورد شد. جهت تایید و انتشار وارد برنامه شوید.',
    sms_tpl_employer_inquiry_rejected: 'کارفرمای گرامی، استعلام "{title}" شما رد شد. علت رد: {reason}',
  };

  constructor(
    @InjectRepository(Inquiry)
    private readonly inquiryRepository: Repository<Inquiry>,
    @InjectRepository(Offer)
    private readonly offerRepository: Repository<Offer>,
    @InjectRepository(AppSetting)
    private readonly settingRepository: Repository<AppSetting>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(WelderProfile)
    private readonly welderProfileRepository: Repository<WelderProfile>,
    @InjectRepository(EmployerReview)
    private readonly reviewRepository: Repository<EmployerReview>,
    private readonly smsService: SmsService,
    private readonly scoringService: WelderScoringService,
    private readonly levelingService: WelderLevelingService,
  ) {}

  async getSmsSettings(): Promise<any> {
    const setting = await this.settingRepository.findOne({ where: { key: 'sms_notification_settings' } });
    if (!setting) return this.DEFAULT_SMS_SETTINGS;
    try {
      return { ...this.DEFAULT_SMS_SETTINGS, ...JSON.parse(setting.value) };
    } catch {
      return this.DEFAULT_SMS_SETTINGS;
    }
  }

  async updateSmsSettings(data: any): Promise<any> {
    let setting = await this.settingRepository.findOne({ where: { key: 'sms_notification_settings' } });
    const updatedData = { ...this.DEFAULT_SMS_SETTINGS, ...data };
    if (!setting) {
      setting = this.settingRepository.create({ key: 'sms_notification_settings', value: JSON.stringify(updatedData) });
    } else {
      setting.value = JSON.stringify(updatedData);
    }
    await this.settingRepository.save(setting);
    return updatedData;
  }

  private async notifyAdminsNewInquiry(inquiry: Inquiry): Promise<void> {
    try {
      const settings = await this.getSmsSettings();
      const adminPhones: string[] = settings.admin_phone_numbers || [];
      if (!adminPhones || adminPhones.length === 0) return;

      const template: string = settings.sms_tpl_admin_new_inquiry || this.DEFAULT_SMS_SETTINGS.sms_tpl_admin_new_inquiry;
      const message = template
        .replace(/{title}/g, inquiry.title || 'استعلام بدون عنوان')
        .replace(/{city}/g, inquiry.city || 'نامشخص')
        .replace(/{inquiryId}/g, inquiry.id || '');

      for (const phone of adminPhones) {
        if (phone && phone.trim()) {
          await this.smsService.sendSimpleSms(phone.trim(), message).catch((err) => {
            console.error(`Failed to send Admin new inquiry SMS to ${phone}:`, err?.message);
          });
        }
      }
    } catch (error) {
      console.error('Error sending admin notification SMS:', error);
    }
  }

  private async notifyEmployerInquiryApproved(inquiry: Inquiry): Promise<void> {
    try {
      const user = await this.userRepository.findOne({ where: { id: inquiry.employerId } });
      if (!user || !user.phone_number) return;

      const settings = await this.getSmsSettings();
      const template: string = settings.sms_tpl_employer_inquiry_approved || this.DEFAULT_SMS_SETTINGS.sms_tpl_employer_inquiry_approved;
      const message = template
        .replace(/{title}/g, inquiry.title || 'استعلام')
        .replace(/{inquiryId}/g, inquiry.id || '');

      await this.smsService.sendSimpleSms(user.phone_number, message);
    } catch (error) {
      console.error('Error sending employer approval notification SMS:', error);
    }
  }

  private async notifyEmployerInquiryRejected(inquiry: Inquiry, reason: string): Promise<void> {
    try {
      const user = await this.userRepository.findOne({ where: { id: inquiry.employerId } });
      if (!user || !user.phone_number) return;

      const settings = await this.getSmsSettings();
      const template: string = settings.sms_tpl_employer_inquiry_rejected || this.DEFAULT_SMS_SETTINGS.sms_tpl_employer_inquiry_rejected;
      const message = template
        .replace(/{title}/g, inquiry.title || 'استعلام')
        .replace(/{reason}/g, reason || 'توسط مدیر سیستم رد گردید.')
        .replace(/{inquiryId}/g, inquiry.id || '');

      await this.smsService.sendSimpleSms(user.phone_number, message);
    } catch (error) {
      console.error('Error sending employer rejection notification SMS:', error);
    }
  }

  /**
   * Creates a new inquiry.
   * If manual items are provided and has_blueprint is false, it starts as BROADCASTED or DRAFT.
   * If has_blueprint is true, it starts as DRAFT until the blueprint file is uploaded.
   */
  async create(employerId: string, dto: CreateInquiryDto): Promise<Inquiry> {
    const hasBlueprint = dto.has_blueprint ?? false;
    let initialStatus = InquiryStatus.DRAFT;

    // If manual items are provided immediately without blueprint, set status to PENDING_ESTIMATION (waiting for admin review)
    if (!hasBlueprint && dto.items && dto.items.length > 0) {
      initialStatus = InquiryStatus.PENDING_ESTIMATION;
    } else if (hasBlueprint) {
      initialStatus = InquiryStatus.DRAFT; // Awaiting blueprint upload
    }

    const inquiry = this.inquiryRepository.create({
      employerId,
      projectId: dto.projectId ?? null,
      title: dto.title,
      description: dto.description,
      city: dto.city,
      province: dto.province ?? null,
      address: dto.address ?? null,
      status: initialStatus,
      has_blueprint: hasBlueprint,
      estimation_type: dto.estimation_type ?? (hasBlueprint ? 'ROUGH' : null),
      items: dto.items ?? [],
      blueprint_url: null,
    });

    const savedInquiry = await this.inquiryRepository.save(inquiry);

    if (savedInquiry.status === InquiryStatus.PENDING_ESTIMATION) {
      this.notifyAdminsNewInquiry(savedInquiry);
    }

    return savedInquiry;
  }

  /**
   * Links a uploaded blueprint file URL to the inquiry, moving it to PENDING_ESTIMATION status.
   */
  async uploadBlueprint(inquiryId: string, employerId: string, fileUrl: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });

    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }

    if (inquiry.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی ویرایش این استعلام را ندارید.');
    }

    inquiry.has_blueprint = true;
    if (inquiry.blueprint_url && inquiry.blueprint_url.trim().length > 0) {
      inquiry.blueprint_url = `${inquiry.blueprint_url},${fileUrl}`;
    } else {
      inquiry.blueprint_url = fileUrl;
    }
    inquiry.status = InquiryStatus.PENDING_ESTIMATION;

    const savedInquiry = await this.inquiryRepository.save(inquiry);
    this.notifyAdminsNewInquiry(savedInquiry);
    return savedInquiry;
  }

  /**
   * Admin-side estimation fulfillment. Fills the items array and changes status to ESTIMATED.
   */
  async estimate(inquiryId: string, dto: EstimateInquiryDto): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });

    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }

    if (inquiry.status !== InquiryStatus.PENDING_ESTIMATION) {
      throw new BadRequestException('این استعلام در وضعیت انتظار برای برآورد قرار ندارد.');
    }

    inquiry.items = dto.items;
    inquiry.status = InquiryStatus.ESTIMATED;

    const savedInquiry = await this.inquiryRepository.save(inquiry);
    this.notifyEmployerInquiryApproved(savedInquiry);
    return savedInquiry;
  }

  /**
   * Employer-side confirmation and final adjustments to broadcast the inquiry.
   */
  async confirm(inquiryId: string, employerId: string, dto: ConfirmInquiryDto): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });

    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }

    if (inquiry.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی تأیید این استعلام را ندارید.');
    }

    if (inquiry.status !== InquiryStatus.ESTIMATED && inquiry.status !== InquiryStatus.DRAFT) {
      throw new BadRequestException('فقط استعلام‌های تایید شده یا پیش‌نویس قابل تأیید و انتشار هستند.');
    }

    if (dto.items && dto.items.length > 0) {
      inquiry.items = dto.items;
    }

    if (inquiry.items.length === 0) {
      throw new BadRequestException('لیست اقلام استعلام نمی‌تواند خالی باشد.');
    }

    inquiry.status = InquiryStatus.BROADCASTED;

    return this.inquiryRepository.save(inquiry);
  }

  /**
   * Retrieves all inquiries (useful for Admin and Welders) mapping real Employer names.
   */
  async findAll(): Promise<any[]> {
    const inquiries = await this.inquiryRepository.find({
      relations: ['project'],
      order: { created_at: 'DESC' },
    });
    
    // Fetch all employer profiles to map names
    const profiles = await this.inquiryRepository.manager.getRepository(EmployerProfile).find();
    
    // Fetch all offers
    const offers = await this.offerRepository.find({
      relations: ['welder']
    });

    // Map profiles by user_id
    const profileMap = new Map<string, EmployerProfile>();
    profiles.forEach(p => {
      profileMap.set(p.user_id, p);
    });

    // Map offers by inquiry_id
    const offerMap = new Map<string, any[]>();
    offers.forEach(o => {
      const list = offerMap.get(o.inquiry_id) || [];
      list.push({
        id: o.id,
        welder_id: o.welder_id,
        welder_user_id: o.welder?.user_id,
        welder_name: o.welder ? `${o.welder.first_name || ''} ${o.welder.last_name || ''}`.trim() || 'جوشکار پلتفرم' : 'جوشکار پلتفرم',
        profile_picture_url: o.welder?.profile_picture_url || null,
        total_price: o.total_price,
        items_prices: o.items_prices,
        scaffold_checked: o.scaffold_checked,
        power_checked: o.power_checked,
        rod_checked: o.rod_checked,
        delivery_checked: o.delivery_checked,
        created_at: o.created_at,
        is_hidden: o.is_hidden,
      });

      offerMap.set(o.inquiry_id, list);
    });
    
    // Map inquiries to include employer name and offers
    return inquiries.map((inq: any) => {
      const profile = profileMap.get(inq.employerId);
      let employer_name = 'کارفرمای پلتفرم';
      if (profile) {
        const fullName = [profile.first_name, profile.last_name].filter(Boolean).join(' ');
        if (fullName) {
          employer_name = fullName;
        } else if (profile.company_name) {
          employer_name = profile.company_name;
        }
      }
      return {
        ...inq,
        employer_name,
        offers: offerMap.get(inq.id) || []
      };
    });
  }

  /**
   * Rejects an inquiry with a reason.
   */
  async reject(inquiryId: string, reason: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });

    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }
    if (inquiry.status === InquiryStatus.DRAFT) {
      throw new BadRequestException('پیش‌نویس‌ها قابل رد شدن نیستند.');
    }
    inquiry.status = InquiryStatus.REJECTED;
    inquiry.rejection_reason = reason;
    const savedInquiry = await this.inquiryRepository.save(inquiry);
    this.notifyEmployerInquiryRejected(savedInquiry, reason);
    return savedInquiry;
  }

  /**
   * Update inquiry (Employer editing their rejected/draft inquiry).
   */
  async update(inquiryId: string, employerId: string, dto: CreateInquiryDto): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });

    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }

    if (inquiry.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی ویرایش این استعلام را ندارید.');
    }

    // Only allow editing if status is DRAFT, REJECTED or PENDING_ESTIMATION
    if (inquiry.status !== InquiryStatus.DRAFT && inquiry.status !== InquiryStatus.REJECTED && inquiry.status !== InquiryStatus.PENDING_ESTIMATION) {
      throw new BadRequestException('این استعلام در این وضعیت قابل ویرایش نیست.');
    }

    inquiry.title = dto.title;
    inquiry.description = dto.description;
    inquiry.city = dto.city;
    inquiry.province = dto.province ?? null;
    
    // Clear old blueprint_url on update so new/retained file selection replaces it
    if (inquiry.has_blueprint || dto.has_blueprint) {
      inquiry.has_blueprint = true;
      inquiry.blueprint_url = null;
    }

    // If it was rejected, move it back to PENDING_ESTIMATION so it gets reviewed again!
    if (inquiry.status === InquiryStatus.REJECTED || inquiry.has_blueprint) {
      inquiry.status = InquiryStatus.PENDING_ESTIMATION;
      inquiry.rejection_reason = null;
    }

    if (dto.items && dto.items.length > 0) {
      inquiry.items = dto.items;
    }

    const savedInquiry = await this.inquiryRepository.save(inquiry);
    if (savedInquiry.status === InquiryStatus.PENDING_ESTIMATION) {
      this.notifyAdminsNewInquiry(savedInquiry);
    }
    return savedInquiry;
  }

  /**
   * Retrieves all inquiries owned by a specific Employer.
   */
  async findByEmployer(employerId: string): Promise<any[]> {
    const inquiries = await this.inquiryRepository.find({
      where: { employerId },
      order: { created_at: 'DESC' },
    });
    // Fetch all offers (exclude hidden ones for employers)
    const offers = await this.offerRepository.find({
      where: { is_hidden: false },
      relations: ['welder']
    });
    // Map offers by inquiry_id
    const offerMap = new Map<string, any[]>();
    offers.forEach(o => {
      const list = offerMap.get(o.inquiry_id) || [];
      list.push({
        id: o.id,
        welder_id: o.welder_id,
        welder_user_id: o.welder?.user_id,
        profile_picture_url: o.welder?.profile_picture_url || null,
        total_price: o.total_price,
        items_prices: o.items_prices,
        scaffold_checked: o.scaffold_checked,
        power_checked: o.power_checked,
        rod_checked: o.rod_checked,
        delivery_checked: o.delivery_checked,
        created_at: o.created_at
      });
      offerMap.set(o.inquiry_id, list);
    });

    return inquiries.map((inq: any) => {
      return {
        ...inq,
        offers: offerMap.get(inq.id) || []
      };
    });
  }

  /**
   * Retrieves a single inquiry by ID.
   */
  async findOne(id: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id } });
    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }
    return inquiry;
  }

  async submitOffer(inquiryId: string, userId: string, dto: SubmitOfferDto): Promise<Offer> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }
    if (inquiry.status !== InquiryStatus.BROADCASTED) {
      throw new BadRequestException('ثبت پیشنهاد قیمت فقط روی پروژه‌های منتشر شده مجاز است.');
    }

    const welder = await this.inquiryRepository.manager.getRepository(WelderProfile).findOne({
      where: { user_id: userId }
    });
    if (!welder) {
      throw new ForbiddenException('فقط کاربران با نقش جوشکار می‌توانند پیشنهاد ثبت کنند.');
    }

    // Check if the welder has already submitted an offer for this inquiry
    const existingOffer = await this.offerRepository.findOne({
      where: { inquiry_id: inquiryId, welder_id: welder.id }
    });
    if (existingOffer) {
      existingOffer.items_prices = dto.items_prices;
      existingOffer.total_price = dto.total_price;
      existingOffer.scaffold_checked = dto.scaffold_checked;
      existingOffer.power_checked = dto.power_checked;
      existingOffer.rod_checked = dto.rod_checked;
      existingOffer.delivery_checked = dto.delivery_checked;
      return this.offerRepository.save(existingOffer);
    }

    const offer = this.offerRepository.create({
      inquiry_id: inquiryId,
      welder_id: welder.id,
      items_prices: dto.items_prices,
      total_price: dto.total_price,
      scaffold_checked: dto.scaffold_checked,
      power_checked: dto.power_checked,
      rod_checked: dto.rod_checked,
      delivery_checked: dto.delivery_checked,
    });

    return this.offerRepository.save(offer);
  }
  async getOffers(inquiryId: string): Promise<any[]> {
    const offers = await this.offerRepository.find({
      where: { inquiry_id: inquiryId, is_hidden: false },
      relations: ['welder', 'welder.user'],
      order: { created_at: 'DESC' }
    });

    return offers.map(o => {
      const w = o.welder;
      const firstName = w?.first_name ?? '';
      const lastName = w?.last_name ?? '';
      const fullName = [firstName, lastName].filter(Boolean).join(' ') || 'جوشکار مهمان';
      
      const initials = this.getInitials(firstName, lastName);
      const timeStr = this.getRelativeFarsiTime(o.created_at);

      return {
        id: o.id,
        name: fullName,
        rating: Number(w?.total_score ?? 0),
        projects: Number(w?.completed_jobs_count ?? 0),
        price: `${o.total_price.toString()}`,
        phone: w?.user?.phone_number ?? 'نامشخص',
        initials: initials,
        time: timeStr,
        items_prices: o.items_prices,
        scaffold_checked: o.scaffold_checked,
        power_checked: o.power_checked,
        rod_checked: o.rod_checked,
        delivery_checked: o.delivery_checked,
        profile_picture_url: w?.profile_picture_url || null,
        profile_picture_status: w?.profile_picture_status || 'NONE',
        bio: w?.bio || '',
        home_city: w?.home_city || '',
        home_province: w?.home_province || '',
        active_cities: w?.active_cities || [],
        skills: w?.skills?.map((s: any) => s.name) || [],
      };
    });
  }

  private getInitials(firstName: string | null, lastName: string | null): string {
    const f = firstName?.trim() ? firstName.trim()[0] : '';
    const l = lastName?.trim() ? lastName.trim()[0] : '';
    if (f && l) return `${f}‌${l}`;
    if (f) return f;
    if (l) return l;
    return 'ج';
  }

  private getRelativeFarsiTime(date: Date): string {
    const diffMs = Date.now() - new Date(date).getTime();
    const diffMins = Math.floor(diffMs / (60 * 1000));
    if (diffMins < 1) return 'هم‌اکنون';
    if (diffMins < 60) return `${diffMins} دقیقه پیش`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours} ساعت پیش`;
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays} روز پیش`;
  }

  async findOffersByWelder(welderId: string): Promise<Offer[]> {
    if (!welderId) return [];
    return this.offerRepository.find({
      where: { welder_id: welderId },
      relations: ['inquiry'],
      order: { created_at: 'DESC' },
    });
  }

  async deleteInquiry(id: string): Promise<void> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id } });
    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }
    await this.inquiryRepository.remove(inquiry);
  }

  async toggleOfferVisibility(offerId: string, isHidden: boolean): Promise<Offer> {
    const offer = await this.offerRepository.findOne({ where: { id: offerId } });
    if (!offer) {
      throw new NotFoundException('پیشنهاد مورد نظر یافت نشد.');
    }
    offer.is_hidden = isHidden;
    return this.offerRepository.save(offer);
  }

  async deleteInquiriesAndOffersByUser(userId: string): Promise<void> {
    // Delete welder offers
    const welderProfile = await this.inquiryRepository.manager.getRepository(WelderProfile).findOne({
      where: { user_id: userId }
    });
    if (welderProfile) {
      await this.offerRepository.delete({ welder_id: welderProfile.id });
    }

    // Delete employer inquiries
    const inquiries = await this.inquiryRepository.find({ where: { employerId: userId } });
    if (inquiries.length > 0) {
      await this.inquiryRepository.remove(inquiries);
    }
  }

  /**
   * 2-Step Agreement Step 1 (Employer initiates agreement):
   * Employer selects winning welder -> Status = AGREEMENT_PENDING_WELDER
   * Calculates deposit = area_sqm * 1000 Tomans.
   * Sends Simple SMS to Welder.
   */
  async startAgreement(inquiryId: string, employerId: string, welderId: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    if (inquiry.employerId !== employerId) throw new ForbiddenException('عدم دسترسی.');

    const welder = await this.welderProfileRepository.findOne({
      where: { id: welderId },
      relations: ['user'],
    });
    if (!welder) throw new NotFoundException('جوشکار مورد نظر یافت نشد.');

    // Single active job constraint check
    if (welder.active_jobs_count >= 1) {
      throw new BadRequestException('این جوشکار در حال حاضر یک پروژه فعال در دست اجرا دارد.');
    }

    inquiry.status = InquiryStatus.AGREEMENT_PENDING_WELDER;
    inquiry.deposit_amount = Number(inquiry.area_sqm || 0) * 1000;
    const savedInquiry = await this.inquiryRepository.save(inquiry);

    // Send Simple SMS to Welder
    if (welder.user && welder.user.phone_number) {
      const message = `کارفرما توافق برای شروع پروژه "${inquiry.title}" را ثبت نمود. جهت تایید وارد برنامه شوید.`;
      this.smsService.sendSimpleSms(welder.user.phone_number, message).catch(() => {});
    }

    return savedInquiry;
  }

  /**
   * 2-Step Agreement Step 2 (Welder accepts agreement):
   * Welder confirms in panel -> Status = IN_PROGRESS, welder.active_jobs_count += 1
   */
  async confirmAgreementByWelder(inquiryId: string, userId: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) throw new NotFoundException('استعلام مورد نظر یافت نشد.');

    const welder = await this.welderProfileRepository.findOne({ where: { user_id: userId } });
    if (!welder) throw new ForbiddenException('فقط جوشکار مجاز است.');

    if (inquiry.status !== InquiryStatus.AGREEMENT_PENDING_WELDER) {
      throw new BadRequestException('این استعلام در وضعیت انتظار برای تایید جوشکار قرار ندارد.');
    }

    inquiry.status = InquiryStatus.IN_PROGRESS;
    welder.active_jobs_count = (welder.active_jobs_count || 0) + 1;
    await this.welderProfileRepository.save(welder);

    return this.inquiryRepository.save(inquiry);
  }

  /**
   * 2-Step Completion Step 1 (Welder finishes job):
   * Welder marks job finished -> Status = COMPLETED_PENDING_EMPLOYER
   * Sends Simple SMS to Employer.
   */
  async finishJobByWelder(inquiryId: string, userId: string): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) throw new NotFoundException('استعلام مورد نظر یافت نشد.');

    const welder = await this.welderProfileRepository.findOne({ where: { user_id: userId } });
    if (!welder) throw new ForbiddenException('فقط جوشکار مجاز است.');

    if (inquiry.status !== InquiryStatus.IN_PROGRESS) {
      throw new BadRequestException('فقط پروژه‌های در حال اجرا قابل اعلام اتمام هستند.');
    }

    inquiry.status = InquiryStatus.COMPLETED_PENDING_EMPLOYER;
    const savedInquiry = await this.inquiryRepository.save(inquiry);

    // Send Simple SMS to Employer
    const employerUser = await this.userRepository.findOne({ where: { id: inquiry.employerId } });
    if (employerUser && employerUser.phone_number) {
      const message = `جوشکار پایان کار پروژه "${inquiry.title}" را اعلام کرد. جهت تایید نهایی و ثبت امتیاز وارد برنامه شوید.`;
      this.smsService.sendSimpleSms(employerUser.phone_number, message).catch(() => {});
    }

    return savedInquiry;
  }

  /**
   * 2-Step Completion Step 2 (Employer confirms & rates):
   * Employer submits Quality, Punctuality, Behavior scores -> Status = COMPLETED
   * Welder active_jobs_count -= 1. Recalculates scores & tier promotions.
   */
  async confirmCompletionByEmployer(
    inquiryId: string,
    employerId: string,
    welderId: string,
    qualityScore: number,
    punctualityScore: number,
    behaviorScore: number,
    comment?: string,
  ): Promise<Inquiry> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    if (inquiry.employerId !== employerId) throw new ForbiddenException('عدم دسترسی.');

    const welder = await this.welderProfileRepository.findOne({ where: { id: welderId } });
    if (!welder) throw new NotFoundException('جوشکار مورد نظر یافت نشد.');

    // Calculate rating using formula (0.4*Q + 0.35*P + 0.25*B)
    const rating = this.scoringService.calculateEmployerRating(qualityScore, punctualityScore, behaviorScore);

    // Save EmployerReview
    const review = this.reviewRepository.create({
      inquiry_id: inquiryId,
      welder_id: welderId,
      employer_id: employerId,
      quality_score: qualityScore,
      punctuality_score: punctualityScore,
      behavior_score: behaviorScore,
      calculated_rating: rating,
      comment: comment || null,
    });
    await this.reviewRepository.save(review);

    // Update Inquiry status & Welder active jobs
    inquiry.status = InquiryStatus.COMPLETED;
    welder.active_jobs_count = Math.max(0, (welder.active_jobs_count || 1) - 1);
    welder.completed_jobs_count = (welder.completed_jobs_count || 0) + 1;
    await this.welderProfileRepository.save(welder);
    const savedInquiry = await this.inquiryRepository.save(inquiry);

    // Recalculate welder score & check tier promotion
    await this.scoringService.recalculateWelderScore(welderId);
    await this.levelingService.checkAndUpdateWelderPromotion(welderId, inquiry.tier, rating);

    return savedInquiry;
  }
}
