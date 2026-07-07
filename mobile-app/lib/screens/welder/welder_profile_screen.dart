import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

enum ProfileView { menu, personalInfo, coverage, rates }

class WelderProfileScreen extends StatefulWidget {
  const WelderProfileScreen({super.key});

  @override
  State<WelderProfileScreen> createState() => _WelderProfileScreenState();
}

class _WelderProfileScreenState extends State<WelderProfileScreen> {
  ProfileView _currentView = ProfileView.menu;

  // Controllers & Local States
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _homeCityController = TextEditingController();

  List<String> _activeCities = [];
  List<Map<String, dynamic>> _priceList = [];

  // Geo API states
  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];
  int? _selectedProvinceId;
  bool _isLoadingGeo = false;
  bool _isLoadingCities = false;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadProfile().then((_) {
        _populateFields();
      });
    });
    _loadProvinces();
  }

  void _populateFields() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.profileData != null) {
      final profile = auth.profileData!['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        setState(() {
          _firstNameController.text = profile['first_name'] ?? '';
          _lastNameController.text = profile['last_name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _homeCityController.text = profile['home_city'] ?? '';
          
          final rawCities = profile['active_cities'] as List<dynamic>?;
          _activeCities = rawCities != null ? rawCities.map((e) => e.toString()).toList() : [];

          final rawPrices = profile['base_price_list'] as List<dynamic>?;
          _priceList = rawPrices != null
              ? rawPrices.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          
          _initialized = true;
        });
      }
    }
  }

  Future<void> _loadProvinces() async {
    if (mounted) setState(() => _isLoadingGeo = true);
    try {
      final list = await _apiService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
          _isLoadingGeo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGeo = false);
      }
    }
  }

  Future<void> _loadCities(int provinceId) async {
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
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _homeCityController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalInfo() async {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('لطفاً نام خود را وارد کنید.');
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('لطفاً نام خانوادگی خود را وارد کنید.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateWelderProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        homeCity: _homeCityController.text.trim(),
        isSetupCompleted: true,
      );
      setState(() {
        _isSaving = false;
        _currentView = ProfileView.menu;
      });
      _showSuccess('اطلاعات شناسایی با موفقیت ذخیره شد.');
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('خطا در ذخیره اطلاعات: $e');
    }
  }

  Future<void> _saveCoverage() async {
    if (_activeCities.isEmpty) {
      _showError('لطفاً حداقل یک شهر را به عنوان محدوده فعالیت خود انتخاب کنید.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateWelderProfile(
        activeCities: _activeCities,
        isSetupCompleted: true,
      );
      setState(() {
        _isSaving = false;
        _currentView = ProfileView.menu;
      });
      _showSuccess('محدوده فعالیت با موفقیت به روزرسانی شد.');
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('خطا در ذخیره محدوده فعالیت: $e');
    }
  }

  Future<void> _saveRates() async {
    if (_priceList.isEmpty) {
      _showError('لیست قیمت‌ها نمی‌تواند خالی باشد. حداقل یک تعرفه وارد کنید.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateWelderPrices(_priceList);
      setState(() {
        _isSaving = false;
        _currentView = ProfileView.menu;
      });
      _showSuccess('لیست تعرفه‌های قیمت با موفقیت به‌روزرسانی شد.');
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('خطا در ذخیره تعرفه‌ها: $e');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }



  void _showAddPriceBottomSheet() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();
    final bottomFormKey = GlobalKey<FormState>();

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
              key: bottomFormKey,
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
                  const SizedBox(height: 20),
                  const Text(
                    'افزودن نرخ/تعرفه جوشکاری جدید',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان خدمات',
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً عنوان را وارد کنید' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'مبلغ (تومان)',
                            filled: true,
                            fillColor: AppColors.lightGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'لطفاً مبلغ را وارد کنید';
                            if (double.tryParse(val.replaceAll(',', '')) == null) return 'عدد معتبر وارد کنید';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'واحد محاسبه',
                            filled: true,
                            fillColor: AppColors.lightGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً واحد را وارد کنید' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!bottomFormKey.currentState!.validate()) return;
                        final priceClean = double.parse(priceController.text.replaceAll(',', ''));
                        setState(() {
                          _priceList.add({
                            'title': titleController.text.trim(),
                            'unit': unitController.text.trim(),
                            'price_per_unit': priceClean,
                          });
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('افزودن به لیست', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!_initialized && auth.profileData == null) {
      return const Scaffold(
        backgroundColor: AppColors.lightGrey,
        body: Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
      );
    }

    // Lazy initialization check if not done already
    if (!_initialized && auth.profileData != null) {
      _populateFields();
    }

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          _getViewTitle(),
          style: const TextStyle(color: AppColors.burgundy, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: _currentView != ProfileView.menu
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => setState(() => _currentView = ProfileView.menu),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderGrey, height: 1),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.burgundy),
                  SizedBox(height: 16),
                  Text('در حال ذخیره‌سازی اطلاعات...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentViewBody(auth),
            ),
    );
  }

  String _getViewTitle() {
    switch (_currentView) {
      case ProfileView.menu:
        return 'حساب کاربری جوشکار';
      case ProfileView.personalInfo:
        return 'ویرایش اطلاعات شناسایی';
      case ProfileView.coverage:
        return 'مدیریت محدوده فعالیت';
      case ProfileView.rates:
        return 'مدیریت نرخ‌ها و تعرفه‌ها';
    }
  }

  Widget _buildCurrentViewBody(AuthProvider auth) {
    switch (_currentView) {
      case ProfileView.menu:
        return _buildMainMenuBody(auth);
      case ProfileView.personalInfo:
        return _buildPersonalInfoBody();
      case ProfileView.coverage:
        return _buildCoverageBody();
      case ProfileView.rates:
        return _buildRatesBody();
    }
  }

  // --- 1. Main Menu View ---
  Widget _buildMainMenuBody(AuthProvider auth) {
    final profile = auth.profileData?['profile'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] ?? 'جوشکار مهمان';
    final bio = profile?['bio'] ?? 'بدون بیوگرافی یا توضیحات تخصص';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Personal profile card summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.lightGrey,
                  child: Icon(Icons.engineering, size: 40, color: AppColors.burgundy),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Menu items list
          _buildMenuTile(
            title: 'ویرایش اطلاعات شناسایی',
            subtitle: 'تغییر نام و نشان، بیوگرافی و شهر محل سکونت',
            icon: Icons.person_outline,
            onTap: () => setState(() => _currentView = ProfileView.personalInfo),
          ),
          _buildMenuTile(
            title: 'مدیریت محدوده فعالیت (استان و شهرها)',
            subtitle: 'انتخاب استان‌ها و اضافه کردن شهرهای خدماتی شما',
            icon: Icons.map_outlined,
            onTap: () => setState(() => _currentView = ProfileView.coverage),
          ),
          _buildMenuTile(
            title: 'مدیریت نرخ‌ها و تعرفه‌ها',
            subtitle: 'تنظیم چندین قیمت پایه برای انواع جوشکاری‌ها',
            icon: Icons.monetization_on_outlined,
            onTap: () => setState(() => _currentView = ProfileView.rates),
          ),
          const SizedBox(height: 30),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('خروج از حساب کاربری', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.burgundy.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.burgundy, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ),
    );
  }

  // --- 2. Edit Personal Info View ---
  Widget _buildPersonalInfoBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اطلاعات هویتی شما:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'نام (الزامی)',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'نام خانوادگی (الزامی)',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _homeCityController,
            decoration: InputDecoration(
              labelText: 'شهر محل سکونت',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'درباره من / بیوگرافی و تخصص‌ها',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _savePersonalInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('ذخیره اطلاعات شناسایی', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
                      'انتخاب استان محل فعالیت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.burgundy),
                    ),
                    const SizedBox(height: 12),

                    // Search field for provinces
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

                    Expanded(
                      child: filteredProvinces.isEmpty
                          ? const Center(
                              child: Text(
                                'هیچ استانی یافت نشد.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredProvinces.length,
                              itemBuilder: (context, idx) {
                                final prov = filteredProvinces[idx];
                                final isSelected = prov['id'] == _selectedProvinceId;
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
                                      _activeCities.clear(); // Clear previously selected cities since province changed
                                    });
                                    _loadCities(prov['id'] as int);
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
                    const Text(
                      'انتخاب شهرهای فعال',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.burgundy),
                    ),
                    const SizedBox(height: 12),
                    
                    // Realtime search textfield
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

                    _isLoadingCities
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: AppColors.royalBlue),
                            ),
                          )
                        : Expanded(
                            child: filteredCities.isEmpty
                                ? const Center(
                                    child: Text(
                                      'هیچ شهری یافت نشد.',
                                      style: TextStyle(color: AppColors.textMuted),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredCities.length,
                                    itemBuilder: (context, idx) {
                                      final city = filteredCities[idx];
                                      final cityName = city['name'] as String;
                                      final isChecked = _activeCities.contains(cityName);

                                      return CheckboxListTile(
                                        title: Text(
                                          cityName,
                                          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                                        ),
                                        value: isChecked,
                                        activeColor: AppColors.royalBlue,
                                        onChanged: (val) {
                                          if (val == true) {
                                            setSheetState(() {
                                              _activeCities.add(cityName);
                                            });
                                            setState(() {});
                                          } else {
                                            setSheetState(() {
                                              _activeCities.remove(cityName);
                                            });
                                            setState(() {});
                                          }
                                        },
                                      );
                                    },
                                  ),
                          ),
                    const SizedBox(height: 12),
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
                        child: const Text('تایید و ثبت شهرها', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. Edit Coverage View ---
  Widget _buildCoverageBody() {
    final selectedProvince = _provinces.firstWhere(
      (prov) => prov['id'] == _selectedProvinceId,
      orElse: () => null,
    );
    final provinceName = selectedProvince != null ? selectedProvince['name'] as String : 'انتخاب نشده';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('انتخاب محدوده جغرافیایی فعالیت:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy)),
          const SizedBox(height: 14),

          // Province Selector Tile
          _isLoadingGeo
              ? const Center(child: CircularProgressIndicator(color: AppColors.burgundy))
              : InkWell(
                  onTap: _showProvincePickerBottomSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
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
                              const Text(
                                'استان محل کار',
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provinceName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),

          // City Selector Tile
          InkWell(
            onTap: _selectedProvinceId == null ? null : _showCityPickerBottomSheet,
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: _selectedProvinceId == null ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
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
                          const Text(
                            'شهرهای فعال تحت پوشش شما',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activeCities.isEmpty
                                ? 'هیچ شهری انتخاب نشده است (افزودن...)'
                                : '${_activeCities.length} شهر انتخاب شده',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _activeCities.isEmpty ? AppColors.textMuted : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.royalBlue, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Selected active cities display
          if (_activeCities.isNotEmpty) ...[
            const Text('شهرهای انتخاب‌شده فعال:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeCities.map((city) {
                return Chip(
                  label: Text(city),
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                  labelStyle: const TextStyle(color: AppColors.royalBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.royalBlue, width: 0.5),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.royalBlue),
                  onDeleted: () {
                    setState(() {
                      _activeCities.remove(city);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveCoverage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('ذخیره محدوده فعالیت', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Edit Rates View ---
  Widget _buildRatesBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('لیست تعرفه‌های ثبت شده:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy)),
              TextButton.icon(
                onPressed: _showAddPriceBottomSheet,
                icon: const Icon(Icons.add),
                label: const Text('افزودن نرخ جدید', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: AppColors.royalBlue),
              )
            ],
          ),
          const SizedBox(height: 14),

          // Prices list
          if (_priceList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  'هیچ تعرفه قیمتی ثبت نشده است.',
                  style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _priceList.length,
              itemBuilder: (context, idx) {
                final item = _priceList[idx];
                final priceFormatted = item['price_per_unit'].toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.amberOrange, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                        ),
                      ),
                      Text(
                        '$priceFormatted تومان / ${item['unit']}',
                        style: const TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () {
                          setState(() {
                            _priceList.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('ذخیره تعرفه‌های قیمت', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
