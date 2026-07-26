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
import 'auth/login_phone_screen.dart';
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
              // Active Role Badge & Clean Logout Button
              _buildActiveRoleBadge(auth),
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

  Widget _buildActiveRoleBadge(AuthProvider auth) {
    final roleText = auth.isEmployer ? 'پنل کارفرما' : 'پنل جوشکار';
    final roleColor = auth.isEmployer ? AppColors.royalBlue : AppColors.burgundy;
    final roleIcon = auth.isEmployer ? Icons.business_center : Icons.construction;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 14, color: roleColor),
              const SizedBox(width: 6),
              Text(
                roleText,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () {
            auth.logout();
            Navigator.of(context).pushAndRemoveUntil(
              FadePageRoute(page: const LoginPhoneScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
          tooltip: 'خروج از حساب',
        ),
      ],
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
}
