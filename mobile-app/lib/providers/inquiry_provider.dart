import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inquiry.dart';
import '../models/project.dart';
import '../models/supply_item.dart';
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
  List<Project> _myProjects = [];
  List<SupplyItem> _predefinedItems = [];
  List<Inquiry> _myInquiries = [];
  List<Inquiry> _allInquiries = [];
  List<dynamic> _inquiryOffers = [];
  
  // Selected files state
  final List<BlueprintFile> _selectedFiles = [];

  // Selected expanded project ID for navigation from dashboard
  String? _selectedExpandedProjectId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBlueprint => _hasBlueprint;
  List<InquiryItem> get manualItems => _manualItems;
  List<Project> get myProjects => _myProjects;
  List<SupplyItem> get predefinedItems => _predefinedItems;
  List<Inquiry> get myInquiries => _myInquiries;
  List<Inquiry> get allInquiries => _allInquiries;
  List<dynamic> get inquiryOffers => _inquiryOffers;
  List<BlueprintFile> get selectedFiles => _selectedFiles;
  String? get selectedFileName => _selectedFiles.isNotEmpty ? _selectedFiles.first.name : null;
  List<int>? get selectedFileBytes => _selectedFiles.isNotEmpty ? _selectedFiles.first.bytes : null;
  String? get selectedExpandedProjectId => _selectedExpandedProjectId;

  void setSelectedExpandedProjectId(String? id) {
    _selectedExpandedProjectId = id;
    notifyListeners();
  }

  void clearSelectedExpandedProjectId() {
    _selectedExpandedProjectId = null;
    notifyListeners();
  }

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
    final allowedExts = ['dwg', 'dxf', 'dwf', 'rvt', 'skp', 'ifc', 'pln', 'pdf', 'zip', 'rar', '7z', 'jpg', 'jpeg', 'png', 'webp'];
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExts,
          withData: true,
          allowMultiple: true,
        );
      } catch (e) {
        debugPrint('pickFiles custom fallback: $e');
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExts,
          allowMultiple: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        int rejectedCount = 0;
        for (var file in result.files) {
          if (file.name.isEmpty) continue;

          final ext = file.extension?.toLowerCase() ?? (file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '');
          if (!allowedExts.contains(ext)) {
            rejectedCount++;
            continue;
          }

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

        if (rejectedCount > 0) {
          _errorMessage = 'تعداد $rejectedCount فایل با فرمت غیرمجاز نادیده گرفته شد. فقط فایل‌های نقشه و فنی (DWG, DXF, PDF, ZIP, RAR, JPG, PNG) مجاز می‌باشند.';
        } else {
          _errorMessage = null;
        }
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

  /// Load predefined items
  Future<void> loadPredefinedItems() async {
    try {
      _predefinedItems = await _apiService.fetchPredefinedItems();
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch logged-in employer's projects.
  Future<void> loadMyProjects(String token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _apiService.fetchMyProjects(token);
      _myProjects = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (!silent) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      notifyListeners();
    }
  }

  /// Create a project
  Future<Project?> createProject({
    required String token,
    required String title,
    required String description,
    required String city,
    required String province,
    String? address,
    List<List<int>>? imageBytesList,
    List<String>? imageFilenames,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('لطفاً عنوان پروژه را وارد کنید.');
      if (city.trim().isEmpty) throw Exception('لطفاً شهر محل پروژه را وارد کنید.');
      if (province.trim().isEmpty) throw Exception('لطفاً استان محل پروژه را وارد کنید.');

      Project project = await _apiService.createProject(
        token: token,
        title: title,
        description: description,
        city: city,
        province: province,
        address: address,
      );

      if (imageBytesList != null && imageFilenames != null) {
        for (int i = 0; i < imageBytesList.length && i < 10; i++) {
          final bytes = imageBytesList[i];
          final name = imageFilenames[i];
          if (bytes.isNotEmpty) {
            project = await _apiService.uploadProjectImage(
              token: token,
              projectId: project.id,
              fileBytes: bytes,
              filename: name,
            );
          }
        }
      }

      await loadMyProjects(token);
      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update a project
  Future<Project?> updateProject({
    required String token,
    required String projectId,
    required String title,
    required String description,
    required String city,
    required String province,
    String? address,
    List<String>? existingImageUrls,
    List<List<int>>? newImageBytesList,
    List<String>? newImageFilenames,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('لطفاً عنوان پروژه را وارد کنید.');
      if (city.trim().isEmpty) throw Exception('لطفاً شهر محل پروژه را وارد کنید.');
      if (province.trim().isEmpty) throw Exception('لطفاً استان محل پروژه را وارد کنید.');

      Project project = await _apiService.updateProject(
        token: token,
        projectId: projectId,
        title: title,
        description: description,
        city: city,
        province: province,
        address: address,
        imageUrls: existingImageUrls,
      );

      if (newImageBytesList != null && newImageFilenames != null) {
        for (int i = 0; i < newImageBytesList.length; i++) {
          final bytes = newImageBytesList[i];
          final name = newImageFilenames[i];
          if (bytes.isNotEmpty) {
            project = await _apiService.uploadProjectImage(
              token: token,
              projectId: project.id,
              fileBytes: bytes,
              filename: name,
            );
          }
        }
      }

      await loadMyProjects(token);
      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Delete a project
  Future<bool> deleteProject({
    required String token,
    required String projectId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteProject(token: token, projectId: projectId);
      await loadMyProjects(token);
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

  /// Fetch logged-in employer's inquiries.
  Future<void> loadMyInquiries(String token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _apiService.fetchMyInquiries(token);
      _myInquiries = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (!silent) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      notifyListeners();
    }
  }

  /// Fetch all broadcasted inquiries for welder marketplace feed.
  Future<void> loadAllInquiries(String token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _apiService.fetchAllInquiries(token);
      _allInquiries = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (!silent) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      notifyListeners();
    }
  }

  /// Submit inquiry creation form and synchronize with API.
  Future<Inquiry?> submitInquiry({
    required String token,
    String? projectId,
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
        projectId: projectId,
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
        final lastInquiry = await _processBlueprintFiles(token, inquiry);
        
        await loadMyInquiries(token, silent: true);
        await loadMyProjects(token, silent: true);
        _isLoading = false;
        clearSelectedFiles();
        clearManualItems();
        notifyListeners();
        return lastInquiry;
      }

      await loadMyInquiries(token, silent: true);
      await loadMyProjects(token, silent: true);
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
        final lastInquiry = await _processBlueprintFiles(token, inquiry);
        
        await loadMyInquiries(token, silent: true);
        await loadMyProjects(token, silent: true);
        _isLoading = false;
        clearSelectedFiles();
        clearManualItems();
        notifyListeners();
        return lastInquiry;
      }

      await loadMyInquiries(token, silent: true);
      await loadMyProjects(token, silent: true);
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

  Future<Inquiry?> _processBlueprintFiles(String token, Inquiry inquiry) async {
    Inquiry? lastInquiry = inquiry;
    for (var file in _selectedFiles) {
      if (file.bytes.isEmpty && file.path != null && (file.path!.startsWith('/uploads') || file.path!.startsWith('http'))) {
        lastInquiry = await _apiService.linkExistingBlueprint(
          token: token,
          inquiryId: inquiry.id,
          fileUrl: file.path!,
        );
      } else {
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

        if (bytesToUpload.isNotEmpty) {
          lastInquiry = await _apiService.uploadBlueprint(
            token: token,
            inquiryId: inquiry.id,
            fileBytes: bytesToUpload,
            filename: file.name,
          );
        }
      }
    }
    return lastInquiry;
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
      await loadMyInquiries(token, silent: true);
      await loadMyProjects(token, silent: true);
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

  Future<bool> startAgreement({
    required String token,
    required String inquiryId,
    required String welderId,
  }) async {
    try {
      await _apiService.postWithToken('/inquiry/$inquiryId/start-agreement', {'welderId': welderId}, token);
      _errorMessage = null;
      await loadMyInquiries(token, silent: true);
      await loadAllInquiries(token, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmAgreement({
    required String token,
    required String inquiryId,
  }) async {
    try {
      await _apiService.postWithToken('/inquiry/$inquiryId/confirm-agreement', {}, token);
      _errorMessage = null;
      await loadMyInquiries(token, silent: true);
      await loadAllInquiries(token, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishJob({
    required String token,
    required String inquiryId,
  }) async {
    try {
      await _apiService.postWithToken('/inquiry/$inquiryId/finish-job', {}, token);
      _errorMessage = null;
      await loadMyInquiries(token, silent: true);
      await loadAllInquiries(token, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmCompletion({
    required String token,
    required String inquiryId,
    required String welderId,
    required double qualityScore,
    required double punctualityScore,
    required double behaviorScore,
    String? comment,
  }) async {
    try {
      await _apiService.postWithToken('/inquiry/$inquiryId/confirm-completion', {
        'welderId': welderId,
        'qualityScore': qualityScore,
        'punctualityScore': punctualityScore,
        'behaviorScore': behaviorScore,
        'comment': comment,
      }, token);
      _errorMessage = null;
      await loadMyInquiries(token, silent: true);
      await loadAllInquiries(token, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reDispatch({
    required String token,
    required String inquiryId,
  }) async {
    try {
      await _apiService.postWithToken('/inquiry/$inquiryId/re-dispatch', {}, token);
      _errorMessage = null;
      await loadMyInquiries(token, silent: true);
      await loadAllInquiries(token, silent: true);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
