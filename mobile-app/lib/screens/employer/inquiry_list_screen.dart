import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/inquiry.dart';
import '../../models/project.dart';
import '../../utils/formatters.dart';
import '../../services/api_service.dart';
import 'inquiry_details_screen.dart';
import 'create_inquiry_screen.dart';
import 'create_project_screen.dart';

class InquiryListScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? expandedProjectId;

  const InquiryListScreen({
    super.key,
    this.initialTabIndex = 0,
    this.expandedProjectId,
  });

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _projectsScrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });

    // Auto-refresh periodically every 8 seconds silently
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchData(silent: true);
      }
    });
  }

  void _fetchData({bool silent = false}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token.isNotEmpty) {
      final provider = Provider.of<InquiryProvider>(context, listen: false);
      provider.loadMyProjects(auth.token, silent: silent);
      provider.loadMyInquiries(auth.token, silent: silent);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _projectsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);
    final myProjects = provider.myProjects;
    final myInquiries = provider.myInquiries;

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
                  Tab(text: 'فهرست پروژه‌ها'),
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
                _buildProjectList(myProjects),
                _buildInquiryList(broadcastedInquiries, 'هیچ پروژه منتشر شده‌ای یافت نشد.'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProjectScreen(),
            ),
          );
          if (result == true && mounted) {
            _fetchData();
          }
        },
        backgroundColor: AppColors.royalBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'پروژه جدید',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center_outlined, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'تاکنون پروژه‌ای ثبت نکرده‌اید.',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ابتدا پروژه خود را تعریف کرده و سپس برای هر پروژه به تعداد دلخواه استعلام بگیرید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = Provider.of<InquiryProvider>(context);
    final String? targetProjectId = widget.expandedProjectId ?? provider.selectedExpandedProjectId;

    if (provider.selectedExpandedProjectId != null && _tabController.index != 0) {
      _tabController.animateTo(0);
    }

    if (targetProjectId != null && projects.isNotEmpty) {
      final int targetIndex = projects.indexWhere((p) => p.id == targetProjectId);
      if (targetIndex > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_projectsScrollController.hasClients) {
            final double offset = (targetIndex * 150.0).clamp(
              0.0,
              _projectsScrollController.position.maxScrollExtent,
            );
            _projectsScrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }

    return ListView.builder(
      controller: _projectsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final bool shouldExpand = targetProjectId != null && targetProjectId == project.id;
        return ProjectCardWidget(
          key: ValueKey('${project.id}_${project.inquiries.length}'),
          project: project,
          initiallyExpanded: shouldExpand,
          onRefresh: _fetchData,
          onDeleteConfirm: _confirmDeleteProject,
          inquiryCardBuilder: _buildInquiryCard,
        );
      },
    );
  }

  void _confirmDeleteProject(Project project) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف پروژه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Vazirmatn')),
          content: Text(
            'آیا از حذف پروژه «${project.title}» اطمینان دارید؟ با حذف این پروژه، تمامی استعلام‌های وابسته به آن نیز حذف خواهند شد.',
            style: const TextStyle(fontSize: 12, height: 1.5, fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final provider = Provider.of<InquiryProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);

                final ok = await provider.deleteProject(token: auth.token, projectId: project.id);
                if (ok) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('پروژه با موفقیت حذف شد.'), backgroundColor: Colors.green),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'خطا در حذف پروژه'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('بله، حذف کن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
            ),
          ],
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
                  fontFamily: 'Vazirmatn',
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
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      color: AppColors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => InquiryDetailsScreen(inquiry: inquiry),
              ),
            );
            if (res == true && mounted) {
              _fetchData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: 'Vazirmatn',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(inquiry.status),
                  ],
                ),
                const SizedBox(height: 6),

                // Description summary
                Text(
                  inquiry.description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Card Footer
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderGrey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        inquiry.province != null && inquiry.province!.isNotEmpty
                            ? '${inquiry.province}، ${inquiry.city}'
                            : inquiry.city,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_month_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Vazirmatn'),
                      ),
                      if (inquiry.status == 'BROADCASTED') ...[
                        const Spacer(),
                        const Icon(Icons.people_outline, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${inquiry.offers?.length ?? 0} پیشنهاد',
                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ],
                  ),
                ),

                // If estimated or has items, show item preview
                if (inquiry.items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildItemsPreview(inquiry.items),
                ],

                // Action triggers for Estimations
                if (inquiry.status == 'ESTIMATED') ...[
                  const SizedBox(height: 10),
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
        label = 'در انتظار تایید مدیریت';
        break;
      case 'ESTIMATED':
        bg = AppColors.royalBlue.withValues(alpha: 0.1);
        fg = AppColors.royalBlue;
        label = 'تایید شده';
        break;
      case 'BROADCASTED':
        bg = Colors.green.withValues(alpha: 0.1);
        fg = Colors.green;
        label = 'انتشار یافته';
        break;
      case 'AGREEMENT_PENDING_WELDER':
        bg = AppColors.amberOrange.withValues(alpha: 0.1);
        fg = AppColors.amberOrange;
        label = 'در انتظار تایید جوشکار';
        break;
      case 'IN_PROGRESS':
        bg = AppColors.royalBlue.withValues(alpha: 0.1);
        fg = AppColors.royalBlue;
        label = 'در حال اجرا';
        break;
      case 'COMPLETED_PENDING_EMPLOYER':
        bg = Colors.purple.withValues(alpha: 0.1);
        fg = Colors.purple;
        label = 'در انتظار تایید اتمام کارفرما';
        break;
      case 'COMPLETED':
        bg = Colors.teal.withValues(alpha: 0.1);
        fg = Colors.teal;
        label = 'اتمام یافته و ارزیابی‌شده';
        break;
      case 'DISPATCHED':
        bg = Colors.cyan.withValues(alpha: 0.1);
        fg = Colors.cyan;
        label = 'ارجاع به ۵ جوشکار';
        break;
      case 'EXPIRED':
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
        label = 'منقضی شده';
        break;
      case 'REJECTED':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        label = 'رد شده توسط مدیریت';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
        label = 'پیش‌نویس';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          fontFamily: 'Vazirmatn',
        ),
      ),
    );
  }

  Widget _buildItemsPreview(List<InquiryItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اقلام استعلام:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.burgundy, fontFamily: 'Vazirmatn'),
          ),
          const SizedBox(height: 2),
          Text(
            items.map((i) => '${i.title} (${i.quantity} ${i.unit})').join(' ، '),
            style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
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
      height: 36,
      child: ElevatedButton(
        onPressed: () {
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
        ),
      ),
    );
  }

  void _confirmInquiry(Inquiry inquiry) async {
    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    List<InquiryItem> editableItems = inquiry.items.map((e) => InquiryItem(
      title: e.title,
      unit: e.unit,
      quantity: e.quantity,
    )).toList();

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
                insetPadding: const EdgeInsets.all(16),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: 500,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note, color: AppColors.royalBlue, size: 26),
                          const SizedBox(width: 8),
                          const Text(
                            'بررسی، ویرایش و تایید برآورد اقلام',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.burgundy,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اقلام زیر بر اساس برآورد کارشناس از نقشه شما استخراج شده است. می‌توانید مقادیر را ویرایش کرده و سپس استعلام را منتشر کنید:',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5, fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(10),
                              itemCount: editableItems.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = editableItems[index];
                                return Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppColors.borderGrey),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${index + 1}. ${item.title}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppColors.textDark,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.lightGrey,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.borderGrey),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  if (item.quantity > 1) {
                                                    setDialogState(() {
                                                      editableItems[index] = InquiryItem(
                                                        title: item.title,
                                                        unit: item.unit,
                                                        quantity: item.quantity - 1,
                                                      );
                                                    });
                                                  }
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                                  child: Icon(Icons.remove, size: 14, color: AppColors.royalBlue),
                                                ),
                                              ),
                                              Text(
                                                '${item.quantity.toInt()} ${item.unit}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: AppColors.royalBlue,
                                                  fontFamily: 'Vazirmatn',
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    editableItems[index] = InquiryItem(
                                                      title: item.title,
                                                      unit: item.unit,
                                                      quantity: item.quantity + 1,
                                                    );
                                                  });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                                  child: Icon(Icons.add, size: 14, color: AppColors.royalBlue),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          onPressed: editableItems.length <= 1
                                              ? null
                                              : () {
                                                  setDialogState(() {
                                                    editableItems.removeAt(index);
                                                  });
                                                },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: const BorderSide(color: AppColors.borderGrey),
                                ),
                                child: const Text('انصراف', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn')),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 44,
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
                                          items: editableItems,
                                        );
                                        if (success && context.mounted) {
                                          Navigator.pop(context, true);
                                          _fetchData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('برآورد اقلام تایید شد و استعلام برای جوشکاران منتشر گردید!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          setDialogState(() {
                                            isSubmitting = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(provider.errorMessage ?? 'خطا در ثبت تایید استعلام'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('تأیید اقلام و انتشار عمومی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Vazirmatn')),
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

class ProjectCardWidget extends StatefulWidget {
  final Project project;
  final VoidCallback onRefresh;
  final Function(Project) onDeleteConfirm;
  final Widget Function(Inquiry) inquiryCardBuilder;
  final bool initiallyExpanded;

  const ProjectCardWidget({
    super.key,
    required this.project,
    required this.onRefresh,
    required this.onDeleteConfirm,
    required this.inquiryCardBuilder,
    this.initiallyExpanded = false,
  });

  @override
  State<ProjectCardWidget> createState() => _ProjectCardWidgetState();
}

class _ProjectCardWidgetState extends State<ProjectCardWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ProjectCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded && !oldWidget.initiallyExpanded) {
      _isExpanded = true;
    }
  }

  void _showPhotosGallery(BuildContext context, List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) {
        int currentIndex = 0;
        final PageController pageController = PageController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final persianCounter = Formatters.toPersianNumbers('${currentIndex + 1} از ${imageUrls.length}');

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: AppColors.white,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with counter chip & close X
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_outlined, color: AppColors.amberOrange, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'آلبوم تصاویر پروژه',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    persianCounter,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderGrey),

                      // Image Slider Container with Side Arrows
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: pageController,
                              itemCount: imageUrls.length,
                              onPageChanged: (index) {
                                setModalState(() {
                                  currentIndex = index;
                                });
                              },
                              itemBuilder: (context, idx) {
                                final url = imageUrls[idx];
                                final fullUrl = url.startsWith('http') ? url : '${ApiService().baseUrl}$url';
                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      fullUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator(color: AppColors.royalBlue));
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Prev Arrow Button
                            if (currentIndex > 0)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ),

                            // Next Arrow Button
                            if (currentIndex < imageUrls.length - 1)
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Dot Indicators at Bottom
                      if (imageUrls.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14, top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(imageUrls.length, (idx) {
                              final isActive = idx == currentIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.royalBlue : AppColors.borderGrey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final inquiries = project.inquiries;
    final dateStr = Formatters.toPersianDate(project.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      color: AppColors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title, Icon, and Photo Badge Stack
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apartment, color: AppColors.royalBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontFamily: 'Vazirmatn',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                project.province != null && project.province!.isNotEmpty
                                    ? '${project.province}، ${project.city}'
                                    : project.city,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                dateStr,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ultra-compact Micro Photo Badge (Clickable Lightbox Trigger)
                    if (project.imageUrls.isNotEmpty)
                      InkWell(
                        onTap: () => _showPhotosGallery(context, project.imageUrls),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amberOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 14, color: AppColors.amberOrange),
                              const SizedBox(width: 4),
                              Text(
                                Formatters.toPersianNumbers('${project.imageUrls.length} عکس'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amberOrange, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4, fontFamily: 'Vazirmatn'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Actions Toolbar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateProjectScreen(projectToEdit: project),
                          ),
                        );
                        if (res == true && mounted) {
                          widget.onRefresh();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: AppColors.borderGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textDark),
                      label: const Text('ویرایش', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => widget.onDeleteConfirm(project),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('حذف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red, fontFamily: 'Vazirmatn')),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateInquiryScreen(parentProject: project),
                          ),
                        );
                        if (result != null && result != false && mounted) {
                          setState(() {
                            _isExpanded = true;
                          });
                          widget.onRefresh();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberOrange,
                        foregroundColor: AppColors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_task, size: 17),
                      label: const Text(
                        'استعلام جدید',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Custom Expand/Collapse Toggle Button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.borderGrey, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 15, color: AppColors.royalBlue),
                  const SizedBox(width: 6),
                  Text(
                    'استعلام‌های این پروژه (${Formatters.toPersianNumbers(inquiries.length.toString())})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.royalBlue,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.royalBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content (Smooth Custom Container)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.lightGrey.withValues(alpha: 0.5),
              child: inquiries.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 26),
                          SizedBox(height: 4),
                          Text(
                            'هنوز استعلامی برای این پروژه ثبت نشده است.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: inquiries.map((inquiry) => widget.inquiryCardBuilder(inquiry)).toList(),
                    ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
