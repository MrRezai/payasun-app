import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/inquiry.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      Provider.of<InquiryProvider>(context, listen: false).loadAllInquiries(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);
    final allInquiries = provider.allInquiries;
    final availableJobs = allInquiries.where((e) => e.status == 'BROADCASTED').toList();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'تالار پروژه‌ها',
          style: TextStyle(
            color: AppColors.burgundy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderGrey, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = Provider.of<AuthProvider>(context, listen: false).token;
          await provider.loadAllInquiries(token);
        },
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.royalBlue),
              )
            : _buildJobsList(availableJobs),
      ),
    );
  }

  Widget _buildJobsList(List<Inquiry> jobs) {
    if (jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[300]),
                ),
                const SizedBox(height: 18),
                const Text(
                  'هیچ پروژه جدیدی منتشر نشده است',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'جهت دریافت آخرین کارها صفحه را به پایین بکشید.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(jobs[index]);
      },
    );
  }

  Widget _buildJobCard(Inquiry job) {
    final dateStr = '${job.createdAt.year}/${job.createdAt.month}/${job.createdAt.day}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with meta
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'درخواست فعال',
                        style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.royalBlue),
                    const SizedBox(width: 4),
                    Text(
                      'شهر: ${job.city}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppColors.borderGrey),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توضیحات پروژه کارفرما:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.burgundy),
                ),
                const SizedBox(height: 6),
                Text(
                  job.description,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Items checklist container
                _buildItemsPreviewBlock(job.items),
              ],
            ),
          ),

          // Card Action Bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  _showBiddingBottomSheet(job);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burgundy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'مشاهده جزئیات و ثبت قیمت پیشنهادی',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsPreviewBlock(List<InquiryItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اقلام مورد نیاز (${items.length} مورد):',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ...items.take(2).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: AppColors.royalBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.title} — مقدار: ${item.quantity} ${item.unit}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (items.length > 2) ...[
            const SizedBox(height: 4),
            Text(
              'و ${items.length - 2} قلم دیگر...',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void _showBiddingBottomSheet(Inquiry job) {
    final bidController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull handler line
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  const Text(
                    'ثبت پیشنهاد قیمت جدید',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job.title,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Input Box
                  TextFormField(
                    controller: bidController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'لطفاً مبلغ کل را وارد کنید';
                      }
                      if (double.tryParse(val) == null) {
                        return 'لطفاً فقط عدد انگلیسی وارد کنید';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'مبلغ کل پیشنهادی (تومان)',
                      hintText: 'مثال: ۵,۰۰۰,۰۰۰',
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'تومان',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 20, color: AppColors.borderGrey),
                          ],
                        ),
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.royalBlue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'این پیشنهاد قیمت به عنوان تخمین اولیه مستقیماً برای کارفرما ارسال می‌شود.',
                            style: TextStyle(fontSize: 10, color: AppColors.royalBlue, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final price = bidController.text.trim();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'پیشنهاد قیمت شما به مبلغ $price تومان با موفقیت ثبت شد.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('ثبت و ارسال پیشنهاد قیمت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
