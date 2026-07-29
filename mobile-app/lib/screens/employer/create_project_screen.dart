import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/project.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

class LocalProjectImage {
  final String name;
  final List<int> bytes;
  final String? path;

  LocalProjectImage({required this.name, required this.bytes, this.path});
}

class CreateProjectScreen extends StatefulWidget {
  final Project? projectToEdit;

  const CreateProjectScreen({super.key, this.projectToEdit});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorsController = TextEditingController();

  // Geo Location states
  int? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityName;

  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isSubmitting = false;
  bool _showInfoAlert = true;

  final List<String> _existingImageUrls = [];
  final List<LocalProjectImage> _newImages = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    if (widget.projectToEdit != null) {
      final p = widget.projectToEdit!;
      _titleController.text = p.title;
      _addressController.text = p.address ?? '';
      _selectedProvinceName = p.province;
      _selectedCityName = p.city;
      _existingImageUrls.addAll(p.imageUrls);

      String rawDesc = p.description;
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

      if (rawDesc.contains('(متراژ زیربنا:') || rawDesc.contains('(تعداد طبقات:')) {
        _descriptionController.text = rawDesc.replaceAll(RegExp(r'\s*\((متراژ زیربنا|تعداد طبقات)[^)]*\)'), '').trim();
      } else {
        _descriptionController.text = rawDesc;
      }
    }
  }

  Future<void> _loadProvinces() async {
    if (mounted) setState(() => _isLoadingProvinces = true);
    try {
      final list = await _apiService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingProvinces = false;

          if (widget.projectToEdit != null && _selectedProvinceName != null) {
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
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
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

  Future<void> _pickImages() async {
    int totalCount = _existingImageUrls.length + _newImages.length;
    if (totalCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حداکثر ${Formatters.toPersianNumbers('10')} تصویر می‌توانید اضافه کنید.',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: AppColors.amberOrange,
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (totalCount >= 10) break;
          if (file.name.isEmpty) continue;

          List<int>? bytes = file.bytes;
          String? filePath;
          if (!kIsWeb) {
            try {
              filePath = file.path;
            } catch (_) {}
          }

          if (!kIsWeb && (bytes == null || bytes.isEmpty) && filePath != null && filePath.isNotEmpty) {
            try {
              final f = io.File(filePath);
              if (await f.exists()) {
                bytes = await f.readAsBytes();
              }
            } catch (_) {}
          }

          if (bytes != null && bytes.isNotEmpty) {
            setState(() {
              _newImages.add(LocalProjectImage(
                name: file.name,
                bytes: bytes!,
                path: filePath,
              ));
            });
            totalCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _floorsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvinceName == null || _selectedProvinceName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً استان پروژه را انتخاب کنید.', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Vazirmatn')), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCityName == null || _selectedCityName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شهر پروژه را انتخاب کنید.', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Vazirmatn')), backgroundColor: Colors.red),
      );
      return;
    }

    String finalDescription = _descriptionController.text.trim();
    final areaText = _areaController.text.trim();
    final floorsText = _floorsController.text.trim();
    List<String> extraDetails = [];
    if (areaText.isNotEmpty) extraDetails.add('متراژ زیربنا: ${Formatters.toPersianNumbers(areaText)} مترمربع');
    if (floorsText.isNotEmpty) extraDetails.add('تعداد طبقات: ${Formatters.toPersianNumbers(floorsText)} طبقه');
    if (extraDetails.isNotEmpty) {
      final extraStr = extraDetails.join(' | ');
      finalDescription = finalDescription.isNotEmpty
          ? '$finalDescription ($extraStr)'
          : extraStr;
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<InquiryProvider>(context, listen: false);

    bool isEdit = widget.projectToEdit != null;

    if (isEdit) {
      final updated = await provider.updateProject(
        token: auth.token,
        projectId: widget.projectToEdit!.id,
        title: _titleController.text.trim(),
        description: finalDescription,
        city: _selectedCityName!,
        province: _selectedProvinceName!,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        existingImageUrls: _existingImageUrls,
        newImageBytesList: _newImages.map((e) => e.bytes).toList(),
        newImageFilenames: _newImages.map((e) => e.name).toList(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (updated != null && mounted) {
        await _showSuccessDialog('اطلاعات پروژه با موفقیت ویرایش شد.');
        if (mounted) Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'خطا در ویرایش پروژه', textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Vazirmatn')), backgroundColor: Colors.red),
        );
      }
    } else {
      final created = await provider.createProject(
        token: auth.token,
        title: _titleController.text.trim(),
        description: finalDescription,
        city: _selectedCityName!,
        province: _selectedProvinceName!,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        imageBytesList: _newImages.map((e) => e.bytes).toList(),
        imageFilenames: _newImages.map((e) => e.name).toList(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (created != null && mounted) {
        await _showSuccessDialog('پروژه جدید با موفقیت ثبت شد!');
        if (mounted) Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'خطا در ثبت پروژه', textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Vazirmatn')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
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
                'ثبت با موفقیت انجام شد',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.royalBlue,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.6,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'متوجه شدم',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                        decoration: BoxDecoration(
                          color: AppColors.borderGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'انتخاب استان پروژه',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                      ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
                              ? const Center(
                                  child: Text(
                                    'هیچ استانی یافت نشد.',
                                    style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                                  ),
                                )
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
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle, color: AppColors.amberOrange, size: 20)
                                            : null,
                                        onTap: () {
                                          _onProvinceSelected(
                                            prov['id'] as int,
                                            prov['name'] as String,
                                          );
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
        const SnackBar(
          content: Text('لطفاً ابتدا استان را انتخاب کنید.', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Vazirmatn')),
          backgroundColor: AppColors.amberOrange,
        ),
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
                        decoration: BoxDecoration(
                          color: AppColors.borderGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'انتخاب شهر ($_selectedProvinceName)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                      ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
                              ? const Center(child: Text('شهری یافت نشد.', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn')))
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
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle, color: AppColors.amberOrange, size: 20)
                                            : null,
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

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.amberOrange),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.royalBlue,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPickerButton({
    required String title,
    required String? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final bool hasStar = title.contains('*');
    final String cleanTitle = title.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
            children: [
              TextSpan(text: cleanTitle),
              if (hasStar)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.amberOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? 'انتخاب کنید...',
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null ? AppColors.textDark : AppColors.textMuted,
                      fontFamily: 'Vazirmatn',
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.amberOrange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontWeight: FontWeight.w300, fontSize: 12, fontFamily: 'Vazirmatn'),
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
        borderSide: const BorderSide(color: AppColors.borderGrey),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.projectToEdit != null;
    int totalImagesCount = _existingImageUrls.length + _newImages.length;
    String persianCountText = Formatters.toPersianNumbers('$totalImagesCount از ۱۰');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 1),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.borderGrey, width: 0.5),
              ),
            ),
            child: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 18),
                onPressed: () => Navigator.pop(context),
                tooltip: 'بازگشت',
              ),
              title: Text(
                isEdit ? 'ویرایش اطلاعات پروژه' : 'ثبت پروژه جدید',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.royalBlue,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              centerTitle: false,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dismissible Guidance Banner with Close X Button
                if (_showInfoAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
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
                            'پروژه خود را مشخص کنید (مانند متراژ و تعداد طبقات). نیازی به تایید ادمین نیست و می‌توانید در مراحل بعد استعلام‌های خود را ایجاد کنید.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                              height: 1.5,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showInfoAlert = false),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section 1: Main Info
                _buildSectionTitle('اطلاعات اصلی پروژه', icon: Icons.business_center_outlined),
                
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                    children: [
                      TextSpan(text: 'عنوان پروژه'),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('مثلاً: پروژه ۳۰۰ متری ۲ طبقه مسکونی', prefixIcon: Icons.edit_note),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'لطفاً عنوان پروژه را وارد کنید.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Optional Area and Floors Row in Project Creation
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('متراژ زیربنا (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _areaController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('مثال: ۲۰۰', prefixIcon: Icons.straighten),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تعداد طبقات (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _floorsController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('مثال: ۵', prefixIcon: Icons.layers_outlined),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 2: Location
                _buildSectionTitle('موقعیت مکانی پروژه', icon: Icons.location_on_outlined),
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationPickerButton(
                        title: 'استان *',
                        value: _selectedProvinceName,
                        onTap: _showProvincePickerBottomSheet,
                        icon: Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLocationPickerButton(
                        title: 'شهر *',
                        value: _selectedCityName,
                        onTap: _showCityPickerBottomSheet,
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('آدرس محل اجرای دقیق (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, fontFamily: 'Vazirmatn')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('خیابان، کوچه، پلاک...', prefixIcon: Icons.place_outlined),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
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
                const SizedBox(height: 18),

                // Section 3: Description
                _buildSectionTitle('توضیحات و مشخصات پروژه', icon: Icons.description_outlined),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration('توضیحات کامل در مورد متراژ، تعداد طبقات، نوع اسکلت و شرایط اجرایی پروژه...'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.5, fontFamily: 'Vazirmatn'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'لطفاً توضیحات پروژه را وارد کنید.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Section 4: Images Upload & Album Gallery
                _buildSectionTitle('تصاویر پروژه ($persianCountText)', icon: Icons.photo_library_outlined),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: totalImagesCount < 10 ? _pickImages : null,
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
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 44,
                            color: AppColors.amberOrange,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            totalImagesCount == 0
                                ? 'انتخاب و آپلود تصاویر پروژه (امکان انتخاب همزمان چند عکس)'
                                : 'افزودن تصاویر بیشتر...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'فرمت‌های مجاز: JPG, PNG (حداکثر ${Formatters.toPersianNumbers('10')} تصویر برای هر پروژه)',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Vazirmatn'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Selected Images Album Display right under upload box
                if (totalImagesCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
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
                                Icon(Icons.collections_outlined, size: 16, color: AppColors.amberOrange),
                                SizedBox(width: 6),
                                Text(
                                  'آلبوم تصاویر انتخاب‌شده:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                persianCountText,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 94,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._existingImageUrls.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final url = entry.value;
                                final fullUrl = url.startsWith('http') ? url : '${ApiService().baseUrl}$url';

                                return Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderGrey),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(fullUrl, width: 90, height: 90, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _existingImageUrls.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              ..._newImages.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final img = entry.value;

                                return Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.amberOrange),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(Uint8List.fromList(img.bytes), width: 90, height: 90, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _newImages.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Sticky Pinned Bottom Button
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.borderGrey, width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        isEdit ? 'ثبت تغییرات پروژه' : 'ثبت پروژه',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vazirmatn'),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
