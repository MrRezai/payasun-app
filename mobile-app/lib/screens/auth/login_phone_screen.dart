import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'verify_otp_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  void _submitPhone() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rawPhone = _phoneController.text.trim();
    final phone = '0$rawPhone';

    try {
      final debugCode = await auth.requestOtp(phone);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              phoneNumber: phone,
              debugCode: debugCode,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا در ارتباط', textDirection: TextDirection.rtl),
            content: Text(_translateError(auth.errorMessage ?? e.toString()), textDirection: TextDirection.rtl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تأیید'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
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
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main Content Body
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Redesigned Image Logo Container
                        _buildImageLogo(),
                        const SizedBox(height: 20),

                        // Title Typography
                        const Text(
                          'جفت‌وجور',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.burgundy,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'سامانه هوشمند استعلام و برآورد جوشکاری',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Input Card Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                            border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ورود یا عضویت سریع',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'شماره موبایل خود را جهت دریافت کد فعال‌سازی وارد کنید.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Dynamic Role Selection tabs
                              _buildRoleSelector(auth),
                              const SizedBox(height: 24),

                              // Form input field
                              _buildPhoneField(),
                              const SizedBox(height: 24),

                              // Primary action button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _submitPhone,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.royalBlue,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'دریافت کد تایید',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Footnote / Terms
                        const Text(
                          'ورود شما به معنای پذیرش قوانین و مقررات جفت‌وجور است.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLogo({double size = 90}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.11),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2), // Slightly rounded corners
        child: Image.asset(
          'assets/logo/joftojoor.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textAlign: TextAlign.left,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        StripLeadingZeroFormatter(),
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'لطفاً شماره موبایل خود را بدون صفر اول وارد کنید';
        }
        if (value.length != 10 || !value.startsWith('9')) {
          return 'شماره موبایل باید ۱۰ رقم و بدون صفر اول باشد (مثال: 9123456789)';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'شماره موبایل (بدون صفر)',
        hintText: 'مثال: 9123456789',
        filled: true,
        fillColor: AppColors.lightGrey,
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
        suffixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 20, color: AppColors.borderGrey),
              const SizedBox(width: 8),
              const Text(
                '+۹۸',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
    );
  }

  Widget _buildRoleSelector(AuthProvider auth) {
    final isEmployer = auth.isEmployer;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Stack(
        children: [
          // Smooth sliding active highlight background
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            alignment: isEmployer ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isEmployer ? AppColors.royalBlue : AppColors.burgundy,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          // Interactive transparent tabs overlay
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => auth.setRole(UserRole.employer),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isEmployer ? AppColors.white : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Vazirmatn',
                      ),
                      child: const Text('ورود به عنوان کارفرما'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => auth.setRole(UserRole.welder),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: !isEmployer ? AppColors.white : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Vazirmatn',
                      ),
                      child: const Text('ورود به عنوان جوشکار'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateError(String? error) {
    if (error == null) return 'خطای نامشخص رخ داده است. لطفاً مجدداً تلاش کنید.';
    
    final err = error.toLowerCase();
    if (err.contains('already registered as welder')) {
      return 'این شماره موبایل قبلاً به عنوان جوشکار ثبت شده است و امکان تغییر نقش وجود ندارد.';
    }
    if (err.contains('already registered as employer')) {
      return 'این شماره موبایل قبلاً به عنوان کارفرما ثبت شده است و امکان تغییر نقش وجود ندارد.';
    }
    if (err.contains('invalid otp') || err.contains('incorrect') || err.contains('not match')) {
      return 'کد تایید وارد شده صحیح نمی‌باشد.';
    }
    if (err.contains('expired')) {
      return 'کد تایید منقضی شده است. لطفاً مجدداً درخواست ارسال کد دهید.';
    }
    if (err.contains('connection refused') || err.contains('failed host lookup') || err.contains('unreachable')) {
      return 'خطا در اتصال به سرور. لطفاً اینترنت خود یا وضعیت سرور بک‌اند را بررسی کنید.';
    }
    return error;
  }
}

class StripLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    while (text.startsWith('0')) {
      text = text.substring(1);
    }
    
    int selectionIndex = newValue.selection.baseOffset - (newValue.text.length - text.length);
    if (selectionIndex < 0) selectionIndex = 0;
    if (selectionIndex > text.length) selectionIndex = text.length;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
