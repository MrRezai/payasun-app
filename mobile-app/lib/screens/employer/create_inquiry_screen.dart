import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/api_service.dart';
import '../../models/inquiry.dart';

class CreateInquiryScreen extends StatefulWidget {
  final Inquiry? inquiryToEdit;
  const CreateInquiryScreen({super.key, this.inquiryToEdit});

  @override
  State<CreateInquiryScreen> createState() => _CreateInquiryScreenState();
}

class _CreateInquiryScreenState extends State<CreateInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _itemTitleController = TextEditingController();
  final _itemUnitController = TextEditingController();
  final _itemQtyController = TextEditingController();

  // Location states
  int? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityName;

  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    if (widget.inquiryToEdit != null) {
      _titleController.text = widget.inquiryToEdit!.title;
      _descController.text = widget.inquiryToEdit!.description;
      _selectedProvinceName = widget.inquiryToEdit!.province;
      _selectedCityName = widget.inquiryToEdit!.city;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<InquiryProvider>(context, listen: false);
        provider.setHasBlueprint(widget.inquiryToEdit!.hasBlueprint);
        provider.clearManualItems();
        for (var item in widget.inquiryToEdit!.items) {
          provider.addManualItem(item.title, item.unit, item.quantity);
        }
      });
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست استان‌ها: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadCities(int provinceId) async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
        _citiesOfSelectedProvince = [];
        _selectedCityName = null;
      });
    }
    try {
      final list = await _apiService.fetchCities(provinceId);
      if (mounted) {
        setState(() {
          _citiesOfSelectedProvince = list;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست شهرها: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadCitiesForEditing(int provinceId) async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
        _citiesOfSelectedProvince = [];
      });
    }
    try {
      final list = await _apiService.fetchCities(provinceId);
      if (mounted) {
        setState(() {
          _citiesOfSelectedProvince = list;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست شهرها: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _itemTitleController.dispose();
    _itemUnitController.dispose();
    _itemQtyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCityName == null || _selectedCityName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً شهر محل پروژه را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<InquiryProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedProvinceName == null || _selectedProvinceName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً استان محل پروژه را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = widget.inquiryToEdit != null
        ? await provider.updateInquiry(
            token: auth.token,
            inquiryId: widget.inquiryToEdit!.id,
            title: _titleController.text,
            description: _descController.text,
            city: _selectedCityName!,
            province: _selectedProvinceName!,
          )
        : await provider.submitInquiry(
            token: auth.token,
            title: _titleController.text,
            description: _descController.text,
            city: _selectedCityName!,
            province: _selectedProvinceName!,
          );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'استعلام با موفقیت ثبت شد!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedProvinceId = null;
        _selectedProvinceName = null;
        _selectedCityName = null;
      });
      provider.clearSelectedFile();
      provider.clearManualItems();
      
      // Go back to the inquiries list screen
      Navigator.pop(context, true);
    } else if (provider.errorMessage != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'خطا در ثبت استعلام',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold),
          ),
          content: Text(
            provider.errorMessage!,
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('متوجه شدم'),
            ),
          ],
        ),
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
            final filteredProvinces = _provinces.where((prov) {
              final name = prov['name'] as String;
              return name.contains(searchFilter);
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
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
                    const Text(
                      'انتخاب استان پروژه',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.burgundy),
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
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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

                    SizedBox(
                      height: 300,
                      child: _isLoadingProvinces
                          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                          : filteredProvinces.isEmpty
                              ? const Center(
                                  child: Text(
                                    'هیچ استانی یافت نشد.',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                )
                              : ListView.builder(
                              itemCount: filteredProvinces.length,
                              itemBuilder: (context, index) {
                                final prov = filteredProvinces[index];
                                final isSelected = prov['name'] == _selectedProvinceName;
                                return ListTile(
                                  title: Text(
                                    prov['name'] as String,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: AppColors.royalBlue)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedProvinceId = prov['id'] as int;
                                      _selectedProvinceName = prov['name'] as String;
                                    });
                                    _loadCities(_selectedProvinceId!);
                                    Navigator.pop(context);
                                  },
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
            final filteredCities = _citiesOfSelectedProvince.where((city) {
              final cityName = city['name'] as String;
              return cityName.contains(searchFilter);
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
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
                    Text(
                      'انتخاب شهر ($_selectedProvinceName)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.burgundy),
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
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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

                    SizedBox(
                      height: 300,
                      child: _isLoadingCities
                          ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                          : filteredCities.isEmpty
                              ? const Center(child: Text('شهری یافت نشد.', style: TextStyle(color: AppColors.textMuted)))
                              : ListView.builder(
                                  itemCount: filteredCities.length,
                                  itemBuilder: (context, index) {
                                    final city = filteredCities[index];
                                    final isSelected = city['name'] == _selectedCityName;
                                    return ListTile(
                                      title: Text(
                                        city['name'] as String,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: AppColors.royalBlue)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedCityName = city['name'] as String;
                                        });
                                        Navigator.pop(context);
                                      },
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'انتخاب واحد محاسبه',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.burgundy),
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
                      return ListTile(
                        title: Text(
                          u,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.royalBlue) : null,
                        onTap: () {
                          setState(() {
                            _itemUnitController.text = u;
                          });
                          Navigator.pop(context);
                        },
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
            onPressed: () => Navigator.pop(context),
            tooltip: 'بازگشت',
          ),
          title: const Text(
            'ثبت استعلام جدید',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.burgundy,
              fontFamily: 'Vazirmatn',
            ),
          ),
          centerTitle: true,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('مشخصات استعلام جدید'),
              const SizedBox(height: 15),

              // Title Field
              _buildTextField(
                controller: _titleController,
                label: 'عنوان استعلام',
                hint: 'مثال: جوشکاری اسکلت فلزی ساختمان مسکونی ۴ طبقه',
                validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً عنوان را وارد کنید' : null,
              ),
              const SizedBox(height: 12),

              // Location Selector Row
              Row(
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
                              color: _selectedProvinceName != null
                                  ? AppColors.royalBlue.withValues(alpha: 0.5)
                                  : AppColors.borderGrey,
                              width: _selectedProvinceName != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedProvinceName ?? 'استان پروژه',
                                style: TextStyle(
                                  color: _selectedProvinceName != null ? AppColors.textDark : AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: _selectedProvinceName != null ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
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
                              color: _selectedCityName != null
                                  ? AppColors.royalBlue.withValues(alpha: 0.5)
                                  : AppColors.borderGrey,
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
                              const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description Field
              _buildTextField(
                controller: _descController,
                label: 'توضیحات تکمیلی پروژه',
                hint: 'توضیحات درباره زمان شروع، جزئیات جوشکاری و شرایط کارگاه...',
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً توضیحات را وارد کنید' : null,
              ),
              const SizedBox(height: 20),

              // Toggle selector card
              _buildToggleCard(provider),
              const SizedBox(height: 20),

              // Conditional Layout: Blueprint Upload Area vs Manual Items Input
              if (provider.hasBlueprint)
                _buildBlueprintUploadArea(provider)
              else
                _buildManualItemsArea(provider),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderGrey, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _showReviewBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'ثبت و ارسال استعلام',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
            ),
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
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.amberOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.royalBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
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
      ),
    );
  }

  Widget _buildToggleCard(InquiryProvider provider) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SwitchListTile(
          title: const Text(
            'من لیست اقلام ندارم، مایل به آپلود پلان ساختمان هستم',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Vazirmatn',
            ),
          ),
          value: provider.hasBlueprint,
          onChanged: (val) {
            provider.setHasBlueprint(val);
          },
          activeThumbColor: AppColors.royalBlue,
          activeTrackColor: AppColors.royalBlue.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildBlueprintUploadArea(InquiryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('آپلود نقشه ساختمان'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            await provider.pickBlueprintFile();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3), style: BorderStyle.solid),
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
                  size: 54,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 15),
                if (provider.selectedFileName == null) ...[
                  const Text(
                    'انتخاب و آپلود پلان یا فایل فنی ساختمان',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'فرمت‌های مجاز: PDF, DWG, PNG, JPG (حداکثر ۱۵ مگابایت)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ] else ...[
                  Text(
                    provider.selectedFileName!,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      provider.clearSelectedFile();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'حذف فایل انتخابی',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualItemsArea(InquiryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ثبت اقلام استعلام'),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _itemTitleController,
                label: 'عنوان کالا یا خدمات جوشکاری',
                hint: 'مثال: جوشکاری نرده حفاظ',
              ),
              const SizedBox(height: 12),
              Row(
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
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final title = _itemTitleController.text.trim();
                    final unit = _itemUnitController.text.trim();
                    final qty = double.tryParse(_itemQtyController.text.trim()) ?? 0.0;

                    if (title.isEmpty || unit.isEmpty || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لطفاً مشخصات قلم کالا را به طور صحیح وارد کنید.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    provider.addManualItem(title, unit, qty);
                    _itemTitleController.clear();
                    _itemUnitController.clear();
                    _itemQtyController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('افزودن به لیست اقلام'),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        if (provider.manualItems.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'اقلام اضافه شده:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amberOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${provider.manualItems.length}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.manualItems.length,
            itemBuilder: (context, index) {
              final item = provider.manualItems[index];
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderGrey),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('مقدار: ${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      provider.removeManualItem(index);
                    },
                  ),
                ),
              );
            },
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'هیچ قلمی ثبت نشده است. لطفاً اقلام پروژه را ثبت کنید.',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _showReviewBottomSheet() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCityName == null || _selectedCityName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً شهر محل پروژه را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedProvinceName == null || _selectedProvinceName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً استان محل پروژه را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<InquiryProvider>(context, listen: false);
    if (provider.hasBlueprint) {
      if (provider.selectedFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً ابتدا فایل پلان را انتخاب کنید.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (provider.manualItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً حداقل یک قلم کالا یا خدمات وارد کنید.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    _showInquiryPreviewBottomSheet();
  }

  void _showInquiryPreviewBottomSheet() {
    bool termsAccepted = false;
    final provider = Provider.of<InquiryProvider>(context, listen: false);

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
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20,
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
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: AppColors.royalBlue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'پیش‌نویس و تایید استعلام',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.burgundy,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لطفاً اطلاعات ثبت شده را بررسی و تایید کنید:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPreviewItem(
                            label: 'عنوان استعلام:',
                            value: _titleController.text,
                            icon: Icons.title,
                          ),
                          const Divider(height: 20, color: AppColors.borderGrey),
                          _buildPreviewItem(
                            label: 'محل پروژه:',
                            value: '$_selectedProvinceName - $_selectedCityName',
                            icon: Icons.location_on_outlined,
                          ),
                          const Divider(height: 20, color: AppColors.borderGrey),
                          _buildPreviewItem(
                            label: 'توضیحات پروژه:',
                            value: _descController.text,
                            icon: Icons.description_outlined,
                          ),
                          const Divider(height: 20, color: AppColors.borderGrey),
                          if (provider.hasBlueprint)
                            _buildPreviewItem(
                              label: 'نقشه فنی آپلود شده:',
                              value: provider.selectedFileName ?? '',
                              icon: Icons.map_outlined,
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_list_bulleted, size: 18, color: AppColors.royalBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      'اقلام ثبت شده (${provider.manualItems.length} قلم):',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 120),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: provider.manualItems.length,
                                    itemBuilder: (context, idx) {
                                      final item = provider.manualItems[idx];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '• ${item.title} - ${item.quantity} ${item.unit}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textDark,
                                            fontFamily: 'Vazirmatn',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Checkbox(
                          value: termsAccepted,
                          activeColor: AppColors.royalBlue,
                          onChanged: (val) {
                            setSheetState(() {
                              termsAccepted = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'قوانین و مقررات ثبت استعلام در جفت‌وجور را می‌پذیرم.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: termsAccepted
                                ? () {
                                    Navigator.pop(context);
                                    _submit();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.borderGrey,
                              disabledForegroundColor: AppColors.textMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: const Text(
                              'تایید نهایی و ارسال',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderGrey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'انصراف و ویرایش',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.royalBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
