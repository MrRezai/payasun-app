import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inquiry.dart';
import '../services/api_service.dart';

class InquiryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasBlueprint = false;
  final List<InquiryItem> _manualItems = [];
  
  // Lists
  List<Inquiry> _myInquiries = [];
  List<Inquiry> _allInquiries = [];
  
  // Selected file state
  List<int>? _selectedFileBytes;
  String? _selectedFileName;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBlueprint => _hasBlueprint;
  List<InquiryItem> get manualItems => _manualItems;
  List<Inquiry> get myInquiries => _myInquiries;
  List<Inquiry> get allInquiries => _allInquiries;
  List<int>? get selectedFileBytes => _selectedFileBytes;
  String? get selectedFileName => _selectedFileName;

  void setHasBlueprint(bool value) {
    _hasBlueprint = value;
    notifyListeners();
  }

  void addManualItem(String title, String unit, double quantity) {
    _manualItems.add(InquiryItem(title: title, unit: unit, quantity: quantity));
    notifyListeners();
  }

  void removeManualItem(int index) {
    if (index >= 0 && index < _manualItems.length) {
      _manualItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearManualItems() {
    _manualItems.clear();
    notifyListeners();
  }

  Future<bool> pickBlueprintFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'dwg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _selectedFileBytes = file.bytes;
        _selectedFileName = file.name;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'خطا در انتخاب فایل: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearSelectedFile() {
    _selectedFileBytes = null;
    _selectedFileName = null;
    notifyListeners();
  }

  /// Fetch logged-in employer's inquiries.
  Future<void> loadMyInquiries(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myInquiries = await _apiService.fetchMyInquiries(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Fetch all broadcasted inquiries for welder marketplace feed.
  Future<void> loadAllInquiries(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allInquiries = await _apiService.fetchAllInquiries(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Submit inquiry creation form and synchronize with API.
  Future<Inquiry?> submitInquiry({
    required String token,
    required String title,
    required String description,
    required String city,
    required String province,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('لطفاً عنوان استعلام را وارد کنید.');
      if (description.trim().isEmpty) throw Exception('لطفاً توضیحات استعلام را وارد کنید.');
      if (city.trim().isEmpty) throw Exception('لطفاً شهر محل پروژه را وارد کنید.');
      if (province.trim().isEmpty) throw Exception('لطفاً استان محل پروژه را وارد کنید.');
      
      if (_hasBlueprint) {
        if (_selectedFileBytes == null || _selectedFileName == null) {
          throw Exception('لطفاً ابتدا فایل پلان را انتخاب کنید.');
        }
      } else {
        if (_manualItems.isEmpty) {
          throw Exception('لطفاً حداقل یک قلم کالا یا خدمات وارد کنید.');
        }
      }

      final inquiry = await _apiService.createInquiry(
        token: token,
        title: title,
        description: description,
        city: city,
        province: province,
        hasBlueprint: _hasBlueprint,
        items: _hasBlueprint ? [] : _manualItems,
      );

      if (_hasBlueprint && _selectedFileBytes != null && _selectedFileName != null) {
        final updatedInquiry = await _apiService.uploadBlueprint(
          token: token,
          inquiryId: inquiry.id,
          fileBytes: _selectedFileBytes!,
          filename: _selectedFileName!,
        );
        
        await loadMyInquiries(token);
        _isLoading = false;
        clearSelectedFile();
        clearManualItems();
        notifyListeners();
        return updatedInquiry;
      }

      await loadMyInquiries(token);
      _isLoading = false;
      clearManualItems();
      notifyListeners();
      return inquiry;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmInquiry({
    required String token,
    required String inquiryId,
    required List<InquiryItem> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.confirmInquiry(token, inquiryId, items);
      await loadMyInquiries(token);
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
}
