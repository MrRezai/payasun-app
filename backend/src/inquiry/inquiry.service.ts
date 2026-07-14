import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inquiry, InquiryStatus } from '../entities/inquiry.entity';
import { EmployerProfile } from '../entities/employer-profile.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { Offer } from '../entities/offer.entity';
import { CreateInquiryDto } from './dto/create-inquiry.dto';
import { EstimateInquiryDto } from './dto/estimate-inquiry.dto';
import { ConfirmInquiryDto } from './dto/confirm-inquiry.dto';
import { SubmitOfferDto } from './dto/submit-offer.dto';

@Injectable()
export class InquiryService {
  constructor(
    @InjectRepository(Inquiry)
    private readonly inquiryRepository: Repository<Inquiry>,
    @InjectRepository(Offer)
    private readonly offerRepository: Repository<Offer>,
  ) {}

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
      title: dto.title,
      description: dto.description,
      city: dto.city,
      province: dto.province ?? null,
      status: initialStatus,
      has_blueprint: hasBlueprint,
      items: dto.items ?? [],
      blueprint_url: null,
    });

    return this.inquiryRepository.save(inquiry);
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
    inquiry.blueprint_url = fileUrl;
    inquiry.status = InquiryStatus.PENDING_ESTIMATION;

    return this.inquiryRepository.save(inquiry);
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

    return this.inquiryRepository.save(inquiry);
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
      throw new BadRequestException('فقط استعلام‌های برآورد شده یا پیش‌نویس قابل تأیید و انتشار هستند.');
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
    const inquiries = await this.inquiryRepository.find({ order: { created_at: 'DESC' } });
    
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

    if (inquiry.status !== InquiryStatus.PENDING_ESTIMATION) {
      throw new BadRequestException('فقط استعلام‌های در انتظار بررسی قابل رد شدن هستند.');
    }

    inquiry.status = InquiryStatus.REJECTED;
    inquiry.rejection_reason = reason;
    return this.inquiryRepository.save(inquiry);
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
    
    // If it was rejected, move it back to PENDING_ESTIMATION so it gets reviewed again!
    if (inquiry.status === InquiryStatus.REJECTED) {
      inquiry.status = InquiryStatus.PENDING_ESTIMATION;
      inquiry.rejection_reason = null;
    }

    if (dto.items && dto.items.length > 0) {
      inquiry.items = dto.items;
    }

    return this.inquiryRepository.save(inquiry);
  }

  /**
   * Retrieves all inquiries owned by a specific Employer.
   */
  async findByEmployer(employerId: string): Promise<any[]> {
    const inquiries = await this.inquiryRepository.find({
      where: { employerId },
      order: { created_at: 'DESC' },
    });

    // Fetch all offers
    const offers = await this.offerRepository.find({
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
      where: { inquiry_id: inquiryId },
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
}
