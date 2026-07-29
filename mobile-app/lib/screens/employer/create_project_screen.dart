import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../models/project.dart';
import '../../services/api_service.dart';

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

  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];

  String? _selectedProvince;
  String? _selectedCity;
  int? _selectedProvinceId;

  bool _isLoadingGeo = true;
  bool _isSubmitting = false;

  final List<String> _existingImageUrls = [];
  final List<LocalProjectImage> _newImages = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    if (widget.projectToEdit != null) {
      final p = widget.projectToEdit!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _addressController.text = p.address ?? '';
      _selectedProvince = p.province;
      _selectedCity = p.city;
      _existingImageUrls.addAll(p.imageUrls);
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final list = await ApiService().fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingGeo = false;

          if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
            final match = _provinces.firstWhere(
              (p) => p['name'].toString().trim() == _selectedProvince!.trim(),
              orElse: () => null,
            );
            if (match != null) {
              _selectedProvinceId = match['id'] as int;
              _loadCities(_selectedProvinceId!);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingGeo = false;
        });
      }
    }
  }

  Future<void> _loadCities(int provinceId) async {
    try {
      final list = await ApiService().fetchCities(provinceId);
      if (mounted) {
        setState(() {
          _cities = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    int totalCount = _existingImageUrls.length + _newImages.length;
    if (totalCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حداکثر ۱۰ تصویر می‌توانید اضافه کنید.'),
          backgroundColor: Colors.orange,
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
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null || _selectedProvince!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً استان پروژه را انتخاب کنید.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شهر پروژه را انتخاب کنید.'), backgroundColor: Colors.red),
      );
      return;
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
        description: _descriptionController.text.trim(),
        city: _selectedCity!,
        province: _selectedProvince!,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        existingImageUrls: _existingImageUrls,
        newImageBytesList: _newImages.map((e) => e.bytes).toList(),
        newImageFilenames: _newImages.map((e) => e.name).toList(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات پروژه با موفقیت ویرایش شد.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'خطا در ویرایش پروژه'), backgroundColor: Colors.red),
        );
      }
    } else {
      final created = await provider.createProject(
        token: auth.token,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _selectedCity!,
        province: _selectedProvince!,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        imageBytesList: _newImages.map((e) => e.bytes).toList(),
        imageFilenames: _newImages.map((e) => e.name).toList(),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (created != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروژه جدید با موفقیت ثبت شد!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'خطا در ثبت پروژه'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.projectToEdit != null;
    int totalImagesCount = _existingImageUrls.length + _newImages.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0.5,
          title: Text(
            isEdit ? 'ویرایش اطلاعات پروژه' : 'ثبت پروژه جدید',
            style: const TextStyle(
              color: AppColors.royalBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Vazirmatn',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.royalBlue, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'پروژه خود را تعریف کنید (مثلاً متراژ و تعداد طبقات). نیازی به تایید ادمین نیست و می‌توانید بعداً روی آن استعلام بگیرید.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textDark,
                            height: 1.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text('عنوان پروژه *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'مثلاً: پروژه ۳۰۰ متری ۲ طبقه مسکونی',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'لطفاً عنوان پروژه را وارد کنید.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Province & City
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('استان *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 8),
                          _isLoadingGeo
                              ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedProvince,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                                  ),
                                  items: _provinces.map((p) {
                                    final name = p['name'].toString();
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedProvince = val;
                                      _selectedCity = null;
                                      _cities = [];
                                      final match = _provinces.firstWhere((p) => p['name'].toString() == val, orElse: () => null);
                                      if (match != null) {
                                        _selectedProvinceId = match['id'] as int;
                                        _loadCities(_selectedProvinceId!);
                                      }
                                    });
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('شهر *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCity,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                            ),
                            items: _cities.map((c) {
                              final name = c['name'].toString();
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCity = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Address
                const Text('آدرس محل پروژه (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'خیابان، کوچه، پلاک...',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                  ),
                ),
                const SizedBox(height: 18),

                // Description
                const Text('توضیحات پروژه *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'توضیحات کامل در مورد متراژ، تعداد طبقات، وضعیت شاسی و شرایط اجرایی پروژه...',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderGrey)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'لطفاً توضیحات پروژه را وارد کنید.';
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Project Images Section (Up to 10 images max)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تصاویر پروژه ($totalImagesCount از ۱۰)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    ),
                    if (totalImagesCount < 10)
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.royalBlue),
                        label: const Text('افزودن تصویر', style: TextStyle(color: AppColors.royalBlue, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (totalImagesCount == 0)
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('جهت افزودن عکس‌های پروژه اینجا کلیک کنید', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn')),
                          const SizedBox(height: 4),
                          const Text('امکان انتخاب تا حداکثر ۱۰ تصویر وجود دارد', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Vazirmatn')),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
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
                              border: Border.all(color: AppColors.royalBlue),
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

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: AppColors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            isEdit ? 'ثبت تغییرات پروژه' : 'ثبت پروژه',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vazirmatn'),
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
}
