import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WelderProfile } from '../entities/welder-profile.entity';

@Injectable()
export class WelderLevelingService {
  private readonly logger = new Logger(WelderLevelingService.name);

  constructor(
    @InjectRepository(WelderProfile)
    private readonly welderRepository: Repository<WelderProfile>,
  ) {}

  /**
   * Classifies a project into Tier A, B, C, or D based on floor count and total area.
   *  - Tier A (الف): Up to 2 floors or up to 250 sqm
   *  - Tier B (ب): 3 to 5 floors or 251 to 750 sqm
   *  - Tier C (ج): 6 to 9 floors or 751 to 1800 sqm
   *  - Tier D (د): 10+ floors or 1800+ sqm
   */
  classifyProjectTier(floorCount?: number | null, areaSqm?: number | null): string {
    const floors = Number(floorCount || 0);
    const area = Number(areaSqm || 0);

    if (floors >= 10 || area > 1800) {
      return 'D';
    } else if (floors >= 6 || area > 750) {
      return 'C';
    } else if (floors >= 3 || area > 250) {
      return 'B';
    }
    return 'A';
  }

  /**
   * Checks welder completed jobs count per tier and promotes tier if requirements are met:
   *  - Tier A -> B: 3 completed Tier A jobs with Rating > 4.0
   *  - Tier B -> C: 3 completed Tier B jobs with Rating > 4.0
   *  - Tier C -> D: 3 completed Tier C jobs with Rating > 4.0
   */
  async checkAndUpdateWelderPromotion(welderId: string, completedProjectTier: string, rating: number): Promise<WelderProfile | null> {
    const welder = await this.welderRepository.findOne({ where: { id: welderId } });
    if (!welder) return null;

    if (rating >= 4.0) {
      if (completedProjectTier === 'A') welder.completed_tier_a_count += 1;
      else if (completedProjectTier === 'B') welder.completed_tier_b_count += 1;
      else if (completedProjectTier === 'C') welder.completed_tier_c_count += 1;
    }

    // Check Promotions
    if (welder.tier === 'A' && welder.completed_tier_a_count >= 3) {
      welder.tier = 'B';
      this.logger.log(`Welder ${welderId} PROMOTED to Tier B (ب)!`);
    }

    if (welder.tier === 'B' && welder.completed_tier_b_count >= 3) {
      welder.tier = 'C';
      this.logger.log(`Welder ${welderId} PROMOTED to Tier C (ج)!`);
    }

    if (welder.tier === 'C' && welder.completed_tier_c_count >= 3) {
      welder.tier = 'D';
      this.logger.log(`Welder ${welderId} PROMOTED to Tier D (د)!`);
    }

    return this.welderRepository.save(welder);
  }

  /**
   * Evaluates if a welder is eligible to receive a dispatch for a project of tier `projectTier`.
   *
   * Logic:
   *  - Preferred Tiers vs Leveling Match:
   *    If welder has selected higher target tiers (e.g. C or D) but hasn't reached them yet (currently Tier A),
   *    we allow dispatching lower tiers (A and B) to help them progress.
   *    Once they reach their target tier (e.g. C), we strictly enforce their preferred_tiers filter.
   */
  isWelderEligibleForTierDispatch(welder: WelderProfile, projectTier: string): boolean {
    const preferredTiers = welder.preferred_tiers || ['A', 'B', 'C', 'D'];
    const currentTier = welder.tier || 'A';

    const tierRank: Record<string, number> = { A: 1, B: 2, C: 3, D: 4 };
    const projectRank = tierRank[projectTier] || 1;
    const currentRank = tierRank[currentTier] || 1;

    // Minimum target tier selected by welder
    const preferredRanks = preferredTiers.map((t) => tierRank[t] || 1);
    const minPreferredRank = Math.min(...preferredRanks);

    // If welder has reached or exceeded their lowest preferred tier, strictly filter by preferred_tiers
    if (currentRank >= minPreferredRank) {
      return preferredTiers.includes(projectTier);
    }

    // If welder hasn't reached their preferred target tier yet, allow projects up to their current rank
    // so they can complete 3 projects and level up!
    return projectRank <= currentRank;
  }
}
