import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../utils/formatters.dart';
import '../../services/api_service.dart';
import 'inquiry_details_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isProfileLoaded) {
        auth.loadProfile();
      }
      Provider.of<InquiryProvider>(context, listen: false).loadMyInquiries(auth.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<InquiryProvider>(context);
    
    final profile = auth.profileData?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? '';
    final lastName = profile?['last_name'] as String? ?? '';
    final fullName = profile?['full_name'] as String? ?? '';
    final province = profile?['province'] as String? ?? '';
    final city = profile?['city'] as String? ?? '';
    final displayName = fullName.isNotEmpty ? fullName : 'کارفرما';

    final profilePicUrl = profile?['profile_picture_url'] as String?;
    final fullPicUrl = profilePicUrl != null && profilePicUrl.isNotEmpty
        ? '${ApiService().baseUrl}$profilePicUrl'
        : null;

    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) {
      if (initials.isNotEmpty) initials += '‌';
      initials += lastName[0];
    }
    if (initials.isEmpty) initials = 'ک‌م';

    String locationText = '';
    if (province.isNotEmpty && city.isNotEmpty) {
      locationText = '$province، $city';
    } else if (province.isNotEmpty) {
      locationText = province;
    } else {
      locationText = city;
    }

    final myInquiries = provider.myInquiries;

    // Calculate metrics
    int totalCount = myInquiries.length;
    int pendingEstimation = myInquiries.where((e) => e.status == 'PENDING_ESTIMATION').length;
    int estimated = myInquiries.where((e) => e.status == 'ESTIMATED').length;
    int broadcasted = myInquiries.where((e) => e.status == 'BROADCASTED').length;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadMyInquiries(auth.token);
      },
      color: AppColors.royalBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card (Redesigned matching welder profile card layout but with blue/business branding)
            _buildWelcomeCard(displayName, locationText, initials, fullPicUrl, auth),
            const SizedBox(height: 25),

            // Statistics Grid
            _buildSectionHeader('وضعیت استعلام‌های شما'),
            const SizedBox(height: 14),
            _buildStatsGrid(
              total: totalCount,
              pending: pendingEstimation,
              estimated: estimated,
              broadcasted: broadcasted,
            ),
            const SizedBox(height: 28),

            // Tips / Info Banner
            _buildTipsCard(),
            const SizedBox(height: 28),

            // Recent activity list
            _buildSectionHeader('آخرین فعالیت‌ها'),
            const SizedBox(height: 14),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.royalBlue),
                ),
              )
            else if (myInquiries.isEmpty)
              _buildEmptyState()
            else
              _buildRecentList(myInquiries),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String locationText, String initials, String? fullPicUrl, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlue, Color(0xFF1E3A8A)],
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
                  auth.setEmployerTabIndex(2);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.amberOrange,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: fullPicUrl != null ? Colors.transparent : AppColors.white,
                    backgroundImage: fullPicUrl != null ? NetworkImage(fullPicUrl) : null,
                    child: fullPicUrl != null
                        ? null
                        : Text(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, color: AppColors.amberOrange, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'کارفرمای رسمی',
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
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 12),
                      const SizedBox(width: 2),
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
            color: AppColors.royalBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid({
    required int total,
    required int pending,
    required int estimated,
    required int broadcasted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
              'کل درخواست‌ها',
              '$total',
              Icons.folder_open,
              AppColors.burgundy,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'انتظار تایید',
              '$pending',
              Icons.hourglass_empty,
              AppColors.amberOrange,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'تایید شده',
              '$estimated',
              Icons.check_circle_outline,
              AppColors.royalBlue,
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildMetricItem(
              'انتشار یافته',
              '$broadcasted',
              Icons.campaign,
              Colors.green,
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
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
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
                  'راهنمای برآورد دقیق جوشکاری',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'با بارگذاری نقشه‌های باکیفیت و تعیین طول دقیق شاسی، مقادیر مصرفی الکترود و آهن‌آلات را دقیق‌تر دریافت کنید.',
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

  Widget _buildEmptyState() {
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
            child: Icon(Icons.inbox_outlined, size: 36, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            'تاکنون استعلامی ثبت نکرده‌اید',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'از منوی پایین می‌توانید با زدن دکمه «استعلام جدید»، اولین استعلام جوشکاری خود را در سامانه ثبت کنید.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(List<dynamic> list) {
    final itemsToShow = list.take(3).toList();

    return Column(
      children: itemsToShow.map((inquiry) {
        final dateStr = Formatters.toPersianDate(inquiry.createdAt);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderGrey),
          ),
          color: AppColors.white,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InquiryDetailsScreen(inquiry: inquiry),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.description_outlined, color: AppColors.royalBlue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              inquiry.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(inquiry.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      inquiry.province != null && inquiry.province!.isNotEmpty
                          ? '${inquiry.province}، ${inquiry.city}'
                          : inquiry.city,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.layers_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${inquiry.items.length} ردیف نقشه',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                    ),
                    if (inquiry.status == 'BROADCASTED') ...[
                      const Spacer(),
                      const Icon(Icons.people_outline, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                    Text(
                      '${inquiry.offers?.length ?? 0} پیشنهاد',
                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'PENDING_ESTIMATION':
        bg = AppColors.amberOrange.withValues(alpha: 0.08);
        fg = AppColors.amberOrange;
        label = 'انتظار تایید';
        break;
      case 'ESTIMATED':
        bg = AppColors.royalBlue.withValues(alpha: 0.08);
        fg = AppColors.royalBlue;
        label = 'تایید شده';
        break;
      case 'BROADCASTED':
        bg = Colors.green.withValues(alpha: 0.08);
        fg = Colors.green;
        label = 'انتشار یافته';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.08);
        fg = Colors.grey;
        label = 'پیش‌نویس';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
