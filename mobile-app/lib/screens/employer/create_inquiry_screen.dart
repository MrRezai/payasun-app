import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';
import '../../models/project.dart';
import '../../utils/formatters.dart';

class CreateInquiryScreen extends StatefulWidget {
  final Inquiry? inquiryToEdit;
  final String? projectId;
  final Project? parentProject;

  const CreateInquiryScreen({
    super.key,
    this.inquiryToEdit,
    this.projectId,
    this.parentProject,
  });

  @override
  State<CreateInquiryScreen> createState() => _CreateInquiryScreenState();
}

class _CreateInquiryScreenState extends State<CreateInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorsController = TextEditingController();

  final _itemTitleController = TextEditingController();
  final _itemUnitController = TextEditingController();
  final _itemQtyController = TextEditingController();

  final Map<String, TextEditingController> _predefinedControllers = {};
  String _itemsSearchQuery = '';

  int _currentStep = 1;

  // Location states
  int? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityName;

  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;

  // Estimation type & dismissible guidance alerts
  String _estimationType = 'ROUGH'; // 'ROUGH' or 'EXACT'
  bool _showRoughAlert = true;
  bool _showExactAlert = true;
  bool _showCustomItemInput = false;
  final Map<String, String> _selectedUnits = {};

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<InquiryProvider>(context, listen: false);
      provider.loadPredefinedItems();

      if (widget.inquiryToEdit != null) {
        provider.clearManualItems();
        for (var item in widget.inquiryToEdit!.items) {
          provider.addManualItem(item.title, item.unit, item.quantity);
          final c = _getControllerForItem(item.title, item.quantity);
          c.text = Formatters.toPersianNumbers(item.quantity.toInt().toString());
        }
      }
    });

    if (widget.parentProject != null) {
      final p = widget.parentProject!;
      _selectedProvinceName = p.province;
      _selectedCityName = p.city;
      if (p.address != null && p.address!.isNotEmpty) {
        _addressController.text = p.address!;
      }
      String pDesc = p.description;
      if (pDesc.contains('متراژ زیربنا:')) {
        final match = RegExp(r'متراژ زیربنا:\s*([\d۰-۹]+)').firstMatch(pDesc);
        if (match != null) {
          _areaController.text = Formatters.cleanNumber(match.group(1)!.trim());
        }
      }
      if (pDesc.contains('تعداد طبقات:')) {
        final match = RegExp(r'تعداد طبقات:\s*([\d۰-۹]+)').firstMatch(pDesc);
        if (match != null) {
          _floorsController.text = Formatters.cleanNumber(match.group(1)!.trim());
        }
      }
    }

    if (widget.inquiryToEdit != null) {
      final inq = widget.inquiryToEdit!;
      _titleController.text = inq.title;
      _addressController.text = inq.address ?? '';
      _selectedProvinceName = inq.province;
      _selectedCityName = inq.city;
      _estimationType = inq.estimationType ?? 'ROUGH';

      // Parse extra details from description if embedded
      String rawDesc = inq.description;
      if (_addressController.text.isEmpty && rawDesc.contains('محل اجرای دقیق:')) {
        final match = RegExp(r'محل اجرای دقیق:\s*([^|)\n]+)').firstMatch(rawDesc);
        if (match != null) {
          _addressController.text = match.group(1)!.trim();
        }
      }

      if (rawDesc.contains('متراژ زیربنا:')) {
        final match = RegExp(r'متراژ زیربنا:\s*([\d۰-۹]+)').firstMatch(rawDesc);
        if (match != null) {
          _areaController.text = Formatters.cleanNumber(match.group(1)!.trim());
        }
      }

      if (rawDesc.contains('تعداد طبقات:')) {
        final match = RegExp(r'تعداد طبقات:\s*([\d۰-۹]+)').firstMatch(rawDesc);
        if (match != null) {
          _floorsController.text = Formatters.cleanNumber(match.group(1)!.trim());
        }
      }

      if (rawDesc.contains('(محل اجرای دقیق:') || rawDesc.contains('(متراژ زیربنا:') || rawDesc.contains('(تعداد طبقات:')) {
        _descController.text = rawDesc.replaceAll(RegExp(r'\s*\((محل اجرای دقیق|متراژ زیربنا|تعداد طبقات)[^)]*\)'), '').trim();
      } else {
        _descController.text = rawDesc;
      }

      if (inq.hasBlueprint) {
        final provider = Provider.of<InquiryProvider>(context, listen: false);
        provider.setHasBlueprint(true);
        provider.loadExistingBlueprintUrls(inq.blueprintUrl);
      }
    }
  }

  TextEditingController _getControllerForItem(String title, double currentQty) {
    if (!_predefinedControllers.containsKey(title)) {
      _predefinedControllers[title] = TextEditingController(
        text: Formatters.toPersianNumbers(currentQty > 0 ? currentQty.toInt().toString() : '0'),
      );
    }
    return _predefinedControllers[title]!;
  }

  void _updateItemQuantity(String title, String unit, double delta) {
    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final controller = _getControllerForItem(title, 0);
    final cleanText = Formatters.cleanNumber(controller.text.trim());
    double current = double.tryParse(cleanText) ?? 0.0;
    double nextVal = current + delta;
    if (nextVal < 0) nextVal = 0;

    controller.text = Formatters.toPersianNumbers(nextVal.toInt().toString());
    _syncManualItemInProvider(provider, title, unit, nextVal);
  }

  void _setItemQuantityDirectly(String title, String unit, String rawInput) {
    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final cleanText = Formatters.cleanNumber(rawInput.trim());
    double qty = double.tryParse(cleanText) ?? 0.0;
    if (qty < 0) qty = 0;

    _syncManualItemInProvider(provider, title, unit, qty);
  }

  void _syncManualItemInProvider(InquiryProvider provider, String title, String unit, double qty) {
    int existingIdx = provider.manualItems.indexWhere((i) => i.title == title);
    if (qty > 0) {
      if (existingIdx >= 0) {
        provider.manualItems[existingIdx] = InquiryItem(title: title, unit: unit, quantity: qty);
      } else {
        provider.addManualItem(title, unit, qty);
      }
    } else {
      if (existingIdx >= 0) {
        provider.removeManualItem(existingIdx);
      }
    }
    setState(() {});
  }

  Future<void> _loadProvinces() async {
    if (mounted) setState(() => _isLoadingProvinces = true);
    try {
      final list = await _apiService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingProvinces = false;

          if (widget.inquiryToEdit != null && _selectedProvinceName != null) {
            final matchingProv = _provinces.firstWhere(
              (p) => p['name'] == _selectedProvinceName,
              orElse: () => null,
            );
            if (matchingProv != null) {
              _selectedProvinceId = matchingProv['id'] as int;
              _loadCitiesForEditing(_selectedProvinceId!);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _loadCitiesForEditing(int provinceId) async {
    if (mounted) setState(() => _isLoadingCities = true);
    try {
      final cities = await _apiService.fetchCities(provinceId);
      if (mounted) {
        setState(() {
          _citiesOfSelectedProvince = cities;
          _isLoadingCities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  void _onProvinceSelected(int provId, String provName) async {
    setState(() {
      _selectedProvinceId = provId;
      _selectedProvinceName = provName;
      _selectedCityName = null;
      _citiesOfSelectedProvince = [];
      _isLoadingCities = true;
    });

    try {
      final cities = await _apiService.fetchCities(provId);
      if (mounted) {
        setState(() {
          _citiesOfSelectedProvince = cities;
          _isLoadingCities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _predefinedControllers.forEach((_, c) => c.dispose());
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _floorsController.dispose();
    _itemTitleController.dispose();
    _itemUnitController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.parentProject == null) {
      if (_selectedProvinceName == null || _selectedProvinceName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً استان محل پروژه را انتخاب کنید.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedCityName == null || _selectedCityName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً شهر محل پروژه را انتخاب کنید.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() {
      _currentStep = 2;
    });
  }

  void _submit() {
    final provider = Provider.of<InquiryProvider>(context, listen: false);

    if (provider.hasBlueprint) {
      if (provider.selectedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً حداقل یک فایل نقشه بارگذاری کنید.'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      if (provider.manualItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً حداقل یک قلم کالا با تعداد مشخص تعیین کنید.'), backgroundColor: AppColors.amberOrange),
        );
        return;
      }
    }

    _showSummaryConfirmationBottomSheet(provider);
  }

  void _showSummaryConfirmationBottomSheet(InquiryProvider provider) {
    final bool hasBlueprint = provider.hasBlueprint;

    String estimationLabel = '';
    Color estimationBadgeBg = AppColors.royalBlue.withValues(alpha: 0.1);
    Color estimationBadgeTextColor = AppColors.royalBlue;

    if (!hasBlueprint) {
      estimationLabel = 'برآورد دقیق (اقلام دستی)';
      estimationBadgeBg = AppColors.royalBlue.withValues(alpha: 0.1);
      estimationBadgeTextColor = AppColors.royalBlue;
    } else if (_estimationType == 'EXACT') {
      estimationLabel = 'محاسبه دقیق (پلان + سازه)';
      estimationBadgeBg = Colors.purple.withValues(alpha: 0.12);
      estimationBadgeTextColor = Colors.purple;
    } else {
      estimationLabel = 'برآورد حدودی (نقشه معماری)';
      estimationBadgeBg = Colors.amber.withValues(alpha: 0.15);
      estimationBadgeTextColor = AppColors.amberOrange;
    }

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
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Handle Bar
                const SizedBox(height: 12),
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

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: AppColors.amberOrange, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'پیش‌نمایش و تأیید نهایی اطلاعات استعلام',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.royalBlue,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderGrey),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Badge Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('عنوان استعلام:', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn')),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: estimationBadgeBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      estimationLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: estimationBadgeTextColor,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _titleController.text.trim(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Location & Project Specs Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.amberOrange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'استان و شهر: ${_selectedProvinceName ?? ''}، ${_selectedCityName ?? ''}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_addressController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 26),
                                  child: Text(
                                    'محل اجرای دقیق: ${_addressController.text.trim()}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                  ),
                                ),
                              ],
                              if (_areaController.text.trim().isNotEmpty || _floorsController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: AppColors.borderGrey),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.architecture_outlined, size: 18, color: AppColors.royalBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'متراژ زیربنا: ${_areaController.text.trim().isNotEmpty ? '${Formatters.toPersianNumbers(_areaController.text.trim())} مترمربع' : 'نامشخص'}  |  تعداد طبقات: ${_floorsController.text.trim().isNotEmpty ? '${Formatters.toPersianNumbers(_floorsController.text.trim())} طبقه' : 'نامشخص'}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Selected Items or Blueprint Files Detail Box
                        const Text('اطلاعات اقلام و مدارک آپلود شده:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                        const SizedBox(height: 8),
                        if (hasBlueprint)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_done_outlined, size: 20, color: AppColors.royalBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تعداد ${Formatters.toPersianNumbers(provider.selectedFiles.length.toString())} فایل نقشه پیوست شده است:',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: provider.selectedFiles.map((file) {
                                    return _buildFileChip(context, file);
                                  }).toList(),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: provider.manualItems.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.royalBlue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${item.title}: ${Formatters.toPersianNumbers(item.quantity.toInt().toString())} ${item.unit}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        if (_descController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text('توضیحات تکمیلی پروژه:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderGrey),
                            ),
                            child: Text(
                              _descController.text.trim(),
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'اطلاعات و نشانی دقیق شما با حفظ محرمانگی و فقط جهت برآورد در سیستم استفاده می‌شود.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Fixed Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(top: BorderSide(color: AppColors.borderGrey, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderGrey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'ویرایش و بازگشت',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _performFinalSubmit();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'تأیید نهایی و انتشار استعلام',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ),
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

  Future<void> _performFinalSubmit() async {
    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    String finalDescription = _descController.text.trim();
    final addressText = _addressController.text.trim();
    final areaText = _areaController.text.trim();
    final floorsText = _floorsController.text.trim();
    List<String> extraDetails = [];
    if (addressText.isNotEmpty) extraDetails.add('محل اجرای دقیق: $addressText');
    if (areaText.isNotEmpty) extraDetails.add('متراژ زیربنا: ${Formatters.toPersianNumbers(areaText)} مترمربع');
    if (floorsText.isNotEmpty) extraDetails.add('تعداد طبقات: ${Formatters.toPersianNumbers(floorsText)} طبقه');
    if (extraDetails.isNotEmpty) {
      final extraStr = extraDetails.join(' | ');
      finalDescription = finalDescription.isNotEmpty
          ? '$finalDescription ($extraStr)'
          : extraStr;
    }

    final targetProjectId = widget.projectId ?? widget.parentProject?.id;

    final result = widget.inquiryToEdit != null
        ? await provider.updateInquiry(
            token: auth.token,
            inquiryId: widget.inquiryToEdit!.id,
            title: _titleController.text,
            description: finalDescription,
            city: _selectedCityName!,
            province: _selectedProvinceName!,
          )
        : await provider.submitInquiry(
            token: auth.token,
            projectId: targetProjectId,
            title: _titleController.text,
            description: finalDescription,
            city: _selectedCityName!,
            province: _selectedProvinceName!,
            address: addressText,
            estimationType: _estimationType,
          );

    if (result != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.white,
            title: const Column(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 54),
                SizedBox(height: 12),
                Text(
                  'استعلام با موفقیت ثبت شد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              provider.hasBlueprint
                  ? 'برآورد شما پس از بررسی و تایید توسط کارشناسان در بخش استعلام‌ها قرار خواهد گرفت.'
                  : 'اقلام استعلام شما ثبت و برای جوشکاران منتشر شد.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.6, fontFamily: 'Vazirmatn'),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, result.projectId ?? targetProjectId ?? true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('متوجه شدم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'خطا در ثبت استعلام'), backgroundColor: Colors.red),
      );
    }
  }

  void _showProvincePickerBottomSheet() {
    String searchFilter = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cleanFilter = searchFilter.trim();
            final filteredProvinces = _provinces.where((prov) {
              final name = prov['name'] as String;
              return cleanFilter.isEmpty || name.contains(cleanFilter);
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text('انتخاب استان پروژه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn')),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      onChanged: (val) {
                        setSheetState(() {
                          searchFilter = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'جستجوی نام استان...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.amberOrange),
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _isLoadingProvinces
                          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                          : filteredProvinces.isEmpty
                              ? const Center(child: Text('هیچ استانی یافت نشد.', style: TextStyle(color: AppColors.textMuted)))
                              : ListView.builder(
                                  itemCount: filteredProvinces.length,
                                  itemBuilder: (context, index) {
                                    final prov = filteredProvinces[index];
                                    final isSelected = prov['name'] == _selectedProvinceName;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.royalBlue.withValues(alpha: 0.08) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.5), width: 1.5)
                                            : Border.all(color: Colors.transparent, width: 1.5),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          prov['name'] as String,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                            fontSize: 14,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.amberOrange, size: 20) : null,
                                        onTap: () {
                                          _onProvinceSelected(prov['id'] as int, prov['name'] as String);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
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

  void _showCityPickerBottomSheet() {
    if (_selectedProvinceName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا استان را انتخاب کنید.')),
      );
      return;
    }

    String searchFilter = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cleanFilter = searchFilter.trim();
            final filteredCities = _citiesOfSelectedProvince.where((city) {
              final name = city['name'] as String;
              return cleanFilter.isEmpty || name.contains(cleanFilter);
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.borderGrey, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text('انتخاب شهر ($_selectedProvinceName)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn')),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      onChanged: (val) {
                        setSheetState(() {
                          searchFilter = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'جستجوی نام شهر...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.amberOrange),
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _isLoadingCities
                          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                          : filteredCities.isEmpty
                              ? const Center(child: Text('شهری یافت نشد.', style: TextStyle(color: AppColors.textMuted)))
                              : ListView.builder(
                                  itemCount: filteredCities.length,
                                  itemBuilder: (context, index) {
                                    final city = filteredCities[index];
                                    final isSelected = city['name'] == _selectedCityName;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.royalBlue.withValues(alpha: 0.08) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.5), width: 1.5)
                                            : Border.all(color: Colors.transparent, width: 1.5),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          city['name'] as String,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                            fontSize: 14,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.amberOrange, size: 20) : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedCityName = city['name'] as String;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
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

  void _showUnitPickerBottomSheet() {
    final units = ['عدد', 'متر', 'کیلوگرم', 'شاخه', 'تن', 'بند', 'ساعت', 'پروژه‌ای'];
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
          child: Container(
            height: 350,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Center(
                  child: Text('انتخاب واحد محاسبه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn')),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderGrey, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: units.length,
                    itemBuilder: (context, idx) {
                      final u = units[idx];
                      final isSelected = _itemUnitController.text == u;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.royalBlue.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.5), width: 1.5)
                              : Border.all(color: Colors.transparent, width: 1.5),
                        ),
                        child: ListTile(
                          title: Text(
                            u,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                              fontSize: 14,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.amberOrange, size: 20) : null,
                          onTap: () {
                            setState(() {
                              _itemUnitController.text = u;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      {'title': 'مشخصات اولیه', 'subtitle': 'عنوان و موقعیت'},
      {'title': 'اقلام و نقشه', 'subtitle': 'اقلام یا فایل‌‌ها'},
    ];

    final currentIdx = _currentStep - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step 1
          _buildSingleStepItem(
            stepNumber: 1,
            title: steps[0]['title']!,
            subtitle: steps[0]['subtitle']!,
            isActive: currentIdx == 0,
            isCompleted: currentIdx > 0,
          ),

          // Connecting line
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: currentIdx > 0 ? AppColors.royalBlue : AppColors.borderGrey,
            ),
          ),

          // Step 2
          _buildSingleStepItem(
            stepNumber: 2,
            title: steps[1]['title']!,
            subtitle: steps[1]['subtitle']!,
            isActive: currentIdx == 1,
            isCompleted: currentIdx > 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStepItem({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.royalBlue
                : (isActive ? AppColors.royalBlue.withValues(alpha: 0.08) : AppColors.lightGrey),
            border: Border.all(
              color: isCompleted || isActive ? AppColors.royalBlue : AppColors.borderGrey,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.white, size: 15)
                : Text(
                    Formatters.toPersianNumbers(stepNumber.toString()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.royalBlue : AppColors.textMuted,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive || isCompleted ? AppColors.textDark : AppColors.textMuted,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getFileIconData(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
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

  Color _getFileIconColor(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
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

  bool _isImageFile(BlueprintFile file) {
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext) && file.bytes.isNotEmpty;
  }

  Widget _buildFileChip(BuildContext context, BlueprintFile file) {
    final bool canPreview = _isImageFile(file);
    final ext = file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'FILE';

    IconData fileIcon = Icons.insert_drive_file_outlined;
    Color iconColor = AppColors.royalBlue;

    if (canPreview) {
      fileIcon = Icons.image_outlined;
      iconColor = AppColors.burgundy;
    } else if (ext == 'PDF') {
      fileIcon = Icons.picture_as_pdf_outlined;
      iconColor = Colors.redAccent;
    } else if (['DWG', 'DXF', 'DWF', 'RVT', 'SKP', 'IFC', 'PLN'].contains(ext)) {
      fileIcon = Icons.architecture_outlined;
      iconColor = AppColors.amberOrange;
    } else if (['ZIP', 'RAR', '7Z'].contains(ext)) {
      fileIcon = Icons.folder_zip_outlined;
      iconColor = Colors.purple;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canPreview ? () => _showFilePreviewDialog(context, file) : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: canPreview ? iconColor.withValues(alpha: 0.1) : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canPreview ? iconColor.withValues(alpha: 0.4) : AppColors.borderGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fileIcon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canPreview) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove_red_eye_outlined, size: 12, color: iconColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilePreviewDialog(BuildContext context, BlueprintFile file) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.royalBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderGrey),

              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: Image.memory(
                      Uint8List.fromList(file.bytes),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('خطا در پیش‌نمایش تصویر', style: TextStyle(fontFamily: 'Vazirmatn')),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بستن پیش‌نمایش', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InquiryProvider>(context);

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
            onPressed: () {
              if (_currentStep == 2) {
                setState(() => _currentStep = 1);
              } else {
                Navigator.pop(context);
              }
            },
            tooltip: 'بازگشت',
          ),
          title: Text(
            widget.inquiryToEdit != null ? 'ویرایش استعلام' : 'استعلام جدید',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.royalBlue,
              fontFamily: 'Vazirmatn',
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),

                if (_currentStep == 1) ...[
                  _buildSectionHeader(widget.parentProject != null ? 'اطلاعات استعلام' : 'مشخصات استعلام جدید'),
                  const SizedBox(height: 14),

                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: 'عنوان استعلام *',
                    hint: 'مثال: جوشکاری اسکلت فلزی ساختمان مسکونی ۴ طبقه',
                    prefixIcon: Icons.edit_note,
                    validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً عنوان را وارد کنید' : null,
                  ),
                  const SizedBox(height: 12),

                  // Conditional Location display
                  if (widget.parentProject != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.amberOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'موقعیت مکانی پروژه: ${_selectedProvinceName ?? ''}، ${_selectedCityName ?? ''}${_addressController.text.isNotEmpty ? ' (${_addressController.text})' : ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Location Selector Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showProvincePickerBottomSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedProvinceName != null ? AppColors.royalBlue.withValues(alpha: 0.5) : AppColors.borderGrey,
                                    width: _selectedProvinceName != null ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _selectedProvinceName != null
                                        ? Text(
                                            _selectedProvinceName!,
                                            style: const TextStyle(
                                              color: AppColors.textDark,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Vazirmatn',
                                            ),
                                          )
                                        : RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal,
                                                fontFamily: 'Vazirmatn',
                                              ),
                                              children: [
                                                TextSpan(text: 'استان پروژه'),
                                                TextSpan(
                                                  text: ' *',
                                                  style: TextStyle(
                                                    color: AppColors.burgundy,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Vazirmatn',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.amberOrange),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _selectedProvinceId == null ? null : _showCityPickerBottomSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: _selectedProvinceId == null ? AppColors.lightGrey : AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedCityName != null ? AppColors.royalBlue.withValues(alpha: 0.5) : AppColors.borderGrey,
                                    width: _selectedCityName != null ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedCityName ?? 'شهر پروژه',
                                      style: TextStyle(
                                        color: _selectedCityName != null ? AppColors.textDark : AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: _selectedCityName != null ? FontWeight.bold : FontWeight.normal,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: AppColors.amberOrange),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Exact Address & Execution Location Field
                    _buildTextField(
                      controller: _addressController,
                      label: 'محل اجرای دقیق پروژه (آدرس / محدوده) *',
                      hint: 'مثال: خیابان شریعتی، کوچه ۱۴، پلاک ۲۵ (یا محدوده دقیق کارگاه)',
                      prefixIcon: Icons.place_outlined,
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً محل اجرای دقیق پروژه را وارد کنید' : null,
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'نشانی که شما وارد می‌کنید در اختیار هیچ فردی قرار داده نمی‌شود.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Area & Floor Count Row (Mandatory in Inquiry stage)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _areaController,
                          label: 'متراژ زیربنا *',
                          hint: 'مثال: ۲۰۰',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'لطفاً متراژ را وارد کنید';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _floorsController,
                          label: 'تعداد طبقات *',
                          hint: 'مثال: ۵',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'لطفاً تعداد طبقات را وارد کنید';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _areaController,
                    builder: (context, value, child) {
                      final clean = Formatters.cleanNumber(value.text);
                      final area = double.tryParse(clean) ?? 0.0;
                      final deposit = (area * 1000).toInt();
                      if (area <= 0) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: AppColors.royalBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'مبلغ بیعانه برآورد شده (متری ۱,۰۰۰ تومان): ${Formatters.formatPrice(deposit)} تومان',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description Field (Optional)
                  _buildTextField(
                    controller: _descController,
                    label: 'توضیحات تکمیلی پروژه (اختیاری)',
                    hint: 'توضیحات درباره زمان شروع، جزئیات جوشکاری و شرایط کارگاه...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: null,
                  ),
                  const SizedBox(height: 18),

                  // Toggle selector card
                  _buildToggleCard(provider),
                ] else ...[
                  // Step 2 Content
                  if (provider.hasBlueprint)
                    _buildBlueprintUploadArea(provider)
                  else
                    _buildManualItemsArea(provider),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.borderGrey, width: 0.5)),
          ),
          child: SafeArea(
            child: _currentStep == 1
                ? SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _goToStep2,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ادامه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep = 1),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderGrey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('مرحله قبل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: provider.isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5))
                                : Text(
                                    widget.inquiryToEdit != null ? 'ویرایش و اصلاح استعلام' : 'ثبت و ارسال استعلام',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.amberOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.royalBlue,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final bool hasStar = label.contains('*');
    final String cleanLabel = label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textDark,
              fontFamily: 'Vazirmatn',
            ),
            children: [
              TextSpan(text: cleanLabel),
              if (hasStar)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final bool hasContent = value.text.trim().isNotEmpty;
            return TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              inputFormatters: [PersianDigitsFormatter(keepText: true)],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontFamily: 'Vazirmatn',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.amberOrange, size: 20) : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasContent ? AppColors.royalBlue.withValues(alpha: 0.5) : AppColors.borderGrey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToggleCard(InquiryProvider provider) {
    final bool hasBlueprint = provider.hasBlueprint;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => provider.setHasBlueprint(false),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    !hasBlueprint ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: !hasBlueprint ? AppColors.amberOrange : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'انتخاب اقلام از لیست آماده (برآورد دستی)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'تنظیم سریع و آسان مقادیر اقلام از لیست اقلام تاییدشده پلتفرم.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGrey),
          InkWell(
            onTap: () => provider.setHasBlueprint(true),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    hasBlueprint ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: hasBlueprint ? AppColors.amberOrange : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دارای نقشه و پلان معماری (ارسال نقشه برای محاسبه)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'فایل‌های نقشه معماری را آپلود کنید تا اقلام توسط کارشناسان استخراج شوند.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintUploadArea(InquiryProvider provider) {
    int totalFilesCount = provider.selectedFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('بارگذاری نقشه و مدارک پروژه'),
        const SizedBox(height: 12),

        // Radio Button Selector Row for ROUGH vs EXACT blueprint calculation
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _estimationType = 'ROUGH');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _estimationType == 'ROUGH' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _estimationType == 'ROUGH' ? AppColors.royalBlue : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'برآورد حدودی',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.borderGrey),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _estimationType = 'EXACT');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _estimationType == 'EXACT' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _estimationType == 'EXACT' ? AppColors.royalBlue : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'محاسبه دقیق',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Dismissible Alert Banner based on active selection
        if (_estimationType == 'ROUGH' && _showRoughAlert)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.amberOrange, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'لطفاً صرفاً نقشه معماری شامل پلانها، نماها و مقاطع آپلود فرمایید. نیاز به نقشههای اجرایی و سازه نمیباشد.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 12, height: 1.5, fontFamily: 'Vazirmatn'),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _showRoughAlert = false),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

        if (_estimationType == 'EXACT' && _showExactAlert)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.amberOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.royalBlue, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'لطفاً برای محاسبه دقیق، نقشه معماری شامل پلانها، نماها و مقاطع به همراه دفترچه محاسبات و نقشههای اجرایی را آپلود فرمایید.',
                    style: TextStyle(color: AppColors.textDark, fontSize: 12, height: 1.5, fontFamily: 'Vazirmatn'),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _showExactAlert = false),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final ok = await provider.pickBlueprintFiles();
              if (!ok && provider.errorMessage != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage!), backgroundColor: Colors.red),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.amberOrange),
                  const SizedBox(height: 10),
                  Text(
                    totalFilesCount == 0
                        ? 'انتخاب و آپلود فایل‌های نقشه و پلان (امکان انتخاب همزمان چند فایل)'
                        : 'افزودن فایل‌های نقشه بیشتر...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'فرمت‌های مجاز: DWG, DXF, DWF, PDF, ZIP, RAR, JPG, PNG (حداکثر ${Formatters.toPersianNumbers('10')} فایل برای هر استعلام)',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (provider.selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 14),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.selectedFiles.length,
            itemBuilder: (context, index) {
              final file = provider.selectedFiles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIconData(file.name),
                      color: _getFileIconColor(file.name),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () => provider.removeSelectedFile(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildManualItemsArea(InquiryProvider provider) {
    final predefinedItems = provider.predefinedItems;
    final cleanSearch = _itemsSearchQuery.trim();

    final filteredItems = predefinedItems.where((item) {
      return cleanSearch.isEmpty || item.title.contains(cleanSearch);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('انتخاب اقلام و تعیین تعداد'),
        const SizedBox(height: 8),
        const Text(
          'لطفاً اقلام مورد نیاز خود را از لیست زیر با استفاده از دکمه‌های + و - انتخاب یا مقدار آن را وارد کنید:',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4, fontFamily: 'Vazirmatn'),
        ),
        const SizedBox(height: 12),

        // Search Bar for Predefined Supply Items
        TextField(
          onChanged: (val) {
            setState(() {
              _itemsSearchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'جستجوی نام قلم کالا (مثلاً آرگون، تیرآهن)...',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
            prefixIcon: const Icon(Icons.search, color: AppColors.amberOrange),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
          ),
        ),
        const SizedBox(height: 12),

        // Render Predefined Supply Items List with Steppers
        if (filteredItems.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            itemBuilder: (context, idx) {
              final item = filteredItems[idx];
              final String itemTitle = item.title;
              final String itemUnit = item.unit;
              final List<String> unitsList = itemUnit.split(RegExp(r'[,،]')).map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
              final String defaultUnit = unitsList.isNotEmpty ? unitsList.first : 'عدد';
              final String currentUnit = _selectedUnits[itemTitle] ?? defaultUnit;

              final existingItem = provider.manualItems.firstWhere(
                (i) => i.title == item.title,
                orElse: () => InquiryItem(title: item.title, unit: currentUnit, quantity: 0),
              );
              final controller = _getControllerForItem(item.title, existingItem.quantity);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: existingItem.quantity > 0 ? AppColors.royalBlue.withValues(alpha: 0.5) : AppColors.borderGrey,
                    width: existingItem.quantity > 0 ? 1.5 : 1,
                  ),
                ),
                color: existingItem.quantity > 0 ? AppColors.royalBlue.withValues(alpha: 0.03) : AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                            ),
                            const SizedBox(height: 4),
                            if (unitsList.length > 1) ...[
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: unitsList.map((u) {
                                  final isSel = currentUnit == u;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedUnits[item.title] = u;
                                      });
                                      if (existingItem.quantity > 0) {
                                        _syncManualItemInProvider(provider, item.title, u, existingItem.quantity);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.royalBlue : AppColors.lightGrey,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSel ? AppColors.royalBlue : AppColors.borderGrey,
                                        ),
                                      ),
                                      child: Text(
                                        u,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          color: isSel ? AppColors.white : AppColors.textDark,
                                          fontFamily: 'Vazirmatn',
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              Text(
                                'واحد: $currentUnit',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Stepper Control: [-] [Editable Number Input] [+]
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _updateItemQuantity(item.title, currentUnit, -1),
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Icon(Icons.remove, size: 16, color: AppColors.royalBlue),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [PersianDigitsFormatter(keepText: true)],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => _setItemQuantityDirectly(item.title, currentUnit, val),
                              ),
                            ),
                            InkWell(
                              onTap: () => _updateItemQuantity(item.title, currentUnit, 1),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Icon(Icons.add, size: 16, color: AppColors.royalBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 14),

        // Custom Item Drawer toggle
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showCustomItemInput = !_showCustomItemInput;
            });
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderGrey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(_showCustomItemInput ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 18, color: AppColors.amberOrange),
          label: Text(
            _showCustomItemInput ? 'بستن افزودن قلم سفارشی' : 'افزودن قلم کالا یا خدمات سفارشی خارج از لیست...',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
          ),
        ),

        if (_showCustomItemInput) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              children: [
                _buildTextField(
                  controller: _itemTitleController,
                  label: 'عنوان کالا یا خدمات اختصاصی',
                  hint: 'مثال: جوشکاری نرده حفاظ',
                  prefixIcon: Icons.handyman_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _showUnitPickerBottomSheet,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _itemUnitController,
                            label: 'واحد',
                            hint: 'انتخاب واحد...',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _itemQtyController,
                        label: 'تعداد/مقدار',
                        hint: '۱۰',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final title = _itemTitleController.text.trim();
                      final unit = _itemUnitController.text.trim();
                      final cleanQty = Formatters.cleanNumber(_itemQtyController.text.trim());
                      final qty = double.tryParse(cleanQty) ?? 0.0;

                      if (title.isEmpty || unit.isEmpty || qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لطفاً مشخصات قلم کالا را به طور صحیح وارد کنید.'), backgroundColor: AppColors.amberOrange),
                        );
                        return;
                      }

                      provider.addManualItem(title, unit, qty);
                      _itemTitleController.clear();
                      _itemUnitController.clear();
                      _itemQtyController.clear();
                      setState(() {
                        _showCustomItemInput = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ثبت قلم سفارشی', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
