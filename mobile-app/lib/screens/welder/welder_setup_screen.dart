import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/route_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../main_shell_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class WelderSetupScreen extends StatefulWidget {
  const WelderSetupScreen({super.key});

  @override
  State<WelderSetupScreen> createState() => _WelderSetupScreenState();
}

class _WelderSetupScreenState extends State<WelderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Profile image picker state
  List<int>? _pickedImageBytes;
  String? _pickedImageName;

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (kIsWeb) {
            _pickedImageBytes = file.bytes;
          } else if (file.path != null) {
            _pickedImageBytes = File(file.path!).readAsBytesSync();
          }
          _pickedImageName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
  final _bioController = TextEditingController();

  // Home location states
  int? _homeProvinceId;
  String? _homeCityName;
  List<dynamic> _citiesOfHomeProvince = [];
  bool _isLoadingHomeCities = false;

  final List<String> _selectedCities = [];
  
  // Custom list of prices/tariffs
  final List<Map<String, dynamic>> _customPrices = [];

  // Geolocation states
  final ApiService _apiService = ApiService();
  List<dynamic> _provinces = [];
  List<dynamic> _citiesOfSelectedProvince = [];
  int? _selectedProvinceId;
  bool _isLoadingGeo = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;

  // Welder skills states
  List<dynamic> _availableSkills = [];
  final List<int> _selectedSkillIds = [];
  bool _isLoadingSkills = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadSkills();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست مهارت‌ها: $e'), backgroundColor: Colors.red),
        );
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
    _bioController.dispose();
    super.dispose();
  }

  void _removeCity(String cityName) {
    setState(() {
      _selectedCities.remove(cityName);
    });
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
                    'افزودن تعرفه جوشکاری جدید',
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
                      hintText: 'مثلاً: جوشکاری اسکلت ساختمان',
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
                            hintText: 'مثلاً: ۱۵۰,۰۰۰',
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
                      onPressed: () {
                        if (!bottomFormKey.currentState!.validate()) return;
                        final priceClean = double.parse(Formatters.cleanNumber(priceController.text));
                        setState(() {
                          _customPrices.add({
                            'title': titleController.text.trim(),
                            'unit': unitController.text.trim(),
                            'price_per_unit': priceClean,
                          });
                        });
                        Navigator.pop(context);
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

  void _saveSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_homeCityName == null || _homeCityName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً شهر محل سکونت خود را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یک مهارت یا تخصص جوشکاری را انتخاب کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یک شهر را به عنوان محدوده فعالیت خود اضافه کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final homeProvinceObj = _provinces.firstWhere(
        (prov) => prov['id'] == _homeProvinceId,
        orElse: () => null,
      );
      final homeProvinceName = homeProvinceObj != null ? homeProvinceObj['name'] as String : '';

      final activeProvinceObj = _provinces.firstWhere(
        (prov) => prov['id'] == _selectedProvinceId,
        orElse: () => null,
      );
      final activeProvinceName = activeProvinceObj != null ? activeProvinceObj['name'] as String : '';

       // 1. Update general profile info
      await auth.updateWelderProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        homeCity: _homeCityName!,
        homeProvince: homeProvinceName,
        activeProvince: activeProvinceName,
        activeCities: _selectedCities,
        bio: _bioController.text.trim(),
        isSetupCompleted: true,
        skillIds: _selectedSkillIds,
      );

      // 1.5 Upload profile picture if picked
      if (_pickedImageBytes != null && _pickedImageName != null) {
        await auth.uploadProfilePicture(_pickedImageBytes!, _pickedImageName!);
      }

      // 2. Update pricing list (pass empty or populated list directly)
      await auth.updateWelderPrices(_customPrices);

      if (mounted) setState(() => _isSaving = false);
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
      if (mounted) setState(() => _isSaving = false);
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

  bool _validateStep0() {
    if (!_formKey.currentState!.validate()) return false;
    if (_homeProvinceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('استان محل سکونت را انتخاب کنید'), backgroundColor: Colors.red),
      );
      return false;
    }
    if (_homeCityName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شهر محل سکونت را انتخاب کنید'), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً حداقل یک مهارت یا تخصص جوشکاری را انتخاب کنید.'), backgroundColor: Colors.red),
      );
      return false;
    }
    if (_selectedCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً حداقل یک شهر را به عنوان محدوده فعالیت خود اضافه کنید.'), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  Widget _buildProfessionalStepper() {
    final steps = [
      {'title': 'اطلاعات شخصی', 'subtitle': 'پروفایل و آدرس'},
      {'title': 'مهارت و محدوده', 'subtitle': 'تخصص‌ها و شهرها'},
      {'title': 'تعرفه خدمات', 'subtitle': 'نرخ‌گذاری و ثبت'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: Row(
              children: [
                // Step indicator circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
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
                        ? const Icon(Icons.check, color: AppColors.white, size: 16)
                        : Text(
                            Formatters.toPersianNumbers((index + 1).toString()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? AppColors.white
                                  : (isActive ? AppColors.royalBlue : AppColors.textMuted),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.textDark : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        steps[index]['subtitle']!,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) ...[
                  // Line connecting steps
                  Container(
                    width: 12,
                    height: 2,
                    color: isCompleted ? AppColors.royalBlue : AppColors.borderGrey,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.borderGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _currentStep == 0
          ? SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_validateStep0()) {
                    setState(() {
                      _currentStep = 1;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'مرحله بعد',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 18),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.royalBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: AppColors.royalBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'مرحله قبل',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.royalBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 1) {
                          if (_validateStep1()) {
                            setState(() {
                              _currentStep = 2;
                            });
                          }
                        } else if (_currentStep == 2) {
                          _saveSetup();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? 'تأیید نهایی و ورود' : 'مرحله بعد',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('اطلاعات شخصی', isRequired: false),
        const SizedBox(height: 10),
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
                validator: (val) => val == null || val.trim().isEmpty ? 'نام الزامی است' : null,
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
                validator: (val) => val == null || val.trim().isEmpty ? 'نام خانوادگی الزامی است' : null,
              ),
            ),
          ],
        ),
        
        // Residence Province Selector
        const SizedBox(height: 14),
        _isLoadingGeo
            ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
            : InkWell(
                onTap: _showHomeProvincePickerBottomSheet,
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
                                orElse: () => {'name': 'انتخاب نشده'},
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

        // Residence City Selector
        const SizedBox(height: 14),
        InkWell(
          onTap: _homeProvinceId == null ? null : _showHomeCityPickerBottomSheet,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: _homeProvinceId == null ? 0.5 : 1.0,
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
        const SizedBox(height: 14),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'معرفی کوتاه / سابقه کاری شما (اختیاری)',
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
        const SizedBox(height: 25),
        _buildProfilePhotoSetupCard(),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('مهارت‌ها و تخصص‌های جوشکاری شما', isRequired: true),
        const SizedBox(height: 10),
        _buildSkillsSelectorCard(),
        const SizedBox(height: 25),

        _buildSectionLabel('محدوده خدمات‌رسانی (استان و شهرها)', isRequired: true),
        const SizedBox(height: 10),
        _buildGeoSelectorCard(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('تعرفه‌ها و نرخ‌های دستمزد شما (اختیاری)'),
        const SizedBox(height: 10),
        _buildPricesManagerCard(),
      ],
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
            : _buildStepNavigationButtons(),
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
                  color: AppColors.royalBlue.withValues(alpha: 0.03),
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
                                  'تکمیل پروفایل جوشکار جفت‌وجور',
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
                                'برای آغاز فعالیت در سیستم، اطلاعات زیر را تکمیل کنید.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stepper Indicator
                            _buildProfessionalStepper(),
                            const SizedBox(height: 25),

                            // Dynamic Step Content
                            IndexedStack(
                              index: _currentStep,
                              children: [
                                _buildStep0(),
                                _buildStep1(),
                                _buildStep2(),
                              ],
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

  Widget _buildSectionLabel(String title, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.royalBlue,
          fontFamily: 'Vazirmatn',
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ]
            : null,
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
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

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
                                      _selectedCities.clear(); // Clear previously selected cities since province changed
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
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

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
                                      final isChecked = _selectedCities.contains(cityName);

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
                                              _selectedCities.add(cityName);
                                            });
                                            setState(() {});
                                          } else {
                                            setSheetState(() {
                                              _selectedCities.remove(cityName);
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
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

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
                    const Divider(color: AppColors.borderGrey, height: 1),
                    const SizedBox(height: 8),

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

  Widget _buildSkillsSelectorCard() {
    if (_isLoadingSkills) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.royalBlue),
        ),
      );
    }

    if (_availableSkills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Center(
          child: Text(
            'خطا در دریافت لیست مهارت‌ها. لطفاً دوباره تلاش کنید.',
            style: TextStyle(fontSize: 12, color: Colors.red, fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    }

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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تخصص‌های خود را از لیست زیر انتخاب کنید (حداقل یک مورد الزامی است):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
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
        ],
      ),
    );
  }

  Widget _buildGeoSelectorCard() {
    final selectedProvince = _provinces.firstWhere(
      (prov) => prov['id'] == _selectedProvinceId,
      orElse: () => null,
    );
    final provinceName = selectedProvince != null ? selectedProvince['name'] as String : 'انتخاب نشده';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'محدوده فعالیت جغرافیایی',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Province Selector Button
          _isLoadingGeo
              ? const Center(child: CircularProgressIndicator(color: AppColors.royalBlue))
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

          // City Selector Button (only visible/enabled when province is selected)
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
                            _selectedCities.isEmpty
                                ? 'هیچ شهری انتخاب نشده است (افزودن...)'
                                : '${_selectedCities.length} شهر انتخاب شده',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedCities.isEmpty ? AppColors.textMuted : AppColors.textDark,
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

          // Selected Cities Chips Display
          if (_selectedCities.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderGrey),
            const SizedBox(height: 8),
            const Text(
              'شهرهای انتخاب‌شده فعال:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCities.map((cityName) {
                return Chip(
                  label: Text(cityName),
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                  labelStyle: const TextStyle(color: AppColors.royalBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.royalBlue, width: 0.5),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.royalBlue),
                  onDeleted: () => _removeCity(cityName),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricesManagerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'لیست تعرفه‌های دستمزد شما:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: _showAddPriceBottomSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('افزودن نرخ جدید', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: AppColors.royalBlue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_customPrices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'هیچ تعرفه‌ای تعریف نشده است. (یک نرخ پیش‌فرض ساخته می‌شود)',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customPrices.length,
              itemBuilder: (context, idx) {
                final priceItem = _customPrices[idx];
                final priceFormatted = Formatters.formatPrice(priceItem['price_per_unit']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_border, color: AppColors.amberOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          priceItem['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ),
                      Text(
                        '$priceFormatted تومان / ${priceItem['unit']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.royalBlue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        onPressed: () {
                          setState(() {
                            _customPrices.removeAt(idx);
                          });
                        },
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

  Widget _buildImageLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/logo/joftojoor.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSetupCard() {
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
                    _pickProfileImage();
                  },
                ),
                if (_pickedImageBytes != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('حذف تصویر', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _pickedImageBytes = null;
                        _pickedImageName = null;
                      });
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('تصویر پروفایل (اختیاری)'),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: showPhotoOptions,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: _pickedImageBytes != null ? Colors.transparent : AppColors.royalBlue.withValues(alpha: 0.12),
                    backgroundImage: _pickedImageBytes != null ? MemoryImage(Uint8List.fromList(_pickedImageBytes!)) : null,
                    child: _pickedImageBytes != null
                        ? null
                        : const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.royalBlue),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: showPhotoOptions,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.royalBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _pickedImageBytes != null ? Icons.edit : Icons.add,
                        color: AppColors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_pickedImageBytes != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Text(
                  'پیش‌نویس تصویر انتخاب شده است',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberOrange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.amberOrange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'داشتن تصویر پروفایل واقعی و باکیفیت، باعث جلب اعتماد بیشتر کارفرمایان و در نتیجه جذب پروژه‌های کاری بیشتر خواهد شد.',
                    style: TextStyle(fontSize: 11, color: AppColors.textDark, height: 1.5, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
