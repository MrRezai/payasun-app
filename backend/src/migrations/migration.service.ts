import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class DataMigrationService implements OnModuleInit {
  private readonly logger = new Logger(DataMigrationService.name);

  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async onModuleInit() {
    await this.runMigrations();
  }

  async runMigrations() {
    this.logger.log('Executing database backward-compatibility data migration...');

    try {
      // 1. Backfill Welder Profiles defaults
      await this.dataSource.query(`
        UPDATE welder_profiles 
        SET 
          total_score = COALESCE(total_score, 20.0),
          responsiveness_score = COALESCE(responsiveness_score, 0.0),
          experience_score = COALESCE(experience_score, 0.0),
          employer_rating_avg = COALESCE(employer_rating_avg, 5.0),
          tier = COALESCE(tier, 'A'),
          preferred_tiers = COALESCE(preferred_tiers, '["A", "B", "C", "D"]'::jsonb),
          working_cities = CASE 
            WHEN working_cities IS NULL OR jsonb_array_length(working_cities) = 0 THEN 
              CASE WHEN home_city IS NOT NULL AND home_city != '' THEN jsonb_build_array(home_city) ELSE '[]'::jsonb END
            ELSE working_cities 
          END,
          experience_start_date = COALESCE(experience_start_date, (SELECT created_at FROM users WHERE users.id = welder_profiles.user_id)),
          missed_responses_count = COALESCE(missed_responses_count, 0),
          low_ratings_count = COALESCE(low_ratings_count, 0),
          active_jobs_count = COALESCE(active_jobs_count, 0),
          completed_tier_a_count = COALESCE(completed_tier_a_count, 0),
          completed_tier_b_count = COALESCE(completed_tier_b_count, 0),
          completed_tier_c_count = COALESCE(completed_tier_c_count, 0),
          is_out_of_service = COALESCE(is_out_of_service, false)
        WHERE tier IS NULL OR total_score IS NULL OR working_cities IS NULL;
      `);

      // 2. Backfill Inquiries defaults
      await this.dataSource.query(`
        UPDATE inquiries 
        SET 
          tier = COALESCE(tier, 'A'),
          deposit_amount = COALESCE(deposit_amount, 0.0),
          giresh_count = COALESCE(giresh_count, 0),
          other_installs_count = COALESCE(other_installs_count, 0),
          is_re_dispatched = COALESCE(is_re_dispatched, false)
        WHERE tier IS NULL OR deposit_amount IS NULL;
      `);

      this.logger.log('Database migration completed successfully with 0 errors.');
    } catch (error) {
      this.logger.error(`Database migration warning: ${error.message}`);
    }
  }
}
