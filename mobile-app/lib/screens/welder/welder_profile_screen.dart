import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/route_transitions.dart';
import '../auth/login_phone_screen.dart';

enum ProfileView { menu, personalInfo, coverage, rates, skills, financialInfo }

class WelderProfileScreen extends StatefulWidget {
  const WelderProfileScreen({super.key});

  @override
  State<WelderProfileScreen> createState() => _WelderProfileScreenState();
}

class _WelderProfileScreenState extends State<WelderProfileScreen> {
  ProfileView _currentView = ProfileView.menu;

  Future<void> _pickProfileImage(AuthProvider auth) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int>? bytes;
        if (kIsWeb) {
          bytes = file.bytes;
        } else if (file.path != null) {
          bytes = File(file.path!).readAsBytesSync();
        }

        if (bytes != null) {
          setState(() => _isSaving = true);
          try {
            await auth.uploadProfilePicture(bytes, file.name);
            setState(() => _isSaving = false);
            _showSuccess('تصویر با موفقیت ارسال شد و در انتظار تایید ادمین قرار گرفت.');
          } catch (e) {
            setState(() => _isSaving = false);
            _showError('خطا در آپلود تصویر: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError('خطا در انتخاب تصویر');
    }
  }
  // Controllers & Local States
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  // Controllers for financial settings
  final _cardNumberController = TextEditingController();
  final _shibaController = TextEditingController();
  final _bankNameController = TextEditingController();



  // Home location states
  int? _homeProvinceId;
  String? _homeCityName;
  String? _homeProvinceName;
  List<dynamic> _citiesOfHomeProvince = [];
  bool _isLoadingHomeCities = false;

  List<String> _activeCities = [];
  List<Map<String, dynamic>> _priceList = [];
  String? _activeProvinceName;

  // Geo API states
  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];
  int? _selectedProvinceId;
  bool _isLoadingGeo = false;
  bool _isLoadingCities = false;

