import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inquiry_provider.dart';
import 'screens/main_shell_screen.dart';
import 'screens/auth/login_phone_screen.dart';
import 'screens/welder/welder_setup_screen.dart';
import 'screens/employer/employer_setup_screen.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InquiryProvider()),
      ],
      child: const JoftojoorApp(),
    ),
  );
}

class JoftojoorApp extends StatelessWidget {
  const JoftojoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جفت‌وجور | سامانه هوشمند استعلام جوشکاری',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.royalBlue,
        useMaterial3: true,
        fontFamily: 'Vazirmatn', // Assume modern Vazirmatn font support
        scaffoldBackgroundColor: AppColors.lightGrey,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(
            fontFamily: 'Vazirmatn',
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          Widget child;
          if (!auth.isInitialized) {
            child = const Scaffold(
              key: ValueKey('SplashLoadingScreen'),
              backgroundColor: AppColors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/logo/joftojoor.png'),
                      width: 72,
                      height: 72,
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      color: AppColors.royalBlue,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          } else if (!auth.isAuthenticated) {
            child = const LoginPhoneScreen(key: ValueKey('LoginPhoneScreen'));
          } else if (!auth.isProfileComplete) {
            if (auth.isWelder) {
              child = const WelderSetupScreen(key: ValueKey('WelderSetupScreen'));
            } else {
              child = const EmployerSetupScreen(key: ValueKey('EmployerSetupScreen'));
            }
          } else {
            child = const MainShellScreen(key: ValueKey('MainShellScreen'));
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: child,
          );
        },
      ),
    );
  }
}
