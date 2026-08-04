import { Injectable, Logger, NotFoundException, BadRequestException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, Not, LessThanOrEqual } from 'typeorm';
import { Inquiry, InquiryStatus } from '../entities/inquiry.entity';
import { WelderProfile } from '../entities/welder-profile.entity';
import { InquiryDispatch, DispatchType, DispatchStatus } from '../entities/inquiry-dispatch.entity';
import { WelderScoringService } from '../scoring/welder-scoring.service';
import { WelderLevelingService } from '../leveling/welder-leveling.service';
import { SmsService } from '../sms/sms.service';

@Injectable()
export class InquiryDispatchService implements OnModuleInit {
  private readonly logger = new Logger(InquiryDispatchService.name);

  constructor(
    @InjectRepository(Inquiry)
    private readonly inquiryRepository: Repository<Inquiry>,
    @InjectRepository(WelderProfile)
    private readonly welderRepository: Repository<WelderProfile>,
    @InjectRepository(InquiryDispatch)
    private readonly dispatchRepository: Repository<InquiryDispatch>,
    private readonly scoringService: WelderScoringService,
    private readonly levelingService: WelderLevelingService,
    private readonly smsService: SmsService,
  ) {}

  onModuleInit() {
    // Run hourly check for 24h timeouts and 72h expirations
    setInterval(() => {
      this.handle24HourTimeouts().catch((e) => this.logger.error(`Error in 24h timeout check: ${e.message}`));
      this.handle72HourExpirations().catch((e) => this.logger.error(`Error in 72h expiration check: ${e.message}`));
    }, 60 * 60 * 1000);
  }

