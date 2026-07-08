import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/route_transitions.dart';
import '../auth/login_phone_screen.dart';

enum ProfileView { menu, personalInfo }

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final ApiService _apiService = ApiService();
  ProfileView _currentView = ProfileView.menu;
  bool _initialized = false;
  bool _isSaving = false;

  // Provinces cache
  List<dynamic> _provinces = [];

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

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final list = await _apiService.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  // Controllers for personal info editing
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _bioController = TextEditingController();

  // Location selector state
  int? _provinceId;
  String? _provinceName;
  String? _cityName;

  // Search variables for bottom sheets
  String _provinceSearchQuery = '';
  String _citySearchQuery = '';
  List<dynamic> _citiesList = [];
  bool _isLoadingCities = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _bioController.dispose();
    super.dispose();
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
          _companyNameController.text = profile['company_name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _cityName = profile['city'];
          _provinceName = profile['province'];
          _initialized = true;
        });
        _resolveProvinceId();
      }
    }
  }

  void _resolveProvinceId() {
    if (_provinceName == null) return;
    try {
      final match = _provinces.firstWhere(
        (element) => element['name'] == _provinceName,
        orElse: () => null,
      );
      if (match != null) {
        setState(() {
          _provinceId = match['id'] as int;
        });
        _loadCitiesForProvince(match['id'] as int);
      }
    } catch (e) {
      debugPrint('Error resolving province ID: $e');
    }
  }

  Future<void> _loadCitiesForProvince(int provId) async {
    setState(() {
      _isLoadingCities = true;
    });
    try {
      final cities = await _apiService.fetchCities(provId);
      setState(() {
        _citiesList = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      debugPrint('Error loading cities: $e');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _savePersonalInfo(AuthProvider auth) async {
    final fName = _firstNameController.text.trim();
    final lName = _lastNameController.text.trim();

    if (fName.isEmpty || lName.isEmpty) {
      _showError('لطفاً نام و نام خانوادگی خود را وارد کنید.');
      return;
    }

    if (_provinceName == null || _cityName == null) {
      _showError('لطفاً استان و شهر محل فعالیت خود را انتخاب کنید.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await auth.updateEmployerProfile(
        firstName: fName,
        lastName: lName,
        companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        province: _provinceName!,
        city: _cityName!,
      );
      
      // Reload profile to refresh the UI
      await auth.loadProfile();
      _showSuccess('اطلاعات هویتی با موفقیت به‌روزرسانی شد.');
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!_initialized && auth.profileData == null) {
      return const Scaffold(
        backgroundColor: AppColors.lightGrey,
        body: Center(child: CircularProgressIndicator(color: AppColors.royalBlue)),
      );
    }

    if (!_initialized && auth.profileData != null) {
      _populateFields();
    }

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _getViewTitle(),
          style: const TextStyle(
            color: AppColors.royalBlue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
          ),
        ),
        centerTitle: true,
        leading: _currentView != ProfileView.menu
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 18),
                onPressed: () => setState(() => _currentView = ProfileView.menu),
              )
            : null,
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.royalBlue),
                  SizedBox(height: 16),
                  Text(
                    'در حال ذخیره‌سازی اطلاعات...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                  ),
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
        return 'حساب کاربری کارفرما';
      case ProfileView.personalInfo:
        return 'ویرایش اطلاعات کارفرما';
    }
  }

  Widget _buildCurrentViewBody(AuthProvider auth) {
    switch (_currentView) {
      case ProfileView.menu:
        return _buildMainMenuBody(auth);
      case ProfileView.personalInfo:
        return _buildPersonalInfoBody(auth);
    }
  }

  Widget _buildMainMenuBody(AuthProvider auth) {
    final profile = auth.profileData?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] ?? '';
    final lastName = profile?['last_name'] ?? '';
    final fullName = (firstName.isEmpty && lastName.isEmpty)
        ? 'کارفرمای مهمان'
        : '$firstName $lastName'.trim();
    final companyName = profile?['company_name'];
    final bio = profile?['bio'] ?? 'توضیحات یا شرح فعالیت برای شما ثبت نشده است.';

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
                  if (initials.isEmpty) initials = 'ک‌م';

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
                            'در انتظار تایید ادمین',
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                if (companyName != null && companyName.toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    companyName.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.royalBlue,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  auth.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5, fontFamily: 'Vazirmatn'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu items list
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderGrey),
            ),
            color: AppColors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                title: const Text(
                  'ویرایش اطلاعات شناسایی کارفرما',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Vazirmatn'),
                ),
                subtitle: const Text(
                  'تغییر نام، شرکت، بیوگرافی و شهر سکونت',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                ),
                leading: const Icon(Icons.person_outline, color: AppColors.royalBlue),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () {
                  _populateFields();
                  setState(() => _currentView = ProfileView.personalInfo);
                },
              ),
            ),
          ),
          const SizedBox(height: 25),

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
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text(
                'خروج از حساب کاربری',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', fontSize: 13),
              ),
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

  Widget _buildPersonalInfoBody(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات هویتی شما:',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn', fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'نام',
                      labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'نام خانوادگی',
                      labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
              decoration: InputDecoration(
                labelText: 'نام شرکت یا کسب و کار (اختیاری)',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                filled: true,
                fillColor: AppColors.lightGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 14),
              decoration: InputDecoration(
                labelText: 'توضیحات و شرح فعالیت شما',
                labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                filled: true,
                fillColor: AppColors.lightGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'محل سکونت / فعالیت کارفرما:',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue, fontFamily: 'Vazirmatn', fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.borderGrey),
                    ),
                    color: AppColors.lightGrey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _showProvincePickerBottomSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _provinceName ?? 'استان',
                                style: TextStyle(
                                  color: _provinceName != null ? AppColors.textDark : AppColors.textMuted,
                                  fontSize: 13,
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: _provinceName != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.borderGrey),
                    ),
                    color: _provinceId == null ? AppColors.lightGrey.withValues(alpha: 0.5) : AppColors.lightGrey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _provinceId == null || _isLoadingCities ? null : _showCityPickerBottomSheet,
                        child: Opacity(
                          opacity: _provinceId == null ? 0.5 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _cityName ?? 'شهر',
                                  style: TextStyle(
                                    color: _cityName != null ? AppColors.textDark : AppColors.textMuted,
                                    fontSize: 13,
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: _cityName != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.borderGrey, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _savePersonalInfo(auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'ذخیره اطلاعات شناسایی',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProvincePickerBottomSheet() {
    setState(() {
      _provinceSearchQuery = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredProvinces = _provinces
                .where((element) => (element['name'] as String).contains(_provinceSearchQuery))
                .toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
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
                      'انتخاب استان',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalBlue,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          _provinceSearchQuery = val;
                        });
                      },
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'جستجوی استان...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderGrey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredProvinces.isEmpty
                          ? const Center(
                              child: Text(
                                'استانی یافت نشد.',
                                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredProvinces.length,
                              itemBuilder: (context, idx) {
                                final prov = filteredProvinces[idx];
                                final isSelected = prov['id'] == _provinceId;
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.royalBlue : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  color: isSelected
                                      ? AppColors.royalBlue.withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      title: Text(
                                        prov['name'] as String,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: AppColors.royalBlue, size: 20)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _provinceId = prov['id'] as int;
                                          _provinceName = prov['name'] as String;
                                          _cityName = null;
                                        });
                                        _loadCitiesForProvince(prov['id'] as int);
                                        Navigator.pop(context);
                                      },
                                    ),
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
    setState(() {
      _citySearchQuery = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCities = _citiesList
                .where((element) => (element['name'] as String).contains(_citySearchQuery))
                .toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
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
                    Text(
                      'انتخاب شهر ($_provinceName)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalBlue,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          _citySearchQuery = val;
                        });
                      },
                      style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'جستجوی شهر...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderGrey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredCities.isEmpty
                          ? const Center(
                              child: Text(
                                'شهری یافت نشد.',
                                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Vazirmatn'),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredCities.length,
                              itemBuilder: (context, idx) {
                                final city = filteredCities[idx];
                                final cityName = city['name'] as String;
                                final isSelected = cityName == _cityName;
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.royalBlue : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  color: isSelected
                                      ? AppColors.royalBlue.withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      title: Text(
                                        cityName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.royalBlue : AppColors.textDark,
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: AppColors.royalBlue, size: 20)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _cityName = cityName;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
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
}
