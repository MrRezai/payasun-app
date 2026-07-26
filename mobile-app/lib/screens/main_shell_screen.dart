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
        ),
        body: IndexedStack(
          index: activeIndex,
          children: auth.isEmployer ? _employerScreens : _welderScreens,
        ),
        bottomNavigationBar: _buildBottomNavBar(auth),
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
}
