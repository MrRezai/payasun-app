import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/inquiry.dart';
import '../../utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import 'create_inquiry_screen.dart';

class InquiryDetailsScreen extends StatefulWidget {
  final Inquiry inquiry;

  const InquiryDetailsScreen({super.key, required this.inquiry});

  @override
  State<InquiryDetailsScreen> createState() => _InquiryDetailsScreenState();
}

class _InquiryDetailsScreenState extends State<InquiryDetailsScreen> {
  Inquiry get inquiry => widget.inquiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Provider.of<InquiryProvider>(context, listen: false).loadInquiryOffers(
        token: token,
        inquiryId: widget.inquiry.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = Formatters.toPersianDate(inquiry.createdAt);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 18),
            onPressed: () => Navigator.pop(context),
            tooltip: 'بازگشت',
          ),
          title: const Text(
            'جزئیات استعلام',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark,
              fontFamily: 'Vazirmatn',
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Card
                _buildOverviewCard(context, dateStr),
                const SizedBox(height: 16),

                // Blueprint / Info Section
                if (inquiry.hasBlueprint) ...[
                  _buildBlueprintSection(context),
                  const SizedBox(height: 16),
                ],

                // Items Section
                _buildItemsSection(),
                const SizedBox(height: 16),

                // Offers Section (Bids)
                _buildOffersSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(inquiry.status),
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            inquiry.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontFamily: 'Vazirmatn',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.royalBlue, size: 16),
              const SizedBox(width: 6),
              Text(
                inquiry.province != null && inquiry.province!.isNotEmpty
                    ? '${inquiry.province}، ${inquiry.city}'
                    : inquiry.city,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderGrey, height: 1),
          const SizedBox(height: 16),
          const Text(
            'توضیحات استعلام:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.burgundy,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inquiry.description.isEmpty ? 'توضیحاتی ثبت نشده است.' : inquiry.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontFamily: 'Vazirmatn',
              height: 1.6,
            ),
          ),
          if (inquiry.status == 'REJECTED') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'علت رد شدن توسط ادمین:',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inquiry.rejectionReason ?? 'علتی توسط مدیریت ثبت نشده است.',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateInquiryScreen(inquiryToEdit: inquiry),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note, color: AppColors.white),
                label: const Text(
                  'اصلاح و ارسال مجدد جهت بررسی',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white, fontFamily: 'Vazirmatn'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlueprintSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: AppColors.royalBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'فایل پلان فنی ساختمان',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'پلان بارگذاری شده',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inquiry.blueprintUrl != null
                            ? 'فرمت فایل ضمیمه شده'
                            : 'در انتظار آپلود یا پردازش فایل پلان...',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                if (inquiry.blueprintUrl != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'در حال باز کردن نقشه فنی...',
                            style: TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('دانلود فایل', style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.royalBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'لیست اقلام استعلام',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (inquiry.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.pending_actions_outlined, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      inquiry.hasBlueprint
                          ? 'در انتظار تایید مدیریت...'
                          : 'هیچ قلمی ثبت نشده است.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'Vazirmatn',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inquiry.items.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.borderGrey, height: 1),
              itemBuilder: (context, index) {
                final item = inquiry.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.royalBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Text(
                          '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    final showBids = inquiry.status == 'BROADCASTED';
    final inquiryProvider = Provider.of<InquiryProvider>(context);
    final offers = inquiryProvider.inquiryOffers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, color: AppColors.royalBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'پیشنهادهای قیمت جوشکاران',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(width: 8),
              if (showBids && offers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${offers.length} پیشنهاد',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!showBids)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.lock_clock_outlined, color: Colors.amber[600], size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'پس از تأیید نهایی برآورد و انتشار عمومی استعلام، پیشنهادهای جوشکاران ثبت‌شده در این قسمت نمایش داده خواهد شد.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFamily: 'Vazirmatn',
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (inquiryProvider.isLoading && offers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(color: AppColors.royalBlue),
              ),
            )
          else
            _buildBidsList(context, offers),
        ],
      ),
    );
  }

  Widget _buildBidsList(BuildContext context, List<dynamic> offers) {
    if (offers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'هنوز هیچ پیشنهادی از سوی جوشکاران ثبت نشده است.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bid = offers[index];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                        child: Text(
                          bid['initials'] as String,
                          style: const TextStyle(
                            color: AppColors.royalBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bid['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'جوشکار تأیید شده',
                                    style: TextStyle(
                                      color: AppColors.royalBlue,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${bid['rating']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.textDark,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${bid['projects']} پروژه موفق)',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        bid['time'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderGrey, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مبلغ پیشنهادی کارشناسی شده:',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Formatters.formatPrice(int.tryParse(bid['price']) ?? 0)} تومان',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.royalBlue,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                _showCallPreviewDialog(context, bid['name'] as String, bid['phone'] as String);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.borderGrey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.phone_in_talk_outlined, color: AppColors.royalBlue, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _showProfilePreviewDialog(context, bid);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: const Text(
                              'مشاهده پروفایل',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ],
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
  }

  void _showCallPreviewDialog(BuildContext context, String name, String phone) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'تماس با $name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Vazirmatn'),
            ),
            content: Text(
              'مایل به برقراری تماس تلفنی با جوشکار هستید؟\nشماره تماس: $phone',
              style: const TextStyle(fontSize: 13, height: 1.6, fontFamily: 'Vazirmatn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف', style: TextStyle(color: Colors.grey, fontFamily: 'Vazirmatn')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'در حال برقراری تماس با شماره $phone...',
                        style: const TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('تماس گرفتن', style: TextStyle(fontFamily: 'Vazirmatn')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfilePreviewDialog(BuildContext context, Map<String, dynamic> bid) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                  child: Text(
                    bid['initials'] as String,
                    style: const TextStyle(
                      color: AppColors.royalBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  bid['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'متخصص جوشکاری اسکلت و لوله‌کشی گاز',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${bid['rating']} از ۵',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${bid['projects']} پروژه انجام‌شده',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderGrey, height: 1),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'جزئیات قیمت پیشنهادی برای هر قلم:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.royalBlue,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: (bid['items_prices'] as List<dynamic>?)?.length ?? 0,
                    separatorBuilder: (context, index) => const Divider(height: 12, color: AppColors.borderGrey),
                    itemBuilder: (context, index) {
                      final item = bid['items_prices'][index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? '',
                              style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                          Text(
                            '${Formatters.formatPrice(item['price'] as int? ?? 0)} تومان',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.borderGrey, height: 1),
                const SizedBox(height: 16),
                const Text(
                  'مهارت‌ها و تجهیزات:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.burgundy,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSkillChip('جوشکاری آرگون'),
                    _buildSkillChip('جوشکاری CO2'),
                    _buildSkillChip('دارای ژنراتور برق سیار'),
                    _buildSkillChip('تجهیزات ایمنی کامل'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('بستن', style: TextStyle(fontFamily: 'Vazirmatn')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'DRAFT':
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = 'پیش‌نویس';
        break;
      case 'PENDING_ESTIMATION':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        label = 'در انتظار تایید مدیریت';
        break;
      case 'ESTIMATED':
        bgColor = AppColors.royalBlue.withValues(alpha: 0.1);
        textColor = AppColors.royalBlue;
        label = 'برآورد شده';
        break;
      case 'BROADCASTED':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        label = 'انتشار یافته';
        break;
      case 'REJECTED':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        label = 'رد شده توسط مدیریت';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Vazirmatn',
        ),
      ),
    );
  }
}