  // Welder skills states
  List<dynamic> _availableSkills = [];
  final List<int> _selectedSkillIds = [];
  bool _isLoadingSkills = false;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).loadProfile().then((_) {
        if (mounted) {
          _populateFields();
        }
      });
    });
    _loadProvinces();
  }

  Future<void> _loadSkills() async {
    if (mounted) setState(() => _isLoadingSkills = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final list = await auth.getAvailableSkills();
      if (mounted) {
        setState(() {
          _availableSkills = list;
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSkills = false);
        _showError('خطا در دریافت لیست مهارت‌ها: $e');
      }
    }
  }

  void _populateFields() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.profileData != null) {
      final profile = auth.profileData!['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        setState(() {
          _firstNameController.text = profile['first_name'] ?? '';
          _lastNameController.text = profile['last_name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _homeCityName = profile['home_city'];
          _homeProvinceName = profile['home_province'];
          _activeProvinceName = profile['active_province'];
          
          final rawCities = profile['active_cities'] as List<dynamic>?;
          _activeCities = rawCities != null ? rawCities.map((e) => e.toString()).toList() : [];

          final rawPrices = profile['base_price_list'] as List<dynamic>?;
          _priceList = rawPrices != null
              ? rawPrices.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          
          final rawSkills = profile['skills'] as List<dynamic>?;
          _selectedSkillIds.clear();
          if (rawSkills != null) {
            for (final s in rawSkills) {
              final id = s['id'] as int?;
              if (id != null) {
                _selectedSkillIds.add(id);
              }
            }
          }
          
          _initialized = true;
        });
        _resolveHomeProvinceId();
        _resolveActiveProvinceId();
      }
    }
  }

  void _populateFinancialFields() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.profileData != null) {
      final profile = auth.profileData!['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        setState(() {
          _cardNumberController.text = profile['card_number'] ?? '';
          _shibaController.text = profile['shiba_number'] ?? '';
          _bankNameController.text = profile['bank_name'] ?? '';
        });
      }
    }
  }

  Future<void> _saveFinancialInfo(AuthProvider auth) async {
    final card = _cardNumberController.text.trim();
    final shiba = _shibaController.text.trim();
    final bank = _bankNameController.text.trim();
    if (card.isEmpty) {
      _showError('لطفاً شماره کارت را وارد کنید.');
      return;
    }
    if (card.length != 16) {
      _showError('شماره کارت باید ۱۶ رقم باشد.');
      return;
    }

    if (shiba.isEmpty) {
      _showError('لطفاً شماره شبا را وارد کنید.');
      return;
    }
    if (shiba.length != 24 && shiba.length != 26) {
      _showError('شماره شبا باید ۲۴ رقم باشد.');
      return;
    }

    if (bank.isEmpty) {
      _showError('لطفاً نام بانک را وارد کنید.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await auth.updateWelderProfile(
        cardNumber: card.isEmpty ? "" : card,
        shibaNumber: shiba.isEmpty ? "" : shiba,
        bankName: bank.isEmpty ? "" : bank,
      );
      _showSuccess('تنظیمات مالی با موفقیت به‌روزرسانی شد.');
      setState(() {
        _isSaving = false;
        _currentView = ProfileView.menu;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showError('خطا در به‌روزرسانی اطلاعات: ${e.toString().replaceAll('Exception: ', '')}');
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
        _resolveHomeProvinceId();
        _resolveActiveProvinceId();
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

  Future<void> _loadHomeCities(int provinceId) async {
    if (mounted) {
      setState(() {
        _isLoadingHomeCities = true;
        _citiesOfHomeProvince = [];
      });
    }
    try {
      final list = await _apiService.fetchCities(provinceId);
      if (mounted) {
        setState(() {
          _citiesOfHomeProvince = list;
          _isLoadingHomeCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHomeCities = false);
      }
    }
  }

  void _resolveHomeProvinceId() {
    if (_provinces.isEmpty || _homeProvinceName == null) return;
    final matched = _provinces.firstWhere(
      (prov) => (prov['name'] as String).trim() == _homeProvinceName!.trim(),
      orElse: () => null,
    );
    if (matched != null) {
      setState(() {
        _homeProvinceId = matched['id'] as int;
      });
      _loadHomeCities(_homeProvinceId!);
    }
  }

  void _resolveActiveProvinceId() {
    if (_provinces.isEmpty || _activeProvinceName == null) return;
    final matched = _provinces.firstWhere(
      (prov) => (prov['name'] as String).trim() == _activeProvinceName!.trim(),
      orElse: () => null,
    );
    if (matched != null) {
      setState(() {
        _selectedProvinceId = matched['id'] as int;
      });
      _loadCities(_selectedProvinceId!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _cardNumberController.dispose();
    _shibaController.dispose();
    _bankNameController.dispose();
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
    if (_homeCityName == null || _homeCityName!.isEmpty) {
      _showError('لطفاً شهر محل سکونت خود را انتخاب کنید.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final homeProvinceObj = _provinces.firstWhere(
        (prov) => prov['id'] == _homeProvinceId,
        orElse: () => null,
      );
      final homeProvinceName = homeProvinceObj != null ? homeProvinceObj['name'] as String : _homeProvinceName ?? '';

      await auth.updateWelderProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        homeCity: _homeCityName!,
        homeProvince: homeProvinceName,
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
      final activeProvinceObj = _provinces.firstWhere(
        (prov) => prov['id'] == _selectedProvinceId,
        orElse: () => null,
      );
      final activeProvName = activeProvinceObj != null ? activeProvinceObj['name'] as String : _activeProvinceName ?? '';
      await auth.updateWelderProfile(
        activeProvince: activeProvName,
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
    final unitController = TextEditingController(text: 'بند');
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
                      color: AppColors.royalBlue,
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
                          inputFormatters: [
                            PersianPriceInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'مبلغ (تومان)',
                            filled: true,
                            fillColor: AppColors.lightGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'لطفاً مبلغ را وارد کنید';
                            final cleaned = Formatters.cleanNumber(val);
                            if (double.tryParse(cleaned) == null) return 'عدد معتبر وارد کنید';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showUnitPickerBottomSheet(context, unitController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: unitController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'واحد محاسبه',
                                filled: true,
                                fillColor: AppColors.lightGrey,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                       onPressed: () async {
                        if (!bottomFormKey.currentState!.validate()) return;
                        final priceClean = double.parse(Formatters.cleanNumber(priceController.text));
                        final newPrice = {
                          'title': titleController.text.trim(),
                          'unit': unitController.text.trim(),
                          'price_per_unit': priceClean,
                        };

                        // Pop bottom sheet first so overlay is shown on main screen
                        Navigator.pop(context);

                        setState(() {
                          _priceList.add(newPrice);
                          _isSaving = true;
                        });

                        try {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.updateWelderPrices(_priceList);
                          setState(() {
                            _isSaving = false;
                          });
                          _showSuccess('تعرفه با موفقیت اضافه شد.');
                        } catch (e) {
                          setState(() {
                            _isSaving = false;
                          });
                          _showError('خطا در اضافه کردن تعرفه: $e');
                          _populateFields();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
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

  void _showUnitPickerBottomSheet(BuildContext context, TextEditingController controller) {
    final units = ['بند', 'متر', 'عدد', 'کیلوگرم', 'ساعت', 'روز', 'تن', 'پروژه‌ای'];
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderGrey, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: units.length,
                    itemBuilder: (context, idx) {
                      final u = units[idx];
                      final isSelected = controller.text == u;
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
                          controller.text = u;
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
    return PopScope(
      canPop: _currentView == ProfileView.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentView != ProfileView.menu) {
          setState(() => _currentView = ProfileView.menu);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(
            _getViewTitle(),
            style: const TextStyle(color: AppColors.royalBlue, fontSize: 16, fontWeight: FontWeight.bold),
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
                    CircularProgressIndicator(color: AppColors.royalBlue),
                    SizedBox(height: 16),
                    Text('در حال ذخیره‌سازی اطلاعات...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentViewBody(auth),
              ),
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
      case ProfileView.skills:
        return 'مدیریت تخصص‌های جوشکاری';
      case ProfileView.financialInfo:
        return 'تنظیمات مالی';
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
      case ProfileView.skills:
        return _buildSkillsBody();
      case ProfileView.financialInfo:
        return _buildFinancialInfoBody(auth);
    }
  }
  // --- 1. Main Menu View ---
  Widget _buildMainMenuBody(AuthProvider auth) {
    final profile = auth.profileData?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? '';
    final lastName = profile?['last_name'] as String? ?? '';
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
                (() {
                  final profilePicUrl = profile?['profile_picture_url'] as String?;
                  final pendingPicUrl = profile?['pending_profile_picture_url'] as String?;
                  final picStatus = profile?['profile_picture_status'] as String? ?? 'NONE';
                  
                  final ImageProvider? avatarImage;
                  if (picStatus == 'PENDING' && pendingPicUrl != null) {
                    avatarImage = NetworkImage('${ApiService().baseUrl}$pendingPicUrl');
                  } else if (picStatus == 'APPROVED' && profilePicUrl != null) {
                    avatarImage = NetworkImage('${ApiService().baseUrl}$profilePicUrl');
                  } else {
                    avatarImage = null;
                  }

                  // Compute initials
                  String initials = '';
                  if (firstName.isNotEmpty) initials += firstName[0];
                  if (lastName.isNotEmpty) {
                    if (initials.isNotEmpty) initials += '‌';
                    initials += lastName[0];
                  }
                  if (initials.isEmpty) initials = 'ج‌م';

                  void showPhotoOptions() {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (sheetContext) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'مدیریت تصویر پروفایل',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.royalBlue,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.photo_library_outlined, color: AppColors.royalBlue),
                                title: const Text('انتخاب از گالری / فایل‌ها', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _pickProfileImage(auth);
                                },
                              ),
                              if (picStatus != 'NONE') ...[
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                                  title: const Text('حذف تصویر پروفایل', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.red)),
                                  onTap: () async {
                                    Navigator.pop(sheetContext);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: const Text('حذف تصویر پروفایل', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
                                          content: const Text('آیا از حذف عکس پروفایل خود اطمینان دارید؟', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('بله، حذف شود', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    if (confirm == true) {
                                      setState(() => _isSaving = true);
                                      try {
                                        await auth.deleteProfilePicture();
                                        setState(() => _isSaving = false);
                                        _showSuccess('تصویر پروفایل با موفقیت حذف شد.');
                                      } catch (e) {
                                        setState(() => _isSaving = false);
                                        _showError('خطا در حذف تصویر: $e');
                                      }
                                    }
                                  },
                                ),
                              ],
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.close, color: AppColors.textMuted),
                                title: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: AppColors.textMuted)),
                                onTap: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: showPhotoOptions,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: avatarImage != null ? Colors.transparent : AppColors.royalBlue.withValues(alpha: 0.12),
                              backgroundImage: avatarImage,
                              child: avatarImage != null
                                  ? null
                                  : Text(
                                      initials,
                                      style: const TextStyle(
                                        color: AppColors.royalBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: showPhotoOptions,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.royalBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (picStatus == 'PENDING') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amberOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.amberOrange,
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'در انتظار تایید مدیریت',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                              color: AppColors.amberOrange,
                            ),
                          ),
                        ),
                      ] else if (picStatus == 'REJECTED') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red,
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'تصویر رد شده است',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                })(),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.formatPhoneNumber(auth.phoneNumber),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                  textDirection: TextDirection.ltr,
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
            onTap: () {
              _populateFields();
              setState(() => _currentView = ProfileView.personalInfo);
            },
          ),
          _buildMenuTile(
            title: 'مدیریت محدوده فعالیت',
            subtitle: 'انتخاب استان‌ها و اضافه کردن شهرهای خدماتی شما',
            icon: Icons.map_outlined,
            onTap: () {
              _populateFields();
              setState(() => _currentView = ProfileView.coverage);
            },
          ),
          _buildMenuTile(
            title: 'مدیریت تخصص‌ و مهارت‌',
            subtitle: 'ویرایش تخصص‌ها و انواع فرآیندهای جوشکاری مجاز شما',
            icon: Icons.construction_outlined,
            onTap: () {
              _populateFields();
              setState(() => _currentView = ProfileView.skills);
            },
          ),
          _buildMenuTile(
            title: 'مدیریت نرخ‌ها و تعرفه‌ها',
            subtitle: 'تنظیم چندین قیمت پایه برای انواع جوشکاری‌ها',
            icon: Icons.monetization_on_outlined,
            onTap: () {
              _populateFields();
              setState(() => _currentView = ProfileView.rates);
            },
          ),
          _buildMenuTile(
            title: 'تنظیمات مالی',
            subtitle: 'ثبت شماره کارت، شماره شبا و نام بانک جهت تسویه‌حساب',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () {
              _populateFinancialFields();
              setState(() => _currentView = ProfileView.financialInfo);
            },
          ),
          const SizedBox(height: 30),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  FadePageRoute(page: const LoginPhoneScreen(key: ValueKey('LoginPhoneScreen'))),
                  (route) => false,
                );
              },
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
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGrey),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.royalBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.royalBlue, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ),
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
          const Text('اطلاعات هویتی شما:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
          const SizedBox(height: 14),
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
                    filled: true,
                    fillColor: AppColors.white,
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
                    filled: true,
                    fillColor: AppColors.white,
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
              ),
            ],
          ),
          
          // Residence Province Selector
          const SizedBox(height: 14),
          _isLoadingGeo
              ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showHomeProvincePickerBottomSheet,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
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
                                RichText(
                                  text: const TextSpan(
                                    text: 'استان محل سکونت',
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
                                  _provinces.firstWhere(
                                    (prov) => prov['id'] == _homeProvinceId,
                                    orElse: () => {'name': _homeProvinceName ?? 'انتخاب نشده'},
                                  )['name'] as String,
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
                ),

          // Residence City Selector
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _homeProvinceId == null ? null : _showHomeCityPickerBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: _homeProvinceId == null ? 0.5 : 1.0,
                child: Ink(
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
                            RichText(
                              text: const TextSpan(
                                text: 'شهر محل سکونت',
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
                              _homeCityName ?? 'انتخاب نشده',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _homeCityName == null ? AppColors.textMuted : AppColors.textDark,
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
                    const Text(
                      'انتخاب استان محل فعالیت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
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
                    const Text(
                      'انتخاب شهرهای فعال',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
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

  void _showHomeProvincePickerBottomSheet() {
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
                    const Text(
                      'انتخاب استان محل سکونت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
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
                                final isSelected = prov['id'] == _homeProvinceId;
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
                                      _homeProvinceId = prov['id'] as int;
                                      _homeCityName = null; // Clear home city since province changed
                                    });
                                    _loadHomeCities(prov['id'] as int);
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

  void _showHomeCityPickerBottomSheet() {
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
            final filteredCities = _citiesOfHomeProvince.where((city) {
              final cityName = city['name'] as String;
              return cityName.contains(searchFilter);
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
                    const Text(
                      'انتخاب شهر محل سکونت',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                    ),
                    const SizedBox(height: 12),

                    // Search field for cities
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

                    _isLoadingHomeCities
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
                                      final isSelected = _homeCityName == cityName;

                                      return ListTile(
                                        title: Text(
                                          cityName,
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
                                            _homeCityName = cityName;
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
          const Text('انتخاب محدوده جغرافیایی فعالیت:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
          const SizedBox(height: 14),

          // Province Selector Tile
          _isLoadingGeo
              ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showProvincePickerBottomSheet,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
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
                ),
          const SizedBox(height: 12),

          // City Selector Tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectedProvinceId == null ? null : _showCityPickerBottomSheet,
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: _selectedProvinceId == null ? 0.5 : 1.0,
                child: Ink(
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
              const Text('لیست تعرفه‌های ثبت شده:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
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
            Column(
              children: List.generate(_priceList.length, (idx) {
                final item = _priceList[idx];
                final priceFormatted = Formatters.formatPrice(item['price_per_unit']);

                return Container(
                  key: ValueKey(item),
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
                        onPressed: () async {
                          setState(() {
                            _priceList.removeAt(idx);
                            _isSaving = true;
                          });
                          try {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            await auth.updateWelderPrices(_priceList);
                            setState(() {
                              _isSaving = false;
                            });
                            _showSuccess('تعرفه با موفقیت حذف شد.');
                          } catch (e) {
                            setState(() {
                              _isSaving = false;
                            });
                            _showError('خطا در حذف تعرفه: $e');
                            _populateFields();
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
            ),

        ],
      ),
    );
  }

  Widget _buildSkillsBody() {
    final auth = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مدیریت تخصص‌های جوشکاری شما',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.royalBlue,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تخصص‌هایی که بر روی آنها تسلط کامل دارید را انتخاب کنید. حداقل انتخاب یک مورد الزامی است.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.5,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingSkills)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(color: AppColors.royalBlue),
              ),
            )
          else if (_availableSkills.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('خطا در دریافت لیست مهارت‌ها. مجدداً تلاش کنید.'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _availableSkills.map((skill) {
                  final int id = skill['id'];
                  final String name = skill['name'];
                  final isSelected = _selectedSkillIds.contains(id);

                  return ChoiceChip(
                    label: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.white : AppColors.textDark,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.royalBlue,
                    backgroundColor: AppColors.lightGrey,
                    checkmarkColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.royalBlue : AppColors.borderGrey,
                        width: 1,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkillIds.add(id);
                        } else {
                          _selectedSkillIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 35),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                if (_selectedSkillIds.isEmpty) {
                  _showError('لطفاً حداقل یک مهارت را انتخاب کنید.');
                  return;
                }

                setState(() => _isSaving = true);
                try {
                  await auth.updateWelderProfile(
                    skillIds: _selectedSkillIds,
                  );
                  setState(() => _isSaving = false);
                  _showSuccess('مهارت‌های شما با موفقیت به‌روزرسانی شد.');
                  setState(() => _currentView = ProfileView.menu);
                } catch (e) {
                  setState(() => _isSaving = false);
                  _showError('خطا در به‌روزرسانی مهارت‌ها: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : const Text(
                      'ذخیره تخصص‌ها',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoBody(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات حساب مالی جهت تسویه‌حساب',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn', fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Card Number
            const Text(
              'شماره کارت (۱۶ رقمی)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              maxLength: 16,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'مثال: ۶۰۳۷۹۹۱۱۲۲۳۳۴۴۵۵',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
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

            // Shiba Number
            const Text(
              'شماره شبا (۲۴ رقمی - بدون IR)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _shibaController,
              keyboardType: TextInputType.number,
              maxLength: 24,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: 'IR ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                hintText: 'مثال: ۱۲۰۱۲۰۰۰۰۰۰۰۰۱۲۳۴۵۶۷۸۹۰۱',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
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

            // Bank Name
            const Text(
              'نام بانک',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, fontFamily: 'Vazirmatn'),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bankNameController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'مثال: بانک ملی، بانک ملت و ...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _saveFinancialInfo(auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'ذخیره تنظیمات مالی',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vazirmatn'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
