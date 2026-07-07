import 'package:flutter/material.dart';
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

  /// Evaluates if the welder profile contains the minimum necessary onboarding setup.
  /// If they are an EMPLOYER, it returns true by default.
  /// If they are a WELDER, they must have completed the setup.
  bool get isProfileComplete {
    if (_currentRole == UserRole.employer) return true;
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
}
