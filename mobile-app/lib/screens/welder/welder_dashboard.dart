import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class WelderDashboard extends StatefulWidget {
  const WelderDashboard({super.key});

  @override
  State<WelderDashboard> createState() => _WelderDashboardState();
}

class _WelderDashboardState extends State<WelderDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isProfileLoaded) {
        auth.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profileData?['profile'] as Map<String, dynamic>?;


    final firstName = profile?['first_name'] ?? '';
    final lastName = profile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'جوشکار';

    final homeCity = profile?['home_city'] as String? ?? '';
    final homeProvince = profile?['home_province'] as String? ?? '';
    final activeProvince = profile?['active_province'] as String? ?? '';
    final activeCities = (profile?['active_cities'] as List<dynamic>?) ?? [];
    final totalScore = double.tryParse(profile?['total_score']?.toString() ?? '0') ?? 0;
    final completedJobs = profile?['completed_jobs_count'] ?? 0;
    final isSetupCompleted = profile?['is_setup_completed'] == true;

    final priceList = (profile?['base_price_list'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welder Header Profile Card
            _buildWelderHeaderCard(displayName, homeCity, homeProvince, totalScore, isSetupCompleted),
            const SizedBox(height: 25),

            // Performance Metrics
            _buildSectionHeader('خلاصه عملکرد شما'),
            const SizedBox(height: 14),
            _buildPerformanceGrid(completedJobs, totalScore, priceList.length),
            const SizedBox(height: 28),

            // Active Cities Coverage
            _buildSectionHeader('محدوده فعالیت شما'),
            const SizedBox(height: 14),
            _buildCoverageCard(activeProvince, activeCities),
            const SizedBox(height: 28),



            // Price List Section
            if (priceList.isNotEmpty) ...[
              _buildSectionHeader('تعرفه‌های فعال شما'),
              const SizedBox(height: 14),
              _buildPriceListCard(priceList),
              const SizedBox(height: 28),
            ],



            // Tips
            _buildTipsCard(),
            const SizedBox(height: 28),

            // Current projects
            _buildSectionHeader('پروژه‌های جاری'),
            const SizedBox(height: 14),
            _buildCurrentContractsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelderHeaderCard(String name, String city, String province, double score, bool setupDone) {
    final locationText = [city, province].where((s) => s.isNotEmpty).join('، ');

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
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (setupDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
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
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          locationText,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (score > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < score.round() ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.amberOrange,
                          size: 14,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildPerformanceGrid(int completedJobs, double score, int tariffCount) {
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
              'پروژه‌های انجام شده',
              '$completedJobs',
              Icons.done_all_outlined,
              Colors.green,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'امتیاز شما',
              score > 0 ? score.toStringAsFixed(1) : '—',
              Icons.star_rate_rounded,
              AppColors.amberOrange,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'تعرفه‌های فعال',
              '$tariffCount',
              Icons.receipt_long_outlined,
              AppColors.royalBlue,
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
          textAlign: TextAlign.center,
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

  Widget _buildCoverageCard(String activeProvince, List<dynamic> activeCities) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeProvince.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.royalBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'استان فعال: $activeProvince',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          if (activeCities.isNotEmpty) ...[
            if (activeProvince.isNotEmpty) const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_city_outlined, color: AppColors.royalBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${activeCities.length} شهر فعال',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeCities.map((city) {
                return Chip(
                  label: Text(city.toString()),
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                  labelStyle: const TextStyle(color: AppColors.royalBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.royalBlue, width: 0.5),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (activeProvince.isEmpty && activeCities.isEmpty)
            const Center(
              child: Text(
                'محدوده فعالیت تعیین نشده است.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildPriceListCard(List<dynamic> priceList) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: priceList.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final title = item['title'] ?? '';
          final unit = item['unit'] ?? '';
          final price = item['price_per_unit'];
          final priceStr = price != null ? _formatPrice(price) : '—';

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.burgundy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.construction, color: AppColors.burgundy, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'واحد: $unit',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$priceStr تومان',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                  ),
                ],
              ),
              if (idx < priceList.length - 1)
                const Divider(color: AppColors.borderGrey, height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final numValue = double.tryParse(price.toString()) ?? 0;
    final integerPart = numValue.toInt();
    return integerPart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
