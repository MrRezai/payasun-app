import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual } from 'typeorm';
import { WelderProfile } from '../entities/welder-profile.entity';
import { EmployerReview } from '../entities/employer-review.entity';
import { Inquiry } from '../entities/inquiry.entity';

@Injectable()
export class WelderScoringService {
  private readonly logger = new Logger(WelderScoringService.name);

  constructor(
    @InjectRepository(WelderProfile)
    private readonly welderRepository: Repository<WelderProfile>,
    @InjectRepository(EmployerReview)
    private readonly reviewRepository: Repository<EmployerReview>,
    @InjectRepository(Inquiry)
    private readonly inquiryRepository: Repository<Inquiry>,
  ) {}

  /**
   * Calculates employer rating from 3 sub-scores (1 to 5 scale).
   * Formula: (0.4 * Quality) + (0.35 * Punctuality) + (0.25 * Behavior)
   */
  calculateEmployerRating(quality: number, punctuality: number, behavior: number): number {
    const q = Math.max(1, Math.min(5, Number(quality)));
    const p = Math.max(1, Math.min(5, Number(punctuality)));
    const b = Math.max(1, Math.min(5, Number(behavior)));
    const rating = 0.4 * q + 0.35 * p + 0.25 * b;
    return Number(rating.toFixed(2));
  }

  /**
   * Calculates experience score for a set of installs and an employer rating.
   * Formula: sqrt( Giresh_Count + (Other_Installs / 5) ) * (Employer_Rating / 5)
   */
  calculateExperienceScore(gireshCount: number, otherInstallsCount: number, employerRating: number): number {
    const g = Math.max(0, Number(gireshCount || 0));
    const o = Math.max(0, Number(otherInstallsCount || 0));
    const r = Math.max(0, Math.min(5, Number(employerRating || 5)));
    const totalInstallsWeighted = g + o / 5;
    const score = Math.sqrt(totalInstallsWeighted) * (r / 5);
    return Number(score.toFixed(2));
  }

  /**
   * Returns time decay multiplier based on months passed.
   * 0-3m -> 1.0, 3-6m -> 0.7, 6-12m -> 0.4, >12m -> 0.0
   */
  getTimeDecayMultiplier(date: Date): number {
    const diffMs = Date.now() - new Date(date).getTime();
    const months = diffMs / (1000 * 60 * 60 * 24 * 30.44);
    if (months <= 3) return 1.0;
    if (months <= 6) return 0.7;
    if (months <= 12) return 0.4;
    return 0.0;
  }

  /**
   * Dynamic/On-demand suspension reset check.
   * If suspension period has expired, resets suspension_until and missed_responses_count.
   */
  checkAndResetSuspension(welder: WelderProfile): boolean {
    if (welder.suspension_until && new Date(welder.suspension_until).getTime() <= Date.now()) {
      this.logger.log(`Suspension period expired for welder ${welder.id}. Auto-lifting suspension...`);
      welder.suspension_until = null;
      welder.missed_responses_count = 0;
      return true;
    }
    return false;
  }

  /**
   * Recalculates total score, employer average rating, and experience score for a welder.
   */
  async recalculateWelderScore(welderId: string): Promise<WelderProfile | null> {
    const welder = await this.welderRepository.findOne({ where: { id: welderId } });
    if (!welder) return null;

    // Check inline suspension reset
    this.checkAndResetSuspension(welder);

    // Fetch all employer reviews for this welder
    const reviews = await this.reviewRepository.find({
      where: { welder_id: welderId },
      order: { created_at: 'DESC' },
    });

    let avgRating = 5.0;
    let lowRatingsCount = 0;

    if (reviews.length > 0) {
      const sum = reviews.reduce((acc, r) => acc + Number(r.calculated_rating), 0);
      avgRating = Number((sum / reviews.length).toFixed(2));
      lowRatingsCount = reviews.filter((r) => Number(r.calculated_rating) < 2.5).length;
    }

    welder.employer_rating_avg = avgRating;
    welder.low_ratings_count = lowRatingsCount;

    // Apply 3-month suspension if 3 or more ratings are < 2.5
    if (lowRatingsCount >= 3 && !welder.suspension_until) {
      const suspendUntil = new Date();
      suspendUntil.setDate(suspendUntil.getDate() + 90); // 3 months
      welder.suspension_until = suspendUntil;
      this.logger.warn(`Welder ${welderId} received 3 low ratings (<2.5). Suspended until ${suspendUntil}`);
    }

    // Fetch completed inquiries for experience calculation
    const completedInquiries = await this.inquiryRepository.find({
      where: { id: welderId }, // or matched inquiries
    });

    let aggregatedExpScore = 0;
    for (const inq of completedInquiries) {
      const decay = this.getTimeDecayMultiplier(inq.updated_at || inq.created_at);
      const rawScore = this.calculateExperienceScore(
        inq.giresh_count,
        inq.other_installs_count,
        avgRating,
      );
      aggregatedExpScore += rawScore * decay;
    }

    welder.experience_score = Number(aggregatedExpScore.toFixed(2));
    const baseScore = 20.0;
    welder.total_score = Number((baseScore + Number(welder.responsiveness_score) + aggregatedExpScore).toFixed(2));

    return this.welderRepository.save(welder);
  }

  /**
   * Applies penalty for missed response.
   * Miss #1: Deduct 50% responsiveness score.
   * Miss #2: Deduct remaining 50% (score = 0).
   * Miss #3: Apply 1-month suspension.
   */
  async recordMissedResponse(welderId: string): Promise<WelderProfile | null> {
    const welder = await this.welderRepository.findOne({ where: { id: welderId } });
    if (!welder) return null;

    this.checkAndResetSuspension(welder);

    welder.missed_responses_count += 1;

    if (welder.missed_responses_count === 1) {
      welder.responsiveness_score = Number((Number(welder.responsiveness_score) * 0.5).toFixed(2));
    } else if (welder.missed_responses_count === 2) {
      welder.responsiveness_score = 0;
    } else if (welder.missed_responses_count >= 3) {
      welder.responsiveness_score = 0;
      const suspendUntil = new Date();
      suspendUntil.setDate(suspendUntil.getDate() + 30); // 1 month
      welder.suspension_until = suspendUntil;
      this.logger.warn(`Welder ${welderId} missed 3 responses. Suspended for 1 month until ${suspendUntil}`);
    }

    welder.total_score = Number((20.0 + Number(welder.responsiveness_score) + Number(welder.experience_score)).toFixed(2));
    return this.welderRepository.save(welder);
  }

  /**
   * Manually lifts welder suspension by admin.
   */
  async liftSuspension(welderId: string): Promise<WelderProfile | null> {
    const welder = await this.welderRepository.findOne({ where: { id: welderId } });
    if (!welder) return null;
    welder.suspension_until = null;
    welder.missed_responses_count = 0;
    welder.low_ratings_count = 0;
    this.logger.log(`Admin manually lifted suspension for welder ${welderId}`);
    return this.welderRepository.save(welder);
  }

  /**
   * Rewards +3 points for answering an inquiry.
   */
  async recordAnsweredInquiry(welderId: string): Promise<WelderProfile | null> {
    const welder = await this.welderRepository.findOne({ where: { id: welderId } });
    if (!welder) return null;

    this.checkAndResetSuspension(welder);

    welder.responsiveness_score = Number((Number(welder.responsiveness_score) + 3).toFixed(2));
    welder.total_score = Number((20.0 + Number(welder.responsiveness_score) + Number(welder.experience_score)).toFixed(2));
    return this.welderRepository.save(welder);
  }
}
