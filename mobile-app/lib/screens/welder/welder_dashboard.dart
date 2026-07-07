import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class WelderDashboard extends StatelessWidget {
  const WelderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welder Header Profile Card (Burgundy Gradient)
            _buildWelderHeaderCard(size),
            const SizedBox(height: 25),

            // Performance Metrics
            _buildSectionHeader('خلاصه عملکرد شما'),
            const SizedBox(height: 14),
            _buildPerformanceGrid(),
            const SizedBox(height: 28),

            // Tips & Auto-pricing section card
            _buildTipsCard(),
            const SizedBox(height: 28),

            // Current projects feed
            _buildSectionHeader('پروژه‌های جاری'),
            const SizedBox(height: 14),
            _buildCurrentContractsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelderHeaderCard(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.burgundy, Color(0xFF6B1825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.burgundy.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar container with glowing border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.amberOrange,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.white,
              child: Icon(Icons.engineering, color: AppColors.burgundy, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استاد جوشکار عزیز',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.amberOrange, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'تأیید شده',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'سطح ارشد',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.royalBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.burgundy,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              'پیشنهادها',
              '۱۲ عدد',
              Icons.pending_actions_outlined,
              AppColors.royalBlue,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'موفق',
              '۸ پروژه',
              Icons.done_all_outlined,
              Colors.green,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'امتیاز شما',
              '۴.۹',
              Icons.star_rate_rounded,
              AppColors.amberOrange,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'درآمد ماه',
              '۴۵.۲ م',
              Icons.account_balance_wallet_outlined,
              AppColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderGrey,
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.amberOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'راهنمای افزایش درآمد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'با دقیق کردن قیمت پیشنهادی و بررسی پلان استعلام‌ها، کارفرماهای بیشتری را جذب کنید.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContractsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_outlined, size: 36, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            'در حال حاضر پروژه جاری ندارید',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'از بخش «فرصت‌های کار» می‌توانید استعلام‌های منتشر شده را بررسی کرده و پیشنهاد خود را ثبت کنید.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
