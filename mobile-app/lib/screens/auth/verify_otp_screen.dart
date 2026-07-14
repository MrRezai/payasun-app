import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../main_shell_screen.dart';
import '../welder/welder_setup_screen.dart';
import '../employer/employer_setup_screen.dart';
import '../../constants/route_transitions.dart';
import '../../utils/formatters.dart';
class VerifyOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? debugCode;

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    this.debugCode,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const int totalSeconds = 120; // 2 minutes countdown
  int _secondsRemaining = totalSeconds;
  Timer? _timer;

  // 5 digits verification code
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = totalSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTimer() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _resendCode() async {
    if (_secondsRemaining > 0) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final newDebug = await auth.requestOtp(widget.phoneNumber);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newDebug != null ? 'کد جدید ارسال شد: $newDebug' : 'کد جدید با موفقیت پیامک شد.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.royalBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translateError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _submitCode() async {
    final rawCode = _controllers.map((c) => c.text).join();
    final code = Formatters.cleanNumber(rawCode);
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً کد تایید ۵ رقمی را کامل وارد کنید.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyOtpCode(code);

    if (success && mounted) {
      if (!auth.isProfileComplete) {
        if (auth.isWelder) {
          Navigator.pushAndRemoveUntil(
            context,
            FadePageRoute(page: const WelderSetupScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            FadePageRoute(page: const EmployerSetupScreen()),
            (route) => false,
          );
        }
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          FadePageRoute(page: const MainShellScreen()),
          (route) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translateError(auth.errorMessage ?? 'کد وارد شده صحیح نمی‌باشد')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
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
            // Localized positioned back button (aligned right for RTL)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Redesigned Image Logo Header for visual consistency
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

                      // Code Input Card
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
                          children: [
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'تایید شماره موبایل',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Subtitle showing phone number with Edit option
                            Row(
                              children: [
                                Text(
                                  'کد تایید به شماره ${widget.phoneNumber} ارسال شد.',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'ویرایش شماره',
                                    style: TextStyle(
                                      color: AppColors.royalBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Offline/Debug mode code alert badge
                            if (widget.debugCode != null) ...[
                              _buildDebugAlert(widget.debugCode!),
                              const SizedBox(height: 20),
                            ],

                            // OTP Grid Input
                            _buildOtpGrid(),
                            const SizedBox(height: 24),

                            // Countdown Timer & Resend code triggers
                            _buildTimerSection(),
                            const SizedBox(height: 24),

                            // Verification Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submitCode,
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
                                        'بررسی کد تایید',
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

  Widget _buildDebugAlert(String debugCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report_outlined, color: AppColors.amberOrange, size: 16),
          const SizedBox(width: 8),
          Text(
            'حالت تست آفلاین: از کد تایید $debugCode استفاده کنید',
            style: const TextStyle(
              color: AppColors.amberOrange,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpGrid() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return SizedBox(
            width: 48,
            height: 52,
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                PersianDigitsFormatter(),
                LengthLimitingTextInputFormatter(1),
              ],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.burgundy,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.lightGrey,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 4) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                    _submitCode();
                  }
                } else {
                  if (index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimerSection() {
    final timerActive = _secondsRemaining > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timerActive) ...[
          const Icon(Icons.timer_outlined, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            _formatTimer(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'تا امکان ارسال مجدد کد',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ] else ...[
          TextButton(
            onPressed: _resendCode,
            child: const Text(
              'ارسال مجدد کد تایید',
              style: TextStyle(
                color: AppColors.amberOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ]
      ],
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