  /**
   * Main 5-Welder Smart Dispatch Algorithm.
   * Dispatches 3 Top Score + 1 Newcomer + 1 Random candidate.
   * If re-dispatch (after 72h expiration), excludes all previously dispatched welders.
   */
  async dispatch5Welders(inquiryId: string): Promise<InquiryDispatch[]> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) {
      throw new NotFoundException('استعلام مورد نظر یافت نشد.');
    }

    // Determine inquiry project tier if not already set
    if (!inquiry.tier || inquiry.tier === 'A') {
      inquiry.tier = this.levelingService.classifyProjectTier(inquiry.floor_count, inquiry.area_sqm);
    }
    inquiry.deposit_amount = Number(inquiry.area_sqm || 0) * 1000;

    // Fetch all previously dispatched welder IDs for this inquiry (to exclude on re-dispatch)
    const previousDispatches = await this.dispatchRepository.find({ where: { inquiry_id: inquiryId } });
    const excludedWelderIds = new Set(previousDispatches.map((d) => d.welder_id));

    // Fetch all candidate welders
    const allWelders = await this.welderRepository.find();

    // Filter eligible candidates
    const eligibleWelders = allWelders.filter((w) => {
      // Exclude previously dispatched welders
      if (excludedWelderIds.has(w.id)) return false;

      // Inline suspension expiration check
      this.scoringService.checkAndResetSuspension(w);

      // Active suspension check
      if (w.suspension_until && new Date(w.suspension_until).getTime() > Date.now()) return false;

      // Out of service check
      if (w.is_out_of_service) return false;

      // Single active job constraint: max 1 ongoing active job
      if (w.active_jobs_count >= 1) return false;

      // City matching
      const operatingCities = w.working_cities || (w.home_city ? [w.home_city] : []);
      const cityMatches = operatingCities.some(
        (c) => c && c.trim().toLowerCase() === inquiry.city?.trim().toLowerCase(),
      );
      if (!cityMatches) return false;

      // Tier capability eligibility match
      return this.levelingService.isWelderEligibleForTierDispatch(w, inquiry.tier);
    });

    if (eligibleWelders.length === 0) {
      this.logger.warn(`No eligible welders found for inquiry ${inquiryId} in city ${inquiry.city}`);
      inquiry.status = InquiryStatus.DISPATCHED;
      inquiry.dispatched_at = new Date();
      await this.inquiryRepository.save(inquiry);
      return [];
    }

    // Sort by total score DESC
    eligibleWelders.sort((a, b) => Number(b.total_score) - Number(a.total_score));

    const selectedDispatches: { welder: WelderProfile; type: DispatchType }[] = [];

    // 1. Select 3 Top Score Welders
    const top3 = eligibleWelders.slice(0, 3);
    top3.forEach((w) => selectedDispatches.push({ welder: w, type: DispatchType.TOP_SCORE }));

    const selectedIds = new Set(selectedDispatches.map((d) => d.welder.id));

    // 2. Select 1 Newcomer (0 to 2 completed jobs)
    const newcomer = eligibleWelders.find(
      (w) => !selectedIds.has(w.id) && Number(w.completed_jobs_count || 0) <= 2,
    );
    if (newcomer) {
      selectedDispatches.push({ welder: newcomer, type: DispatchType.NEWCOMER });
      selectedIds.add(newcomer.id);
    }

    // 3. Select 1 Random Welder from remaining candidates
    const remaining = eligibleWelders.filter((w) => !selectedIds.has(w.id));
    if (remaining.length > 0) {
      const randomIndex = Math.floor(Math.random() * remaining.length);
      const randomWelder = remaining[randomIndex];
      selectedDispatches.push({ welder: randomWelder, type: DispatchType.RANDOM });
    } else if (eligibleWelders.length > selectedDispatches.length) {
      // If no separate newcomer/random available, pick next highest score candidate
      const nextCandidate = eligibleWelders.find((w) => !selectedIds.has(w.id));
      if (nextCandidate) {
        selectedDispatches.push({ welder: nextCandidate, type: DispatchType.RANDOM });
      }
    }

    // Create InquiryDispatch rows and send SMS alerts
    const createdDispatches: InquiryDispatch[] = [];
    const dispatchRound = inquiry.is_re_dispatched ? 2 : 1;

    for (const item of selectedDispatches) {
      const dispatch = this.dispatchRepository.create({
        inquiry_id: inquiryId,
        welder_id: item.welder.id,
        dispatch_type: item.type,
        dispatch_round: dispatchRound,
        status: DispatchStatus.PENDING,
        dispatched_at: new Date(),
      });

      const savedDispatch = await this.dispatchRepository.save(dispatch);
      createdDispatches.push(savedDispatch);

      // Send SMS alert to welder
      if (item.welder.user && item.welder.user.phone_number) {
        const message = `یک پروژه جدید با رده ${inquiry.tier} در شهر ${inquiry.city} به شما ارجاع داده شد. ۲۴ ساعت مهلت ثبت پاسخ دارید.`;
        this.smsService.sendSimpleSms(item.welder.user.phone_number, message).catch((err) => {
          this.logger.error(`Failed to send dispatch SMS to welder ${item.welder.id}: ${err.message}`);
        });
      }
    }

    inquiry.status = InquiryStatus.DISPATCHED;
    inquiry.dispatched_at = new Date();
    await this.inquiryRepository.save(inquiry);

    this.logger.log(`Successfully dispatched ${createdDispatches.length} welders for inquiry ${inquiryId}`);
    return createdDispatches;
  }

  /**
   * Hourly Check: Auto-replaces non-responding welders after 24 hours.
   */
  async handle24HourTimeouts(): Promise<void> {
    this.logger.log('Running 24-hour dispatch timeout & auto-replacement check...');
    const now = Date.now();
    const timeoutThreshold = new Date(now - 24 * 60 * 60 * 1000);

    const pendingDispatches = await this.dispatchRepository.find({
      where: {
        status: DispatchStatus.PENDING,
        dispatched_at: LessThanOrEqual(timeoutThreshold),
      },
      relations: ['inquiry', 'welder', 'welder.user'],
    });

    for (const dispatch of pendingDispatches) {
      // Skip if inquiry is already contracted or finished
      if (
        dispatch.inquiry.status === InquiryStatus.IN_PROGRESS ||
        dispatch.inquiry.status === InquiryStatus.COMPLETED
      ) {
        continue;
      }

      this.logger.warn(
        `Dispatch ${dispatch.id} for welder ${dispatch.welder_id} timed out after 24h. Replaces candidate...`,
      );

      // Mark timed out
      dispatch.status = DispatchStatus.TIMED_OUT;
      await this.dispatchRepository.save(dispatch);

      // Apply missed response penalty
      await this.scoringService.recordMissedResponse(dispatch.welder_id);

      // Find replacement candidate
      await this.replaceCandidate(dispatch);
    }
  }

  /**
   * Replaces a timed out candidate with the next eligible welder of the same type.
   */
  private async replaceCandidate(oldDispatch: InquiryDispatch): Promise<void> {
    const inquiry = oldDispatch.inquiry;
    const allDispatches = await this.dispatchRepository.find({ where: { inquiry_id: inquiry.id } });
    const excludedIds = new Set(allDispatches.map((d) => d.welder_id));

    const candidates = await this.welderRepository.find();
    const eligible = candidates.filter((w) => {
      if (excludedIds.has(w.id)) return false;
      this.scoringService.checkAndResetSuspension(w);
      if (w.suspension_until && new Date(w.suspension_until).getTime() > Date.now()) return false;
      if (w.is_out_of_service || w.active_jobs_count >= 1) return false;

      const cities = w.working_cities || (w.home_city ? [w.home_city] : []);
      if (!cities.some((c) => c && c.trim().toLowerCase() === inquiry.city?.trim().toLowerCase())) return false;

      return this.levelingService.isWelderEligibleForTierDispatch(w, inquiry.tier);
    });

    if (eligible.length === 0) return;

    eligible.sort((a, b) => Number(b.total_score) - Number(a.total_score));
    const replacementWelder = eligible[0];

    const replacementDispatch = this.dispatchRepository.create({
      inquiry_id: inquiry.id,
      welder_id: replacementWelder.id,
      dispatch_type: DispatchType.REPLACEMENT,
      dispatch_round: oldDispatch.dispatch_round,
      status: DispatchStatus.PENDING,
      dispatched_at: new Date(),
    });

    await this.dispatchRepository.save(replacementDispatch);

    if (replacementWelder.user && replacementWelder.user.phone_number) {
      const message = `یک پروژه جایگزین جدید در شهر ${inquiry.city} به شما ارجاع داده شد. ۲۴ ساعت مهلت ثبت پاسخ دارید.`;
      this.smsService.sendSimpleSms(replacementWelder.user.phone_number, message).catch(() => {});
    }
  }

  /**
   * Hourly Check: Auto-expires inquiries after 72 hours of no contract agreement.
   */
  async handle72HourExpirations(): Promise<void> {
    const expirationThreshold = new Date(Date.now() - 72 * 60 * 60 * 1000);
    const expiredInquiries = await this.inquiryRepository.find({
      where: {
        status: InquiryStatus.DISPATCHED,
        dispatched_at: LessThanOrEqual(expirationThreshold),
      },
    });

    for (const inquiry of expiredInquiries) {
      this.logger.warn(`Inquiry ${inquiry.id} expired after 72 hours without contract agreement.`);
      inquiry.status = InquiryStatus.EXPIRED;
      await this.inquiryRepository.save(inquiry);
    }
  }

  /**
   * Re-dispatches an expired 72h inquiry after employer pays fee.
   * Excludes all previously dispatched welders.
   */
  async reDispatchInquiry(inquiryId: string, employerId: string): Promise<InquiryDispatch[]> {
    const inquiry = await this.inquiryRepository.findOne({ where: { id: inquiryId } });
    if (!inquiry) throw new NotFoundException('استعلام یافت نشد.');
    if (inquiry.employerId !== employerId) throw new BadRequestException('عدم دسترسی.');

    inquiry.is_re_dispatched = true;
    inquiry.status = InquiryStatus.PENDING_ESTIMATION;
    await this.inquiryRepository.save(inquiry);

    return this.dispatch5Welders(inquiryId);
  }
}
