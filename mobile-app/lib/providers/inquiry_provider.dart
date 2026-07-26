import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inquiry.dart';
import '../services/api_service.dart';

class BlueprintFile {
  final String name;
  final List<int> bytes;
  final String? path;

  BlueprintFile({required this.name, required this.bytes, this.path});
}

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
  List<dynamic> _inquiryOffers = [];
  
  // Selected files state
  final List<BlueprintFile> _selectedFiles = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBlueprint => _hasBlueprint;
  List<InquiryItem> get manualItems => _manualItems;
  List<Inquiry> get myInquiries => _myInquiries;
  List<Inquiry> get allInquiries => _allInquiries;
  List<dynamic> get inquiryOffers => _inquiryOffers;
  List<BlueprintFile> get selectedFiles => _selectedFiles;
  String? get selectedFileName => _selectedFiles.isNotEmpty ? _selectedFiles.first.name : null;
  List<int>? get selectedFileBytes => _selectedFiles.isNotEmpty ? _selectedFiles.first.bytes : null;

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

  Future<bool> pickBlueprintFiles() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
          allowMultiple: true,
        );
      } catch (e) {
        debugPrint('pickFiles withData fallback: $e');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.name.isEmpty) continue;

          List<int>? bytes = file.bytes;
          String? filePath;
          if (!kIsWeb) {
            try {
              filePath = file.path;
            } catch (_) {}
          }

          if (!kIsWeb && (bytes == null || bytes.isEmpty) && filePath != null && filePath.isNotEmpty) {
            try {
              final f = io.File(filePath);
              if (await f.exists()) {
                bytes = await f.readAsBytes();
              }
            } catch (e) {
              debugPrint('Error reading file bytes from path: $e');
            }
          }

          final exists = _selectedFiles.any((f) => f.name == file.name);
          if (!exists) {
            _selectedFiles.add(BlueprintFile(
              name: file.name,
              bytes: bytes ?? [],
              path: filePath,
            ));
          }
        }
        _errorMessage = null;
        notifyListeners();
        return _selectedFiles.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Error in pickBlueprintFiles: $e');
      _errorMessage = 'خطا در انتخاب فایل‌ها: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void removeSelectedFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      _selectedFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearSelectedFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void loadExistingBlueprintUrls(String? blueprintUrlString) {
    _selectedFiles.clear();
    if (blueprintUrlString == null || blueprintUrlString.trim().isEmpty) {
      notifyListeners();
      return;
    }

    final urls = blueprintUrlString.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty);
    for (var url in urls) {
      final fileName = url.split('/').last;
      _selectedFiles.add(BlueprintFile(
        name: fileName,
        bytes: [],
        path: url,
      ));
    }
    notifyListeners();
  }

  void clearSelectedFile() {
    clearSelectedFiles();
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
    String? address,
    String? estimationType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('لطفاً عنوان استعلام را وارد کنید.');
      if (city.trim().isEmpty) throw Exception('لطفاً شهر محل پروژه را وارد کنید.');
      if (province.trim().isEmpty) throw Exception('لطفاً استان محل پروژه را وارد کنید.');
      
      if (_hasBlueprint) {
        if (_selectedFiles.isEmpty) {
          throw Exception('لطفاً حداقل یک فایل پلان/نقشه انتخاب کنید.');
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
        address: address,
        hasBlueprint: _hasBlueprint,
        estimationType: estimationType,
        items: _hasBlueprint ? [] : _manualItems,
      );

      if (_hasBlueprint && _selectedFiles.isNotEmpty) {
        Inquiry? lastInquiry = inquiry;
        for (var file in _selectedFiles) {
          List<int> bytesToUpload = file.bytes;
          if (bytesToUpload.isEmpty && file.path != null && file.path!.isNotEmpty && !kIsWeb) {
            try {
              final f = io.File(file.path!);
              if (await f.exists()) {
                bytesToUpload = await f.readAsBytes();
              }
            } catch (e) {
              debugPrint('Error reading bytes for upload: $e');
            }
          }

          lastInquiry = await _apiService.uploadBlueprint(
            token: token,
            inquiryId: inquiry.id,
            fileBytes: bytesToUpload,
            filename: file.name,
          );
        }
        
        await loadMyInquiries(token);
        _isLoading = false;
        clearSelectedFiles();
        clearManualItems();
        notifyListeners();
        return lastInquiry;
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

  /// Update/Resubmit inquiry creation form and synchronize with API.
  Future<Inquiry?> updateInquiry({
    required String token,
    required String inquiryId,
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

      if (!_hasBlueprint && _manualItems.isEmpty) {
        throw Exception('لطفاً حداقل یک قلم کالا یا خدمات وارد کنید.');
      }

      final inquiry = await _apiService.updateInquiry(
        token: token,
        inquiryId: inquiryId,
        title: title,
        description: description,
        city: city,
        province: province,
        items: _hasBlueprint ? [] : _manualItems,
      );

      if (_hasBlueprint && _selectedFiles.isNotEmpty) {
        Inquiry? lastInquiry = inquiry;
        for (var file in _selectedFiles) {
          lastInquiry = await _apiService.uploadBlueprint(
            token: token,
            inquiryId: inquiry.id,
            fileBytes: file.bytes,
            filename: file.name,
          );
        }
        
        await loadMyInquiries(token);
        _isLoading = false;
        clearSelectedFiles();
        clearManualItems();
        notifyListeners();
        return lastInquiry;
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

  Future<bool> submitOffer({
    required String token,
    required String inquiryId,
    required double totalPrice,
    required List<Map<String, dynamic>> itemsPrices,
    required bool scaffoldChecked,
    required bool powerChecked,
    required bool rodChecked,
    required bool deliveryChecked,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.submitOffer(
        token: token,
        inquiryId: inquiryId,
        totalPrice: totalPrice,
        itemsPrices: itemsPrices,
        scaffoldChecked: scaffoldChecked,
        powerChecked: powerChecked,
        rodChecked: rodChecked,
        deliveryChecked: deliveryChecked,
      );
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

  Future<void> loadInquiryOffers({
    required String token,
    required String inquiryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inquiryOffers = await _apiService.fetchOffers(
        token: token,
        inquiryId: inquiryId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _inquiryOffers = [];
      notifyListeners();
    }
  }
}
