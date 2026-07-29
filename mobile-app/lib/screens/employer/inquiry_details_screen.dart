import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/inquiry.dart';
import '../../models/project.dart';
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
  List<InquiryItem> _editableItems = [];
  bool _showEstimatedBanner = true;

  @override
  void initState() {
    super.initState();
    _editableItems = List.from(widget.inquiry.items);
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
    final provider = Provider.of<InquiryProvider>(context);

    Project? parentProject;
    if (inquiry.projectId != null && inquiry.projectId!.isNotEmpty) {
      final match = provider.myProjects.cast<Project?>().firstWhere(
        (p) => p?.id == inquiry.projectId,
        orElse: () => null,
      );
      if (match != null) parentProject = match;
    }

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
                // Guidance Alert for ESTIMATED status before publication
                if (inquiry.status == 'ESTIMATED' && _showEstimatedBanner) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.royalBlue, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'اقلام کارشناسی شده توسط مدیریت ثبت گردیده است. شما می‌توانید پیش از انتشار عمومی استعلام، لیست اقلام را ویرایش کرده و سپس انتشار دهید.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textDark,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showEstimatedBanner = false),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Parent Project Card if available
                if (parentProject != null) ...[
                  _buildParentProjectCard(context, parentProject),
                ],

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
        bottomNavigationBar: inquiry.status == 'ESTIMATED'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.borderGrey, width: 1)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final token = Provider.of<AuthProvider>(context, listen: false).token;
                        final provider = Provider.of<InquiryProvider>(context, listen: false);
                        final success = await provider.confirmInquiry(
                          token: token,
                          inquiryId: inquiry.id,
                          items: _editableItems,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('استعلام با موفقیت تأیید و در سیستم منتشر شد!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'تأیید نهایی و انتشار عمومی استعلام',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildParentProjectCard(BuildContext context, Project project) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<InquiryProvider>(context, listen: false);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business_rounded, color: AppColors.royalBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'پروژه مربوطه (پروژه والد)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              provider.setSelectedExpandedProjectId(project.id);
              auth.setEmployerTabIndex(1);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مشاهده پروژه',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_back, size: 14),
              ],
            ),
          ),
        ],
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
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final provider = Provider.of<InquiryProvider>(context, listen: false);
                  final nav = Navigator.of(context);
                  final res = await nav.push(
                    MaterialPageRoute(
                      builder: (context) => CreateInquiryScreen(inquiryToEdit: inquiry),
                    ),
                  );
                  if (res == true && mounted) {
                    await provider.loadMyInquiries(auth.token);
                    if (mounted) nav.pop();
                  }
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

  IconData _getBlueprintFileIcon(String filename) {
    final cleanName = filename.split('?')[0].toLowerCase();
    final ext = cleanName.contains('.') ? cleanName.split('.').last : '';
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (ext == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    if (['dwg', 'dxf', 'dwf', 'rvt', 'skp', 'ifc', 'pln'].contains(ext)) {
      return Icons.architecture_outlined;
    }
    if (['zip', 'rar', '7z'].contains(ext)) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _getBlueprintFileColor(String filename) {
    final cleanName = filename.split('?')[0].toLowerCase();
    final ext = cleanName.contains('.') ? cleanName.split('.').last : '';
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
      return AppColors.burgundy;
    }
    if (ext == 'pdf') {
      return Colors.redAccent;
    }
    if (['dwg', 'dxf', 'dwf', 'rvt', 'skp', 'ifc', 'pln'].contains(ext)) {
      return AppColors.amberOrange;
    }
    if (['zip', 'rar', '7z'].contains(ext)) {
      return Colors.purple;
    }
    return AppColors.royalBlue;
  }

  Widget _buildBlueprintSection(BuildContext context) {
    final urls = inquiry.blueprintUrl != null && inquiry.blueprintUrl!.isNotEmpty
        ? inquiry.blueprintUrl!.split(',').where((u) => u.trim().isNotEmpty).toList()
        : <String>[];

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
              const Icon(Icons.folder_open_outlined, color: AppColors.royalBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'فایل‌های پلان فنی ساختمان (${urls.length} فایل)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (urls.isEmpty)
            const Text(
              'در انتظار آپلود یا پردازش فایل‌های پلان...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urls.length,
              itemBuilder: (context, index) {
                final url = urls[index];
                final fileName = url.split('/').last;
                final fileIcon = _getBlueprintFileIcon(fileName);
                final fileColor = _getBlueprintFileColor(fileName);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      Icon(fileIcon, color: fileColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'پلان شماره ${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontFamily: 'Vazirmatn',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'در حال باز کردن فایل $fileName...',
                                style: const TextStyle(fontFamily: 'Vazirmatn'),
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
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final displayItems = _editableItems.isNotEmpty ? _editableItems : inquiry.items;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (inquiry.status == 'ESTIMATED')
                TextButton.icon(
                  onPressed: () => _showEditEstimatedItemsBottomSheet(context),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.royalBlue),
                  label: const Text(
                    'ویرایش اقلام',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.royalBlue,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.pending_actions_outlined, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      inquiry.hasBlueprint
                          ? 'در انتظار برآورد اولیه مدیریت...'
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
              itemCount: displayItems.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.borderGrey, height: 1),
              itemBuilder: (context, index) {
                final item = displayItems[index];
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
                          Formatters.toPersianNumbers((index + 1).toString()),
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
                          '${Formatters.toPersianNumbers(item.quantity.toStringAsFixed(0))} ${item.unit}',
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

  void _showEditEstimatedItemsBottomSheet(BuildContext context) {
    List<InquiryItem> tempItems = List.from(_editableItems.isNotEmpty ? _editableItems : inquiry.items);
    final titleController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ویرایش اقلام استعلام قبل از انتشار',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.burgundy, fontFamily: 'Vazirmatn'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderGrey),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'عنوان قلم',
                              hintText: 'مثال: ستون باکس ۲۰',
                              filled: true,
                              fillColor: AppColors.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: unitController,
                            decoration: InputDecoration(
                              labelText: 'واحد',
                              hintText: 'متر/عدد',
                              filled: true,
                              fillColor: AppColors.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'تعداد',
                              hintText: '۱۰',
                              filled: true,
                              fillColor: AppColors.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.royalBlue, size: 30),
                          onPressed: () {
                            final title = titleController.text.trim();
                            final unit = unitController.text.trim();
                            final cleanQty = Formatters.cleanNumber(qtyController.text.trim());
                            final qty = double.tryParse(cleanQty) ?? 0;
                            if (title.isNotEmpty && unit.isNotEmpty && qty > 0) {
                              setSheetState(() {
                                tempItems.add(InquiryItem(title: title, unit: unit, quantity: qty));
                                titleController.clear();
                                unitController.clear();
                                qtyController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tempItems.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.borderGrey, height: 1),
                        itemBuilder: (context, index) {
                          final item = tempItems[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn')),
                            subtitle: Text('${item.quantity.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(fontSize: 11, fontFamily: 'Vazirmatn')),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                setSheetState(() {
                                  tempItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _editableItems = tempItems;
                          });
                          Navigator.pop(modalContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ذخیره و اعمال تغییرات', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

    return Column(
      children: [
        for (int index = 0; index < offers.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _buildBidItem(context, offers[index]),
        ]
      ],
    );
  }

  Widget _buildBidItem(BuildContext context, dynamic bid) {
    final String? rawAvatarUrl = (bid['profile_picture_url'] ?? bid['avatar_url'] ?? bid['welder_avatar']) as String?;
    final bool hasAvatar = rawAvatarUrl != null && rawAvatarUrl.trim().isNotEmpty;
    final String? fullAvatarUrl = hasAvatar
        ? (rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : 'https://api.joftojoor.com${rawAvatarUrl.startsWith('/') ? '' : '/'}$rawAvatarUrl')
        : null;

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
                  GestureDetector(
                    onTap: fullAvatarUrl != null
                        ? () {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    fullAvatarUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }
                        : null,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                      backgroundImage: fullAvatarUrl != null ? NetworkImage(fullAvatarUrl) : null,
                      child: fullAvatarUrl == null
                          ? Text(
                              (bid['initials'] ?? 'ج') as String,
                              style: const TextStyle(
                                color: AppColors.royalBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Vazirmatn',
                              ),
                            )
                          : null,
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
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${bid['projects']} پروژه موفق)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontFamily: 'Vazirmatn',
                                decoration: TextDecoration.none,
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
                      decoration: TextDecoration.none,
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
                          decoration: TextDecoration.none,
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
                          decoration: TextDecoration.none,
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
    final String? rawAvatarUrl = (bid['profile_picture_url'] ?? bid['avatar_url'] ?? bid['welder_avatar']) as String?;
    final bool hasAvatar = rawAvatarUrl != null && rawAvatarUrl.trim().isNotEmpty;
    final String? fullAvatarUrl = hasAvatar
        ? (rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : 'https://api.joftojoor.com${rawAvatarUrl.startsWith('/') ? '' : '/'}$rawAvatarUrl')
        : null;

    final String bioText = (bid['bio'] as String?)?.trim().isNotEmpty == true
        ? (bid['bio'] as String).trim()
        : 'جوشکار تاییدشده و باسابقه پلتفرم تخصصی جفت‌وجور.';

    final String homeLocation = [
      bid['home_province'] as String?,
      bid['home_city'] as String?
    ].where((s) => s != null && s.trim().isNotEmpty).join('، ');

    final List<dynamic> activeCities = (bid['active_cities'] as List<dynamic>?) ?? [];
    final List<dynamic> skillsList = (bid['skills'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Drag Handle
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

                // Scrollable Profile Content Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welder Profile Avatar Header
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 42,
                                    backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                                    backgroundImage: fullAvatarUrl != null ? NetworkImage(fullAvatarUrl) : null,
                                    child: fullAvatarUrl == null
                                        ? Text(
                                            (bid['initials'] ?? 'ج') as String,
                                            style: const TextStyle(
                                              color: AppColors.royalBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                bid['name'] as String? ?? 'جوشکار پلتفرم',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.textDark,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (homeLocation.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 15),
                                    const SizedBox(width: 4),
                                    Text(
                                      'استان / شهر: $homeLocation',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 15),
                                        const SizedBox(width: 4),
                                        Text(
                                          'امتیاز ${bid['rating'] ?? 0} از ۵',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber, fontFamily: 'Vazirmatn'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_outlined, color: Colors.green, size: 15),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bid['projects'] ?? 0} پروژه انجام‌شده',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green, fontFamily: 'Vazirmatn'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // About / Bio Section
                        const Text(
                          'درباره جوشکار و بیوگرافی:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Text(
                            bioText,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.6, fontFamily: 'Vazirmatn'),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Covered Active Cities Section
                        if (activeCities.isNotEmpty) ...[
                          const Text(
                            'شهرهای تحت پوشش فعالیت:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: activeCities.map((city) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  city.toString(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Skills & Expertise Section
                        const Text(
                          'مهارت‌ها و تخصص‌های تاییدشده:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.burgundy, fontFamily: 'Vazirmatn'),
                        ),
                        const SizedBox(height: 8),
                        skillsList.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: skillsList.map((skill) {
                                  final String skillName = skill is String ? skill : (skill['name'] ?? skill.toString());
                                  return _buildSkillChip(skillName);
                                }).toList(),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildSkillChip('جوشکاری اسکلت فلزی'),
                                  _buildSkillChip('جوشکاری برق و الکترود'),
                                  _buildSkillChip('تجهیزات ایمنی کار در ارتفاع'),
                                ],
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'امکان پذیرش مستقیم پیشنهاد جوشکار به زودی فعال خواهد شد.',
                                        style: TextStyle(fontFamily: 'Vazirmatn'),
                                      ),
                                      backgroundColor: AppColors.royalBlue,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('انتخاب این پیشنهاد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Vazirmatn')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.royalBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showCallPreviewDialog(context, bid['name'] as String? ?? 'جوشکار', bid['phone'] as String? ?? '');
                                },
                                icon: const Icon(Icons.phone_in_talk, size: 18),
                                label: const Text('تماس با جوشکار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Vazirmatn')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
        label = 'تایید شده';
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
