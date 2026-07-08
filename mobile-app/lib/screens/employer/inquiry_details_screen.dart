import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/inquiry.dart';
import '../../utils/formatters.dart';

class InquiryDetailsScreen extends StatelessWidget {
  final Inquiry inquiry;

  const InquiryDetailsScreen({super.key, required this.inquiry});

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
                _buildOverviewCard(dateStr),
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

  Widget _buildOverviewCard(String dateStr) {
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
                          ? 'در انتظار برآورد اقلام از روی پلان توسط کارشناس...'
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
              if (showBids)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '۳ پیشنهاد',
                    style: TextStyle(
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
          else
            _buildBidsList(context),
        ],
      ),
    );
  }

  Widget _buildBidsList(BuildContext context) {
    // Dynamically generate mock proposals based on inquiry ID hash to keep them consistent
    final seed = inquiry.id.hashCode;
    final List<Map<String, dynamic>> mockBids = [
      {
        'name': 'علی‌رضا مرادی',
        'rating': 4.8,
        'projects': 18 + (seed % 5),
        'price': '${Formatters.formatPrice(5400000 + (seed % 10) * 100000)} تومان',
        'phone': '09123456789',
        'initials': 'ع‌م',
        'time': '۲ ساعت پیش',
      },
      {
        'name': 'محمد امینی',
        'rating': 4.6,
        'projects': 9 + (seed % 3),
        'price': '${Formatters.formatPrice(5700000 + (seed % 8) * 100000)} تومان',
        'phone': '09129876543',
        'initials': 'م‌ا',
        'time': '۵ ساعت پیش',
      },
      {
        'name': 'امیرحسین رضایی',
        'rating': 4.9,
        'projects': 34 + (seed % 10),
        'price': '${Formatters.formatPrice(5100000 + (seed % 6) * 100000)} تومان',
        'phone': '09125556677',
        'initials': 'ا‌ر',
        'time': '۱ روز پیش',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockBids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bid = mockBids[index];

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
                      // Welder Avatar
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
                      // Welder Details
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
                            'مبلغ کل پیشنهادی:',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bid['price'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.burgundy,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Contact Button
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
                          // View Profile CTA
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
        label = 'در انتظار برآورد';
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
