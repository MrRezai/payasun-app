import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inquiry, InquiryStatus } from '../entities/inquiry.entity';
import { CreateInquiryDto } from './dto/create-inquiry.dto';
import { EstimateInquiryDto } from './dto/estimate-inquiry.dto';
import { ConfirmInquiryDto } from './dto/confirm-inquiry.dto';

@Injectable()
export class InquiryService {
  constructor(
    @InjectRepository(Inquiry)
    private readonly inquiryRepository: Repository<Inquiry>,
  ) {}

  /**
   * Creates a new inquiry.
   * If manual items are provided and has_blueprint is false, it starts as BROADCASTED or DRAFT.
   * If has_blueprint is true, it starts as DRAFT until the blueprint file is uploaded.
   */
  async create(employerId: string, dto: CreateInquiryDto): Promise<Inquiry> {
    const hasBlueprint = dto.has_blueprint ?? false;
    let initialStatus = InquiryStatus.DRAFT;

    // If manual items are provided immediately without blueprint, we can broadcast it directly
    if (!hasBlueprint && dto.items && dto.items.length > 0) {
      initialStatus = InquiryStatus.BROADCASTED;
    } else if (hasBlueprint) {
      initialStatus = InquiryStatus.DRAFT; // Awaiting blueprint upload
    }

    const inquiry = this.inquiryRepository.create({
      employerId,
      title: dto.title,
      description: dto.description,
      city: dto.city,
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
   * Retrieves all inquiries (useful for Admin and Welders).
   */
  async findAll(): Promise<Inquiry[]> {
    return this.inquiryRepository.find({ order: { created_at: 'DESC' } });
  }

  /**
   * Retrieves all inquiries owned by a specific Employer.
   */
  async findByEmployer(employerId: string): Promise<Inquiry[]> {
    return this.inquiryRepository.find({
      where: { employerId },
      order: { created_at: 'DESC' },
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
}
