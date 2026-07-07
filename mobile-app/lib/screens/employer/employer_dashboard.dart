import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';

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
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Provider.of<InquiryProvider>(context, listen: false).loadMyInquiries(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);
    final myInquiries = provider.myInquiries;

    // Calculate metrics
    int totalCount = myInquiries.length;
    int pendingEstimation = myInquiries.where((e) => e.status == 'PENDING_ESTIMATION').length;
    int estimated = myInquiries.where((e) => e.status == 'ESTIMATED').length;
    int broadcasted = myInquiries.where((e) => e.status == 'BROADCASTED').length;

    return RefreshIndicator(
      onRefresh: () async {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        await provider.loadMyInquiries(token);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            _buildWelcomeCard(),
            const SizedBox(height: 25),

            // Statistics Grid
            _buildSectionHeader('وضعیت استعلام‌های شما'),
            const SizedBox(height: 12),
            _buildStatsGrid(
              total: totalCount,
              pending: pendingEstimation,
              estimated: estimated,
              broadcasted: broadcasted,
            ),
            const SizedBox(height: 25),

            // Recent activity list
            _buildSectionHeader('آخرین فعالیت‌ها'),
            const SizedBox(height: 12),
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

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlue, Color(0xFF5C85FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خوش آمدید به جفت‌وجور',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'درخواست خود را ثبت کنید تا در سریع‌ترین زمان ممکن نقشه‌های شما برآورد شده و برای جوشکاران حرفه‌ای ارسال گردد.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.burgundy,
      ),
    );
  }

  Widget _buildStatsGrid({
    required int total,
    required int pending,
    required int estimated,
    required int broadcasted,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('کل درخواست‌ها', total.toString(), Icons.folder_open, AppColors.burgundy),
        _buildStatCard('انتظار برآورد', pending.toString(), Icons.hourglass_empty, AppColors.amberOrange),
        _buildStatCard('برآورد شده', estimated.toString(), Icons.check_circle_outline, AppColors.royalBlue),
        _buildStatCard('انتشار یافته', broadcasted.toString(), Icons.campaign, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'تاکنون استعلامی ثبت نکرده‌اید',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'هم‌اکنون استعلام جوشکاری خود را در سامانه ثبت کنید.',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(List<dynamic> list) {
    // Show top 3 recent inquiries
    final itemsToShow = list.take(3).toList();

    return Column(
      children: itemsToShow.map((inquiry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              inquiry.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'شهر: ${inquiry.city} | تعداد اقلام: ${inquiry.items.length}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            trailing: _buildStatusBadge(inquiry.status),
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
        bg = AppColors.amberOrange.withValues(alpha: 0.1);
        fg = AppColors.amberOrange;
        label = 'انتظار برآورد';
        break;
      case 'ESTIMATED':
        bg = AppColors.royalBlue.withValues(alpha: 0.1);
        fg = AppColors.royalBlue;
        label = 'برآورد شده';
        break;
      case 'BROADCASTED':
        bg = Colors.green.withValues(alpha: 0.1);
        fg = Colors.green;
        label = 'انتشار یافته';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
        label = 'پیش‌نویس';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
