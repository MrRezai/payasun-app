import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/inquiry.dart';
import '../../utils/formatters.dart';
import 'inquiry_details_screen.dart';
import 'create_inquiry_screen.dart';

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
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(12),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontFamily: 'Vazirmatn'),
                tabs: const [
                  Tab(text: 'در حال پردازش (فعال)'),
                  Tab(text: 'تاریخچه انتشار'),
                ],
              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInquiryScreen(),
            ),
          );
        },
        backgroundColor: AppColors.royalBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'استعلام جدید',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Vazirmatn',
          ),
        ),
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
    final dateStr = Formatters.toPersianDate(inquiry.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      color: AppColors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                    inquiry.province != null && inquiry.province!.isNotEmpty
                        ? '${inquiry.province}، ${inquiry.city}'
                        : inquiry.city,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                  ),
                  if (inquiry.status == 'BROADCASTED') ...[
                    const Spacer(),
                    const Icon(Icons.people_outline, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      '۳ پیشنهاد',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
                  ],
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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, color: AppColors.royalBlue, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'تأیید نهایی برآورد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لیست اقلام زیر توسط کارشناسان برآورد شده است. در صورت تأیید، استعلام شما برای جوشکاران منتشر خواهد شد:',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      // List of items
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: inquiry.items.length,
                            separatorBuilder: (context, index) => const Divider(color: AppColors.borderGrey, height: 16),
                            itemBuilder: (context, index) {
                              final item = inquiry.items[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.amberOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.borderGrey),
                                    ),
                                    child: Text(
                                      '${item.quantity} ${item.unit}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: const BorderSide(color: AppColors.borderGrey),
                                ),
                                child: const Text('انصراف', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        setDialogState(() {
                                          isSubmitting = true;
                                        });
                                        final success = await provider.confirmInquiry(
                                          token: auth.token,
                                          inquiryId: inquiry.id,
                                          items: inquiry.items,
                                        );
                                        if (success && context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('برآورد با موفقیت تایید و منتشر شد.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          setDialogState(() {
                                            isSubmitting = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(provider.errorMessage ?? 'خطا در انتشار استعلام'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.royalBlue,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                                      )
                                    : const Text('تأیید و انتشار', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
