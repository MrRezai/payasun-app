import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/inquiry.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'https://api.joftojoor.com'});

  /// Request an OTP for a given phone number.
  /// Returns a map containing the message and optionally the otpCode if in debug mode.
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'خطا در ارسال کد تایید');
    }
  }

  /// Verify the OTP code and return the JWT token.
  Future<String> verifyOtp(String phoneNumber, String code, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
        'role': role,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return data['access_token'] as String;
    } else {
      throw Exception(data['message'] ?? 'کد وارد شده صحیح نمی‌باشد');
    }
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch only the logged-in Employer's inquiries.
  Future<List<Inquiry>> fetchMyInquiries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inquiry/my'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Inquiry.fromJson(item)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در دریافت لیست استعلام‌های من');
    }
  }

  /// Fetch all inquiries in the system (welder marketplace feed).
  Future<List<Inquiry>> fetchAllInquiries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inquiry'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Inquiry.fromJson(item)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در دریافت لیست استعلام‌ها');
    }
  }

  /// Create an inquiry.
  Future<Inquiry> createInquiry({
    required String token,
    required String title,
    required String description,
    required String city,
    required String province,
    required bool hasBlueprint,
    required List<InquiryItem> items,
  }) async {
    final body = jsonEncode({
      'title': title,
      'description': description,
      'city': city,
      'province': province,
      'has_blueprint': hasBlueprint,
      'items': items.map((e) => e.toJson()).toList(),
    });

    final response = await http.post(
      Uri.parse('$baseUrl/inquiry'),
      headers: _getHeaders(token),
      body: body,
    );

    if (response.statusCode == 201) {
      return Inquiry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در ثبت استعلام');
    }
  }

  /// Update/Resubmit a rejected or draft inquiry.
  Future<Inquiry> updateInquiry({
    required String token,
    required String inquiryId,
    required String title,
    required String description,
    required String city,
    required String province,
    required List<InquiryItem> items,
  }) async {
    final body = jsonEncode({
      'title': title,
      'description': description,
      'city': city,
      'province': province,
      'items': items.map((e) => e.toJson()).toList(),
    });

    final response = await http.patch(
      Uri.parse('$baseUrl/inquiry/$inquiryId'),
      headers: _getHeaders(token),
      body: body,
    );

    if (response.statusCode == 200) {
      return Inquiry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در ویرایش استعلام');
    }
  }

  /// Upload blueprint file.
  Future<Inquiry> uploadBlueprint({
    required String token,
    required String inquiryId,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/inquiry/$inquiryId/blueprint');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    String ext = filename.split('.').last.toLowerCase();
    MediaType mediaType;
    if (ext == 'pdf') {
      mediaType = MediaType('application', 'pdf');
    } else if (ext == 'png') {
      mediaType = MediaType('image', 'png');
    } else if (ext == 'jpg' || ext == 'jpeg') {
      mediaType = MediaType('image', 'jpeg');
    } else {
      mediaType = MediaType('application', 'octet-stream');
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: mediaType,
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Inquiry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در آپلود فایل پلان');
    }
  }

  /// Fetch authenticated user profile details (User + Role specific details).
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در دریافت اطلاعات پروفایل');
    }
  }

  /// Fetch all available skills configured on the server
  Future<List<dynamic>> fetchSkills(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/skills'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در دریافت لیست مهارت‌ها');
    }
  }

  Future<Map<String, dynamic>> updateWelderProfile(
    String token, {
    String? firstName,
    String? lastName,
    String? homeCity,
    String? homeProvince,
    String? activeProvince,
    List<String>? activeCities,
    String? bio,
    bool? isSetupCompleted,
    List<int>? skillIds,
    String? cardNumber,
    String? shibaNumber,
    String? bankName,
  }) async {
    final bodyMap = <String, dynamic>{};
    if (firstName != null) bodyMap['first_name'] = firstName;
    if (lastName != null) bodyMap['last_name'] = lastName;
    if (homeCity != null) bodyMap['home_city'] = homeCity;
    if (homeProvince != null) bodyMap['home_province'] = homeProvince;
    if (activeProvince != null) bodyMap['active_province'] = activeProvince;
    if (activeCities != null) bodyMap['active_cities'] = activeCities;
    if (bio != null) bodyMap['bio'] = bio;
    if (isSetupCompleted != null) bodyMap['is_setup_completed'] = isSetupCompleted;
    if (skillIds != null) bodyMap['skill_ids'] = skillIds;
    if (cardNumber != null) bodyMap['card_number'] = cardNumber;
    if (shibaNumber != null) bodyMap['shiba_number'] = shibaNumber;
    if (bankName != null) bodyMap['bank_name'] = bankName;

    final response = await http.patch(
      Uri.parse('$baseUrl/profile/welder'),
      headers: _getHeaders(token),
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در به‌روزرسانی پروفایل جوشکار');
    }
  }
  Future<Map<String, dynamic>> updateEmployerProfile(
    String token, {
    String? firstName,
    String? lastName,
    String? province,
    String? city,
    String? companyName,
    String? bio,
    bool? isSetupCompleted,
    String? cardNumber,
    String? shibaNumber,
    String? bankName,
  }) async {
    final bodyMap = <String, dynamic>{};
    if (firstName != null) bodyMap['first_name'] = firstName;
    if (lastName != null) bodyMap['last_name'] = lastName;
    if (province != null) bodyMap['province'] = province;
    if (city != null) bodyMap['city'] = city;
    if (companyName != null) bodyMap['company_name'] = companyName;
    if (bio != null) bodyMap['bio'] = bio;
    if (isSetupCompleted != null) bodyMap['is_setup_completed'] = isSetupCompleted;
    if (cardNumber != null) bodyMap['card_number'] = cardNumber;
    if (shibaNumber != null) bodyMap['shiba_number'] = shibaNumber;
    if (bankName != null) bodyMap['bank_name'] = bankName;

    final response = await http.patch(
      Uri.parse('$baseUrl/profile/employer'),
      headers: _getHeaders(token),
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در به‌روزرسانی پروفایل کارفرما');
    }
  }  /// Overwrites the entire base price list for the Welder.
  Future<Map<String, dynamic>> updateWelderPrices(
    String token,
    List<Map<String, dynamic>> priceList,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/welder/prices'),
      headers: _getHeaders(token),
      body: jsonEncode({'base_price_list': priceList}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در ثبت لیست قیمت‌ها');
    }
  }

  /// Switch the active role of the authenticated user.
  /// Returns the new JWT access token.
  Future<String> switchRole(String token, String targetRole) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/switch-role'),
      headers: _getHeaders(token),
      body: jsonEncode({'role': targetRole}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در تغییر نقش کاربری');
    }
  }

  Future<Inquiry> confirmInquiry(String token, String inquiryId, List<InquiryItem> items) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/inquiry/$inquiryId/confirm'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'items': items.map((i) => {
          'title': i.title,
          'unit': i.unit,
          'quantity': i.quantity,
        }).toList(),
      }),
    );

    if (response.statusCode == 200) {
      return Inquiry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در تایید استعلام');
    }
  }

  /// Fetch all Iranian provinces from Geo API.
  Future<List<dynamic>> fetchProvinces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/geo/provinces'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('خطا در دریافت لیست استان‌ها');
    }
  }

  /// Fetch all cities in a province.
  Future<List<dynamic>> fetchCities(int provinceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/geo/cities/$provinceId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('خطا در دریافت لیست شهرها');
    }
  }

  /// Upload profile picture.
  Future<Map<String, dynamic>> uploadProfilePicture(
    String token,
    List<int> fileBytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/picture'),
    );
    request.headers.addAll(_getHeaders(token));
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در آپلود عکس پروفایل');
    }
  }

  /// Delete profile picture.
  Future<Map<String, dynamic>> deleteProfilePicture(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profile/picture'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در حذف عکس پروفایل');
    }
  }

  /// Submit a price offer for an inquiry.
  Future<void> submitOffer({
    required String token,
    required String inquiryId,
    required double totalPrice,
    required List<Map<String, dynamic>> itemsPrices,
    required bool scaffoldChecked,
    required bool powerChecked,
    required bool rodChecked,
    required bool deliveryChecked,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inquiry/$inquiryId/offer'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'total_price': totalPrice,
        'items_prices': itemsPrices,
        'scaffold_checked': scaffoldChecked,
        'power_checked': powerChecked,
        'rod_checked': rodChecked,
        'delivery_checked': deliveryChecked,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در ثبت پیشنهاد قیمت');
    }
  }

  /// Fetch all offers submitted for a specific inquiry.
  Future<List<dynamic>> fetchOffers({
    required String token,
    required String inquiryId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inquiry/$inquiryId/offers'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'خطا در دریافت لیست پیشنهادها');
    }
  }
}
