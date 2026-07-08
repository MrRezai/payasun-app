import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/route_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../main_shell_screen.dart';

class EmployerSetupScreen extends StatefulWidget {
  const EmployerSetupScreen({super.key});

  @override
  State<EmployerSetupScreen> createState() => _EmployerSetupScreenState();
}

class _EmployerSetupScreenState extends State<EmployerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _bioController = TextEditingController();

  // Location states
  int? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedCityName;
  
  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];
  
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    // Pre-populate name from auth provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = auth.profileData?['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        if (profile['first_name'] != null) {
          _firstNameController.text = profile['first_name'] as String;
        }
        if (profile['last_name'] != null) {
          _lastNameController.text = profile['last_name'] as String;
        }
      }
    });
  }

  Future<void> _loadProvinces() async {
    if (mounted) setState(() => _isLoadingProvinces = true);
    try {
      final list = await _apiService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingProvinces = false;
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvinceName == null || _selectedProvinceName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً استان محل فعالیت خود را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCityName == null || _selectedCityName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً شهر محل فعالیت خود را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      await auth.updateEmployerProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        companyName: _companyNameController.text.trim().isNotEmpty ? _companyNameController.text.trim() : null,
        province: _selectedProvinceName,
        city: _selectedCityName,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        isSetupCompleted: true,
      );

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حساب کاربری شما با موفقیت پیکربندی شد. خوش آمدید!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const MainShellScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره اطلاعات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProvincePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'انتخاب استان محل فعالیت',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _provinces.length,
                    itemBuilder: (context, index) {
                      final prov = _provinces[index];
                      return ListTile(
                        title: Text(
                          prov['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
  }

  void _showCityPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انتخاب شهر ($_selectedProvinceName)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _citiesOfSelectedProvince.isEmpty
                      ? const Center(child: Text('شهری یافت نشد.'))
                      : ListView.builder(
                          itemCount: _citiesOfSelectedProvince.length,
                          itemBuilder: (context, index) {
                            final city = _citiesOfSelectedProvince[index];
                            return ListTile(
                              title: Text(
                                city['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
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
  }

  Widget _buildImageLogo(double size) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: AppColors.royalBlue.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/logo/joftojoor.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.royalBlue,
            fontFamily: 'Vazirmatn',
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: _isSaving
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تأیید نهایی و ورود به داشبورد',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
        body: Stack(
          children: [
            // Decorative background glowing accents
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.02),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: _isSaving
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.royalBlue),
                          SizedBox(height: 16),
                          Text(
                            'در حال ثبت و ایجاد پروفایل کاربری...',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                          )
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Title with small logo next to it
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildImageLogo(24),
                                const SizedBox(width: 8),
                                const Text(
                                  'تکمیل پروفایل کارفرما جفت‌وجور',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'برای آغاز ثبت استعلام‌ها در سیستم، اطلاعات زیر را تکمیل کنید.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 35),

                            // Personal info card
                            _buildSectionLabel('اطلاعات کاربری', isRequired: false),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      label: RichText(
                                        text: const TextSpan(
                                          text: 'نام',
                                          style: TextStyle(color: AppColors.textDark, fontFamily: 'Vazirmatn', fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      filled: true,
                                      fillColor: AppColors.lightGrey,
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
                                        borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'وارد کردن نام الزامی است' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      label: RichText(
                                        text: const TextSpan(
                                          text: 'نام خانوادگی',
                                          style: TextStyle(color: AppColors.textDark, fontFamily: 'Vazirmatn', fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: ' *',
                                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      filled: true,
                                      fillColor: AppColors.lightGrey,
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
                                        borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                                      ),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'وارد کردن نام خانوادگی الزامی است' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _companyNameController,
                              decoration: InputDecoration(
                                labelText: 'نام پروژه، برند یا شرکت (اختیاری)',
                                helperText: 'اگر پروژه شخصی است یا شرکت ندارید، می‌توانید این فیلد را خالی بگذارید.',
                                helperStyle: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.business_rounded, size: 20),
                                filled: true,
                                fillColor: AppColors.lightGrey,
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
                                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Location selector card
                            _buildSectionLabel('محل فعالیت شرکت / کارگاه', isRequired: false),
                            const SizedBox(height: 12),
                            _isLoadingProvinces
                                ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
                                : InkWell(
                                    onTap: _showProvincePickerBottomSheet,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGrey,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.borderGrey),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.map_outlined, color: AppColors.royalBlue, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: const TextSpan(
                                                    text: 'استان',
                                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                                    children: [
                                                      TextSpan(
                                                        text: ' *',
                                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _selectedProvinceName ?? 'انتخاب نشده',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: _selectedProvinceName == null ? AppColors.textMuted : AppColors.textDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _selectedProvinceId == null || _isLoadingCities ? null : _showCityPickerBottomSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Opacity(
                                opacity: _selectedProvinceId == null ? 0.5 : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderGrey),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_city_outlined, color: AppColors.royalBlue, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                text: 'شهر',
                                                style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                                                children: [
                                                  TextSpan(
                                                    text: ' *',
                                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _isLoadingCities
                                                ? const SizedBox(
                                                    height: 14,
                                                    width: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.royalBlue),
                                                  )
                                                : Text(
                                                    _selectedCityName ?? 'انتخاب نشده',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: _selectedCityName == null ? AppColors.textMuted : AppColors.textDark,
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _bioController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'آدرس فیزیکی یا جزئیات فعالیت (اختیاری)',
                                prefixIcon: const Icon(Icons.description_outlined, size: 20),
                                filled: true,
                                fillColor: AppColors.lightGrey,
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
                                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
