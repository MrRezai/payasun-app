import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'employer/employer_dashboard.dart';
import 'employer/inquiry_list_screen.dart';
import 'employer/create_inquiry_screen.dart';
import 'welder/welder_dashboard.dart';
import 'welder/available_jobs_screen.dart';
import 'welder/welder_profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _employerIndex = 0;
  int _welderIndex = 0;

  final List<Widget> _employerScreens = [
    const EmployerDashboard(),
    const InquiryListScreen(),
    const CreateInquiryScreen(),
  ];

  final List<Widget> _welderScreens = [
    const WelderDashboard(),
    const AvailableJobsScreen(),
    const WelderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final activeIndex = auth.isEmployer ? _employerIndex : _welderIndex;
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
                      color: AppColors.burgundy,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            auth.toggleRole();
            // Reset index on switch
            setState(() {
              _employerIndex = 0;
              _welderIndex = 0;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  auth.isEmployer ? Icons.business_center : Icons.construction,
                  size: 16,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  auth.isEmployer ? 'پنل کارفرما' : 'پنل جوشکار',
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
        currentIndex: _employerIndex,
        onTap: (index) {
          setState(() {
            _employerIndex = index;
          });
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
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'استعلام جدید',
          ),
        ],
      );
    } else {
      return BottomNavigationBar(
        currentIndex: _welderIndex,
        onTap: (index) {
          setState(() {
            _welderIndex = index;
          });
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
