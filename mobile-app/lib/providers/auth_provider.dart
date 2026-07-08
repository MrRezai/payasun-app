import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum UserRole { employer, welder }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserRole _currentRole = UserRole.employer;
  String? _token;
  String? _phoneNumber;
  bool _isLoading = false;
  String? _errorMessage;

  // Profile data cache
  Map<String, dynamic>? _profileData;
  bool _isProfileLoaded = false;

  int _employerTabIndex = 0;
  int _welderTabIndex = 0;

  AuthProvider() {
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedPhone = prefs.getString('auth_phone');
      final savedRole = prefs.getString('auth_role');

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        _phoneNumber = savedPhone;
        if (savedRole == 'WELDER') {
          _currentRole = UserRole.welder;
        } else {
          _currentRole = UserRole.employer;
        }
        notifyListeners();
        
        try {
          await loadProfile();
        } catch (e) {
          debugPrint('Error loading profile in auto-login: $e');
          if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
            logout();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading persisted auth data: $e');
    }
  }

  Future<void> _savePersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      } else {
        await prefs.remove('auth_token');
      }
      if (_phoneNumber != null) {
        await prefs.setString('auth_phone', _phoneNumber!);
      } else {
        await prefs.remove('auth_phone');
      }
      await prefs.setString('auth_role', _currentRole == UserRole.welder ? 'WELDER' : 'EMPLOYER');
    } catch (e) {
      debugPrint('Error persisting auth data: $e');
    }
  }

  // Getters
  UserRole get currentRole => _currentRole;
  String get token => _token ?? '';
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String get phoneNumber => _phoneNumber ?? '';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmployer => _currentRole == UserRole.employer;
  bool get isWelder => _currentRole == UserRole.welder;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isProfileLoaded => _isProfileLoaded;

  int get employerTabIndex => _employerTabIndex;
  int get welderTabIndex => _welderTabIndex;

  void setEmployerTabIndex(int index) {
    _employerTabIndex = index;
    notifyListeners();
  }

  void setWelderTabIndex(int index) {
    _welderTabIndex = index;
    notifyListeners();
  }

  /// Evaluates if the welder profile contains the minimum necessary onboarding setup.
  /// If they are an EMPLOYER, it returns true by default.
  /// If they are a WELDER, they must have completed the setup.
  bool get isProfileComplete {
    if (_profileData == null) return false;
    
    final profile = _profileData!['profile'] as Map<String, dynamic>?;
    if (profile == null) return false;
    
    return profile['is_setup_completed'] == true;
  }

  void toggleRole() {
    if (_currentRole == UserRole.employer) {
      _currentRole = UserRole.welder;
    } else {
      _currentRole = UserRole.employer;
    }
    notifyListeners();
  }

  Future<void> switchUserRole(UserRole targetRole) async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final roleStr = targetRole == UserRole.employer ? 'EMPLOYER' : 'WELDER';
      final newToken = await _apiService.switchRole(_token!, roleStr);
      _token = newToken;
      _currentRole = targetRole;
      _isProfileLoaded = false;
      await _savePersistedData();
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _phoneNumber = null;
    _profileData = null;
    _isProfileLoaded = false;
    _errorMessage = null;
    _savePersistedData();
    notifyListeners();
  }

  /// Request OTP from backend API.
  /// If in debug mode, returns the otpCode directly for easy copy-pasting.
  Future<String?> requestOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.sendOtp(phone);
      _phoneNumber = phone;
      await _savePersistedData();
      _isLoading = false;
      notifyListeners();

      // Read otpCode if present (debug mode)
      if (response.containsKey('otpCode')) {
        return response['otpCode']?.toString();
      }
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Verify OTP and receive authentication token.
  Future<bool> verifyOtpCode(String code) async {
    if (_phoneNumber == null) {
      _errorMessage = 'شماره موبایل یافت نشد. مجدداً تلاش کنید.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final roleStr = _currentRole == UserRole.employer ? 'EMPLOYER' : 'WELDER';
      final tokenResult = await _apiService.verifyOtp(_phoneNumber!, code, roleStr);
      _token = tokenResult;
      await _savePersistedData();
      
      // Load user profile details immediately on login to verify onboarding status
      await loadProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Fetch user profile details.
  Future<void> loadProfile() async {
    if (_token == null) return;
    try {
      final data = await _apiService.fetchProfile(_token!);
      _profileData = data;
      _isProfileLoaded = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Update welder profile details.
  Future<void> updateWelderProfile({
    String? firstName,
    String? lastName,
    String? homeCity,
    String? homeProvince,
    String? activeProvince,
    List<String>? activeCities,
    String? bio,
    bool? isSetupCompleted,
  }) async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateWelderProfile(
        _token!,
        firstName: firstName,
        lastName: lastName,
        homeCity: homeCity,
        homeProvince: homeProvince,
        activeProvince: activeProvince,
        activeCities: activeCities,
        bio: bio,
        isSetupCompleted: isSetupCompleted,
      );
      // Reload profile
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Update employer profile details.
  Future<void> updateEmployerProfile({
    String? firstName,
    String? lastName,
    String? province,
    String? city,
    String? companyName,
    String? bio,
    bool? isSetupCompleted,
  }) async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateEmployerProfile(
        _token!,
        firstName: firstName,
        lastName: lastName,
        province: province,
        city: city,
        companyName: companyName,
        bio: bio,
        isSetupCompleted: isSetupCompleted,
      );
      // Reload profile
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Update welder base price list.
  Future<void> updateWelderPrices(List<Map<String, dynamic>> priceList) async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateWelderPrices(_token!, priceList);
      // Reload profile
      await loadProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Upload profile picture.
  Future<void> uploadProfilePicture(List<int> fileBytes, String filename) async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.uploadProfilePicture(_token!, fileBytes, filename);
      _profileData = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Delete profile picture.
  Future<void> deleteProfilePicture() async {
    if (_token == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.deleteProfilePicture(_token!);
      _profileData = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
