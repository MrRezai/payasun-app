import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'employer/employer_dashboard.dart';
import 'employer/inquiry_list_screen.dart';
import 'employer/employer_profile_screen.dart';
import 'welder/welder_dashboard.dart';
import 'welder/available_jobs_screen.dart';
import 'welder/welder_profile_screen.dart';
import 'welder/welder_setup_screen.dart';
import 'employer/employer_setup_screen.dart';
import '../constants/route_transitions.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final List<Widget> _employerScreens = [
    const EmployerDashboard(),
    const InquiryListScreen(),
    const EmployerProfileScreen(),
  ];

  final List<Widget> _welderScreens = [
    const WelderDashboard(),
    const AvailableJobsScreen(),
    const WelderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final activeIndex = auth.isEmployer ? auth.employerTabIndex : auth.welderTabIndex;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.lightGrey,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          shadowColor: AppColors.borderGrey,
          title: Row(
            children: [
              // Logo/App Title Text and Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo/joftojoor.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'جفت‌وجور',
                    style: TextStyle(
                      color: AppColors.royalBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Stylized Role Switcher Button
              _buildRoleSwitcher(auth),
            ],
          ),
        ),
        body: IndexedStack(
          index: activeIndex,
          children: auth.isEmployer ? _employerScreens : _welderScreens,
        ),
        bottomNavigationBar: _buildBottomNavBar(auth),
      ),
    );
  }

  Widget _buildRoleSwitcher(AuthProvider auth) {
    final targetText = auth.isEmployer ? 'پنل جوشکار' : 'پنل کارفرما';
    final targetIcon = auth.isEmployer ? Icons.construction : Icons.business_center;
    final targetColor = auth.isEmployer ? AppColors.burgundy : AppColors.royalBlue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final targetRole = auth.isEmployer ? UserRole.welder : UserRole.employer;
            final targetRoleStr = targetRole == UserRole.welder ? 'WELDER' : 'EMPLOYER';
            final userRoles = auth.profileData?['user']?['roles'] as List<dynamic>? ?? [];

            if (userRoles.contains(targetRoleStr)) {
              // Switch role directly
              _showLoadingDialog(context);
              try {
                await auth.switchUserRole(targetRole);
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  auth.setEmployerTabIndex(0);
                  auth.setWelderTabIndex(0);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar(context, e.toString());
                }
              }
            } else {
              // First time switching to this role -> Show onboarding dialog/bottom sheet
              _showRoleSwitchOnboarding(auth, targetRole);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  targetIcon,
                  size: 16,
                  color: targetColor,
                ),
                const SizedBox(width: 8),
                Text(
                  targetText,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(AuthProvider auth) {
    if (auth.isEmployer) {
      return BottomNavigationBar(
        currentIndex: auth.employerTabIndex,
        onTap: (index) {
          auth.setEmployerTabIndex(index);
        },
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.royalBlue,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'داشبورد',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'استعلام‌ها',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'پروفایل',
          ),
        ],
      );
    } else {
      return BottomNavigationBar(
        currentIndex: auth.welderTabIndex,
        onTap: (index) {
          auth.setWelderTabIndex(index);
        },
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.burgundy,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'داشبورد جوشکار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'فرصت‌های کار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'پروفایل و تعرفه‌ها',
          ),
        ],
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.royalBlue),
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error,
          style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRoleSwitchOnboarding(AuthProvider auth, UserRole targetRole) {
    final isTargetWelder = targetRole == UserRole.welder;
    final title = isTargetWelder ? 'فعال‌سازی پنل جوشکار' : 'فعال‌سازی پنل کارفرما';
    final desc = isTargetWelder
        ? 'شما در حال حاضر به عنوان کارفرما در سیستم ثبت هستید. با فعال‌سازی پنل جوشکاری، می‌توانید مهارت‌ها، تعرفه‌ها و محدوده جغرافیایی خود را ثبت کرده و پروژه‌های جوشکاری را دریافت کنید. نام شما در هر دو پنل هماهنگ خواهد بود.'
        : 'شما در حال حاضر به عنوان جوشکار در سیستم ثبت هستید. با فعال‌سازی پنل کارفرما، می‌توانید استعلام‌ها و نقشه‌های ساختمانی خود را ثبت و برآورد کنید. نام شما در هر دو پنل هماهنگ خواهد بود.';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isTargetWelder ? AppColors.burgundy : AppColors.royalBlue).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTargetWelder ? Icons.construction_outlined : Icons.business_rounded,
                        color: isTargetWelder ? AppColors.burgundy : AppColors.royalBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isTargetWelder ? AppColors.burgundy : AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext); // Close bottom sheet using sheetContext
                          _showLoadingDialog(context);
                           try {
                            await auth.switchUserRole(targetRole);
                            if (mounted) {
                              Navigator.pop(context); // Close loading dialog
                              // Navigate to corresponding Setup Screen
                              if (isTargetWelder) {
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
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              _showErrorSnackBar(context, e.toString());
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTargetWelder ? AppColors.burgundy : AppColors.royalBlue,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('شروع ستاپ و تکمیل اطلاعات', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('انصراف'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
