import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/inquiry.dart';
import '../../utils/formatters.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  String? _selectedCityFilter;

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

    final filteredJobs = _selectedCityFilter == null
        ? availableJobs
        : availableJobs.where((job) => job.city == _selectedCityFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'تالار پروژه‌ها',
          style: TextStyle(
            color: AppColors.royalBlue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderGrey, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(availableJobs),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                await provider.loadAllInquiries(token);
              },
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.royalBlue),
                    )
                  : _buildJobsList(filteredJobs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<Inquiry> availableJobs) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profileData?['profile'];
    final activeCities = (profile?['active_cities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    List<String> filterOptions = [];
    if (activeCities.isNotEmpty) {
      filterOptions = activeCities;
    } else {
      filterOptions = availableJobs.map((e) => e.city).where((c) => c.isNotEmpty).toSet().toList();
    }

    if (filterOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final options = ['همه شهرها', ...filterOptions];

    return Container(
      height: 56,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final city = options[index];
            final bool isAllOption = index == 0;
            final bool isSelected = isAllOption 
                ? _selectedCityFilter == null 
                : _selectedCityFilter == city;

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(
                  city,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.white : AppColors.textDark,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.royalBlue,
                backgroundColor: AppColors.lightGrey,
                checkmarkColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.royalBlue : AppColors.borderGrey,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (isAllOption) {
                      _selectedCityFilter = null;
                    } else {
                      _selectedCityFilter = city;
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobsList(List<Inquiry> jobs) {
    if (jobs.isEmpty) {
      final String noJobsMsg = _selectedCityFilter != null
          ? 'هیچ پروژه جدیدی در شهر $_selectedCityFilter یافت نشد.'
          : 'هیچ پروژه جدیدی منتشر نشده است';

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
                Text(
                  noJobsMsg,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'جهت دریافت آخرین کارها صفحه را به پایین بکشید.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
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
    final dateStr = Formatters.toPersianDate(job.createdAt);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final welderUserId = authProvider.profileData?['id'] as String?;
    final welderProfileId = authProvider.profileData?['profile']?['id'] as String?;

    final hasBid = job.offers?.any((o) => 
      o['welder_id'] == welderProfileId || o['welder_user_id'] == welderUserId
    ) ?? false;

    final myOffer = hasBid 
        ? job.offers?.firstWhere((o) => o['welder_id'] == welderProfileId || o['welder_user_id'] == welderUserId)
        : null;

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
                    if (hasBid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 10, color: AppColors.royalBlue),
                            SizedBox(width: 4),
                            Text(
                              'پیشنهاد ثبت شده',
                              style: TextStyle(color: AppColors.royalBlue, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'درخواست فعال',
                          style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
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
                  if (hasBid) {
                    _showOfferDetailsBottomSheet(job, myOffer);
                  } else {
                    _showBiddingBottomSheet(job);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBid ? Colors.white : AppColors.royalBlue,
                  foregroundColor: hasBid ? AppColors.royalBlue : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: hasBid ? const BorderSide(color: AppColors.royalBlue) : BorderSide.none,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  hasBid ? 'مشاهده جزئیات پیشنهاد شما' : 'مشاهده جزئیات و ثبت قیمت پیشنهادی',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
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
    final formKey = GlobalKey<FormState>();
    final controllers = List.generate(job.items.length, (_) => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        bool scaffoldChecked = false;
        bool powerChecked = false;
        bool rodChecked = false;
        bool deliveryChecked = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            double totalSum = 0;
            for (var controller in controllers) {
              final cleanText = Formatters.cleanNumber(controller.text);
              final val = double.tryParse(cleanText) ?? 0.0;
              totalSum += val;
            }

            final bool allChecked = scaffoldChecked && powerChecked && rodChecked && deliveryChecked;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),

                        const Text(
                          'ثبت پیشنهاد قیمت جدید',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.royalBlue,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.title,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'لطفاً قیمت پیشنهادی خود را برای هر کدام از اقلام به صورت مجزا وارد کنید:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: job.items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = job.items[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderGrey),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.royalBlue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                        ),
                                      ),
                                      Text(
                                        'مقدار: ${item.quantity} ${item.unit}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.royalBlue, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: controllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.left,
                                    inputFormatters: [
                                      PersianPriceInputFormatter(),
                                    ],
                                    onChanged: (_) {
                                      setSheetState(() {});
                                    },
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'لطفاً مبلغ این قلم را وارد کنید';
                                      }
                                      final cleaned = Formatters.cleanNumber(val);
                                      if (double.tryParse(cleaned) == null) {
                                        return 'مبلغ نامعتبراست';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'مبلغ پیشنهادی برای این قلم (تومان)',
                                      hintText: 'مثال: ۱,۵۰۰,۰۰۰',
                                      filled: true,
                                      fillColor: AppColors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.borderGrey),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.borderGrey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.textMuted, size: 18),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vazirmatn'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'جمع کل پیشنهادی شما:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                              ),
                              Text(
                                '${Formatters.formatPrice(totalSum.toInt())} تومان',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'تعهدات و شرایط انجام کار (تایید کلیه موارد الزامی است):',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 8),

                        _buildCheckboxRow(
                          label: 'تامین زیر پایی مناسب بر عهده کارفرما است',
                          value: scaffoldChecked,
                          onChanged: (val) {
                            setSheetState(() {
                              scaffoldChecked = val ?? false;
                            });
                          },
                        ),
                        _buildCheckboxRow(
                          label: 'تامین برق بر عهده کارفرما است',
                          value: powerChecked,
                          onChanged: (val) {
                            setSheetState(() {
                              powerChecked = val ?? false;
                            });
                          },
                        ),
                        _buildCheckboxRow(
                          label: 'تامین سیم جوش و صفحه بر عهده کارفرما است',
                          value: rodChecked,
                          onChanged: (val) {
                            setSheetState(() {
                              rodChecked = val ?? false;
                            });
                          },
                        ),
                        _buildCheckboxRow(
                          label: 'تحویل آهن آلات تا پای کار بر عهده کارفرما است',
                          value: deliveryChecked,
                          onChanged: (val) {
                            setSheetState(() {
                              deliveryChecked = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (!allChecked || isSubmitting)
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() {
                                      isSubmitting = true;
                                    });

                                    final token = Provider.of<AuthProvider>(context, listen: false).token;
                                    final inquiryProvider = Provider.of<InquiryProvider>(context, listen: false);

                                    final List<Map<String, dynamic>> itemsPrices = [];
                                    for (int i = 0; i < job.items.length; i++) {
                                      final cleanText = Formatters.cleanNumber(controllers[i].text);
                                      final val = double.tryParse(cleanText) ?? 0.0;
                                      itemsPrices.add({
                                        'title': job.items[i].title,
                                        'price': val.toInt(),
                                      });
                                    }

                                    final success = await inquiryProvider.submitOffer(
                                      token: token,
                                      inquiryId: job.id,
                                      totalPrice: totalSum,
                                      itemsPrices: itemsPrices,
                                      scaffoldChecked: scaffoldChecked,
                                      powerChecked: powerChecked,
                                      rodChecked: rodChecked,
                                      deliveryChecked: deliveryChecked,
                                    );

                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'پیشنهاد قیمت شما به مبلغ ${Formatters.formatPrice(totalSum.toInt())} تومان با موفقیت ثبت شد.',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      setSheetState(() {
                                        isSubmitting = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            inquiryProvider.errorMessage ?? 'خطا در ثبت پیشنهاد قیمت',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'ثبت و ارسال پیشنهاد قیمت',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.royalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferDetailsBottomSheet(Inquiry job, Map<String, dynamic>? offer) {
    if (offer == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final totalSum = (offer['total_price'] as num?)?.toDouble() ?? 0.0;
        final itemsPrices = offer['items_prices'] as List<dynamic>? ?? [];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.royalBlue, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'جزئیات پیشنهاد قیمت شما',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'این پیشنهاد پیش‌تر با موفقیت برای پروژه «${job.title}» ثبت شده است.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'دستمزد پیشنهادی تفکیک‌شده به ازای هر قلم:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemsPrices.length,
                    separatorBuilder: (context, index) => const Divider(height: 12, color: AppColors.borderGrey),
                    itemBuilder: (context, index) {
                      final item = itemsPrices[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                          Text(
                            '${Formatters.formatPrice((item['price'] as num?)?.toInt() ?? 0)} تومان',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'جمع کل دستمزد پیشنهادی شما:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        Text(
                          '${Formatters.formatPrice(totalSum.toInt())} تومان',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'تعهدات پذیرفته‌شده کارفرما:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 10),
                  _buildAgreedConditionItem('تامین داربست یا زیرپایی مناسب بر عهده کارفرما است.'),
                  _buildAgreedConditionItem('تامین برق مورد نیاز بر عهده کارفرما است.'),
                  _buildAgreedConditionItem('تامین سیم‌جوش و صفحه برش بر عهده کارفرما است.'),
                  _buildAgreedConditionItem('تحویل آهن‌آلات تا پای کار بر عهده کارفرما است.'),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'بستن',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgreedConditionItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
            ),
          ),
        ],
      ),
    );
  }
}
