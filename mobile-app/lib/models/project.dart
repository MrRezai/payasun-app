import 'inquiry.dart';

class Project {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String city;
  final String? province;
  final String? address;
  final List<String> imageUrls;
  final List<Inquiry> inquiries;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.city,
    this.province,
    this.address,
    required this.imageUrls,
    required this.inquiries,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var rawImages = json['image_urls'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    } else if (rawImages is String && rawImages.isNotEmpty) {
      images = rawImages.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    var rawInquiries = json['inquiries'] as List? ?? [];
    List<Inquiry> parsedInquiries = rawInquiries
        .map((i) => Inquiry.fromJson(i as Map<String, dynamic>))
        .toList();

    return Project(
      id: json['id'] as String? ?? '',
      employerId: json['employerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String?,
      address: json['address'] as String?,
      imageUrls: images,
      inquiries: parsedInquiries,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employerId': employerId,
      'title': title,
      'description': description,
      'city': city,
      'province': province,
      'address': address,
      'image_urls': imageUrls,
      'inquiries': inquiries.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
