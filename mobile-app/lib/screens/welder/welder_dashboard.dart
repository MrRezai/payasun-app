import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/inquiry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/api_service.dart';
import '../employer/inquiry_details_screen.dart';

class WelderDashboard extends StatefulWidget {
  const WelderDashboard({super.key});

  @override
  State<WelderDashboard> createState() => _WelderDashboardState();
}

class _WelderDashboardState extends State<WelderDashboard> {
  bool _tipEnabled = true;
  String _tipTitle = 'راهنمای دریافت بیشتر پروژه';
  String _tipText = 'با دقیق کردن قیمت پیشنهادی و بررسی پلان استعلام‌ها، کارفرماهای بیشتری را جذب کنید.';

  @override
  void initState() {
    super.initState();
    _loadTips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isProfileLoaded) {
        auth.loadProfile();
      }
    });
  }

  void _loadTips() async {
    final data = await ApiService().fetchAppTips();
    if (data != null && mounted) {
      setState(() {
        _tipEnabled = data['welder_enabled'] ?? true;
        if (data['welder_title'] != null && (data['welder_title'] as String).isNotEmpty) {
          _tipTitle = data['welder_title'];
        }
        if (data['welder_text'] != null && (data['welder_text'] as String).isNotEmpty) {
          _tipText = data['welder_text'];
        }
      });
    }
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
    final skills = (profile?['skills'] as List<dynamic>?) ?? [];

    final profilePicUrl = profile?['profile_picture_url'] as String?;
    final fullPicUrl = profilePicUrl != null && profilePicUrl.isNotEmpty
        ? '${ApiService().baseUrl}$profilePicUrl'
        : null;

    String initials = '';
    if (firstName.toString().isNotEmpty) initials += firstName.toString()[0];
    if (lastName.toString().isNotEmpty) {
      if (initials.isNotEmpty) initials += '‌';
      initials += lastName.toString()[0];
    }
    if (initials.isEmpty) initials = 'ج‌م';

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welder Header Profile Card
            _buildWelderHeaderCard(displayName, homeCity, homeProvince, totalScore, isSetupCompleted, initials, fullPicUrl, auth, skills, profile?['tier'] ?? 'A'),
            const SizedBox(height: 25),

            // High Priority Pending Agreement Alert Carousel (When Selected by Employer)
            Builder(
              builder: (context) {
                final inquiryProvider = Provider.of<InquiryProvider>(context);
                final pendingInquiries = inquiryProvider.allInquiries
                    .where((i) => i.status == 'AGREEMENT_PENDING_WELDER')
                    .toList();
                if (pendingInquiries.isEmpty) return const SizedBox.shrink();

                return WelderPendingAgreementsSection(
                  pendingInquiries: pendingInquiries,
                  authProvider: auth,
                  inquiryProvider: inquiryProvider,
                );
              },
            ),

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
            if (_tipEnabled) ...[
              _buildTipsCard(),
              const SizedBox(height: 28),
            ],

            // Current projects
            _buildSectionHeader('پروژه‌های جاری'),
            const SizedBox(height: 14),
            _buildCurrentContractsSection(Provider.of<InquiryProvider>(context), auth),
          ],
        ),
      ),
    );
  }

  Widget _buildWelderHeaderCard(String name, String city, String province, double score, bool setupDone, String initials, String? fullPicUrl, AuthProvider auth, List<dynamic> skills, String tier) {
    final locationText = [province, city].where((s) => s.isNotEmpty).join('، ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlue, Color(0xFF254EDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  auth.setWelderTabIndex(2);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.amberOrange,
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: AppColors.royalBlue.withValues(alpha: 0.12),
                      child: fullPicUrl != null
                          ? Image.network(
                              fullPicUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.royalBlue.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppColors.royalBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.royalBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                    ),
                  ),

                ),
              ),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amberOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'گروه $tier',
                        style: const TextStyle(color: AppColors.royalBlue, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) {
                      return Icon(
                        i < (score / 4).round() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.amberOrange,
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      'امتیاز: ${score.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: skills.map((skill) {
                      final name = skill['name'] as String? ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      );
                    }).toList(),
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
            color: AppColors.burgundy,
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
                const Icon(Icons.map_outlined, color: AppColors.burgundy, size: 18),
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
                const Icon(Icons.location_city_outlined, color: AppColors.burgundy, size: 18),
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
                  backgroundColor: AppColors.burgundy.withValues(alpha: 0.08),
                  labelStyle: const TextStyle(color: AppColors.burgundy, fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.burgundy, width: 0.5),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (activeProvince.isEmpty && activeCities.isEmpty)
            const SizedBox(height: 8),
          const Text(
            'استعلام‌های ارجاع‌شده در تب کارهای موجود نمایش داده می‌شوند.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.construction, color: AppColors.royalBlue, size: 16),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.burgundy),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tipTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tipText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContractsSection(InquiryProvider inquiryProvider, AuthProvider authProvider) {
    final activeJobsCount = (authProvider.profileData?['profile']?['active_jobs_count'] as int?) ?? 0;
    
    if (activeJobsCount > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.construction_outlined, color: AppColors.royalBlue, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'شما ۱ پروژه فعال در حال اجرا دارید',
                    style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'پس از به اتمام رسیدن عملیات جوشکاری پروژه، دکمه زیر را جهت اطلاع‌رسانی به کارفرما و ثبت تاییدیه نهایی بفشارید.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final inquiries = inquiryProvider.allInquiries;
                  final activeInquiry = inquiries.cast<Inquiry?>().firstWhere(
                    (i) => i?.status == 'IN_PROGRESS' || i?.status == 'AGREEMENT_PENDING_WELDER',
                    orElse: () => null,
                  );
                  if (activeInquiry != null) {
                    final success = await inquiryProvider.finishJob(
                      token: authProvider.token,
                      inquiryId: activeInquiry.id,
                    );
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('اعلام پایان کار با موفقیت ثبت شد و پیامک تایید برای کارفرما ارسال گردید.'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(inquiryProvider.errorMessage ?? 'خطا در اعلام اتمام کار'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('پروژه فعال در حالت اجرا یافت نشد.')),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('اعلام پایان کار پروژه به کارفرما', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

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

class WelderPendingAgreementsSection extends StatefulWidget {
  final List<Inquiry> pendingInquiries;
  final AuthProvider authProvider;
  final InquiryProvider inquiryProvider;

  const WelderPendingAgreementsSection({
    super.key,
    required this.pendingInquiries,
    required this.authProvider,
    required this.inquiryProvider,
  });

  @override
  State<WelderPendingAgreementsSection> createState() => _WelderPendingAgreementsSectionState();
}

class _WelderPendingAgreementsSectionState extends State<WelderPendingAgreementsSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.pendingInquiries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.amberOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'دعوت‌نامه‌های تایید شروع کار (${widget.pendingInquiries.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
            if (widget.pendingInquiries.length > 1)
              Text(
                '${_currentIndex + 1} از ${widget.pendingInquiries.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontFamily: 'Vazirmatn',
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 165,
          child: PageView.builder(
            itemCount: widget.pendingInquiries.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final inquiry = widget.pendingInquiries[index];
              return Container(
                margin: const EdgeInsets.only(left: 4, right: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amberOrange.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.amberOrange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars_rounded, color: AppColors.amberOrange, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inquiry.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'شهر: ${inquiry.city} | بیعانه: ${(inquiry.depositAmount ?? 0).toInt()} تومان',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    DispatchCountdownTimer(dispatchedAt: inquiry.updatedAt ?? inquiry.createdAt),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final success = await widget.inquiryProvider.confirmAgreement(
                                  token: widget.authProvider.token,
                                  inquiryId: inquiry.id,
                                );
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('توافق با موفقیت تایید گردید. پروژه به حالت «در حال اجرا» تغییر یافت.'), backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(widget.inquiryProvider.errorMessage ?? 'خطا در تایید توافق'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('تایید توافق و شروع کار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Vazirmatn')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.royalBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InquiryDetailsScreen(inquiry: inquiry),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.royalBlue),
                            label: const Text('جزئیات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.royalBlue, fontFamily: 'Vazirmatn')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              side: const BorderSide(color: AppColors.royalBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.pendingInquiries.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.pendingInquiries.length,
              (i) => Container(
                width: _currentIndex == i ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentIndex == i ? AppColors.amberOrange : AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 25),
      ],
    );
  }
}

class DispatchCountdownTimer extends StatefulWidget {
  final DateTime dispatchedAt;
  const DispatchCountdownTimer({super.key, required this.dispatchedAt});

  @override
  State<DispatchCountdownTimer> createState() => _DispatchCountdownTimerState();
}

class _DispatchCountdownTimerState extends State<DispatchCountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calc();
        });
      }
    });
  }

  void _calc() {
    final expire = widget.dispatchedAt.add(const Duration(hours: 24));
    final diff = expire.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: h < 3 ? Colors.red[50] : AppColors.amberOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: h < 3 ? Colors.red[200]! : AppColors.amberOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: h < 3 ? Colors.red : AppColors.amberOrange),
          const SizedBox(width: 4),
          Text(
            'مهلت تایید توافق: ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: h < 3 ? Colors.red : AppColors.amberOrange,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}
