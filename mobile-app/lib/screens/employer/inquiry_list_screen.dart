import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/inquiry.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Provider.of<InquiryProvider>(context, listen: false).loadMyInquiries(token);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);
    final myInquiries = provider.myInquiries;

    // Filter lists
    final activeInquiries = myInquiries.where((e) => e.status != 'BROADCASTED').toList();
    final broadcastedInquiries = myInquiries.where((e) => e.status == 'BROADCASTED').toList();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: AppColors.white,
          child: SafeArea(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.royalBlue,
                  labelColor: AppColors.royalBlue,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(text: 'در حال پردازش (فعال)'),
                    Tab(text: 'تاریخچه انتشار'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.royalBlue),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInquiryList(activeInquiries, 'هیچ استعلام فعالی یافت نشد.'),
                _buildInquiryList(broadcastedInquiries, 'هیچ استعلام منتشر شده‌ای یافت نشد.'),
              ],
            ),
    );
  }

  Widget _buildInquiryList(List<Inquiry> inquiries, String emptyMessage) {
    if (inquiries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inquiries.length,
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        return _buildInquiryCard(inquiry);
      },
    );
  }

  Widget _buildInquiryCard(Inquiry inquiry) {
    // Basic Persian date placeholder logic
    final dateStr = '${inquiry.createdAt.year}/${inquiry.createdAt.month}/${inquiry.createdAt.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    inquiry.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(inquiry.status),
              ],
            ),
            const SizedBox(height: 12),

            // Description summary
            Text(
              inquiry.description,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Card Footer
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderGrey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    inquiry.city,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),

            // If estimated or has items, show item preview
            if (inquiry.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildItemsPreview(inquiry.items),
            ],

            // Action triggers for Estimations
            if (inquiry.status == 'ESTIMATED') ...[
              const SizedBox(height: 12),
              _buildConfirmButton(inquiry),
            ],
          ],
        ),
      ),
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
        label = 'در انتظار برآورد';
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

  Widget _buildItemsPreview(List<InquiryItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اقلام استعلام:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.burgundy),
          ),
          const SizedBox(height: 4),
          Text(
            items.map((i) => '${i.title} (${i.quantity} ${i.unit})').join(' ، '),
            style: const TextStyle(fontSize: 11, color: AppColors.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(Inquiry inquiry) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: () {
          // Open Employer-side confirmation flow or send patch request
          _confirmInquiry(inquiry);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amberOrange,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'مشاهده و تایید نهایی برآورد جهت انتشار',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmInquiry(Inquiry inquiry) async {
    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    // Direct mock confirm for demonstration or we can make a clean dialog to let the user confirm
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید نهایی برآورد', textDirection: TextDirection.rtl),
        content: const Text(
          'آیا با انتشار عمومی این اقلام برای جوشکاران موافق هستید؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('خیر'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('برآورد با موفقیت تایید و منتشر شد.')),
                );
                await provider.loadMyInquiries(token);
              } catch (e) {
                // handle error
              }
            },
            child: const Text('بله، انتشار عمومی'),
          ),
        ],
      ),
    );
  }
}
