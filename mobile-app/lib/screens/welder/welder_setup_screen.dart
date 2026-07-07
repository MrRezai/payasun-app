import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WelderSetupScreen extends StatefulWidget {
  const WelderSetupScreen({super.key});

  @override
  State<WelderSetupScreen> createState() => _WelderSetupScreenState();
}

class _WelderSetupScreenState extends State<WelderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _homeCityController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingGeo = true);
    try {
      final list = await _apiService.fetchProvinces();
      setState(() {
        _provinces = list;
        _isLoadingGeo = false;
      });
    } catch (e) {
      setState(() => _isLoadingGeo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در دریافت لیست استان‌ها: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadCities(int provinceId) async {
    setState(() {
      _isLoadingCities = true;
      _citiesOfSelectedProvince = [];
    });
    try {
      final list = await _apiService.fetchCities(provinceId);
      setState(() {
        _citiesOfSelectedProvince = list;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() => _isLoadingCities = false);
      if (mounted) {
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
    _homeCityController.dispose();
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
                    'افزودن تعرفه جوشکاری جدید',
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
                          decoration: InputDecoration(
                            labelText: 'مبلغ (تومان)',
                            hintText: 'مثلاً: ۱۵۰,۰۰۰',
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
                            hintText: 'مثلاً: متر / ساعت / کیلو',
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
                          _customPrices.add({
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

  void _saveSetup() async {
    if (!_formKey.currentState!.validate()) return;

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
      // 1. Update general profile info
      await auth.updateWelderProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        homeCity: _homeCityController.text.trim(),
        activeCities: _selectedCities,
        bio: _bioController.text.trim(),
        isSetupCompleted: true,
      );

      // 2. Update pricing list (if any prices added, otherwise upload default pricing list)
      final priceListToSend = _customPrices.isNotEmpty
          ? _customPrices
          : [
              {'title': 'جوشکاری عمومی برق', 'unit': 'ساعت', 'price_per_unit': 200000.0}
            ];
      await auth.updateWelderPrices(priceListToSend);

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حساب کاربری شما با موفقیت پیکربندی شد. خوش آمدید!'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
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
                  color: AppColors.burgundy.withValues(alpha: 0.03),
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
                          CircularProgressIndicator(color: AppColors.burgundy),
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
                            // Brand Logo at the top
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildImageLogo(76),
                              ),
                            ),

                            // Header Title
                            const Center(
                              child: Text(
                                'تکمیل پروفایل جوشکار جفت‌وجور',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.burgundy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'برای آغاز فعالیت در سیستم، اطلاعات زیر را تکمیل کنید.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Personal info card
                            _buildSectionLabel('اطلاعات شخصی'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'نام (الزامی)',
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      filled: true,
                                      fillColor: AppColors.lightGrey,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'نام الزامی است' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'نام خانوادگی (الزامی)',
                                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                                      filled: true,
                                      fillColor: AppColors.lightGrey,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'نام خانوادگی الزامی است' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _homeCityController,
                              decoration: InputDecoration(
                                labelText: 'شهر محل سکونت (الزامی)',
                                prefixIcon: const Icon(Icons.home_outlined, size: 20),
                                filled: true,
                                fillColor: AppColors.lightGrey,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'وارد کردن شهر محل سکونت الزامی است' : null,
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Geography settings
                            _buildSectionLabel('محدوده خدمات‌رسانی (استان و شهرها) (الزامی)'),
                            const SizedBox(height: 10),
                            _buildGeoSelectorCard(),
                            const SizedBox(height: 25),

                            // Selected cities display
                            if (_selectedCities.isNotEmpty) ...[
                              _buildSectionLabel('شهرهای انتخاب شده شما:'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedCities.map((city) {
                                  return InputChip(
                                    label: Text(city),
                                    onDeleted: () => _removeCity(city),
                                    deleteIconColor: AppColors.burgundy,
                                    labelStyle: const TextStyle(fontSize: 12),
                                    backgroundColor: AppColors.lightGrey,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 25),
                            ],

                            // Bids management
                            _buildSectionLabel('تعرفه‌ها و نرخ‌های دستمزد شما (اختیاری)'),
                            const SizedBox(height: 10),
                            _buildPricesManagerCard(),
                            const SizedBox(height: 35),

                            // Action Button
                            SizedBox(
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

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.burgundy,
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
                  onDeleted: () {
                    setState(() {
                      _selectedCities.remove(cityName);
                    });
                  },
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
                final priceFormatted = priceItem['price_per_unit'].toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );

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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
}
