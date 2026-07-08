class InquiryItem {
  final String title;
  final String unit;
  final double quantity;

  InquiryItem({
    required this.title,
    required this.unit,
    required this.quantity,
  });

  factory InquiryItem.fromJson(Map<String, dynamic> json) {
    return InquiryItem(
      title: json['title'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      quantity: (json['quantity'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'unit': unit,
      'quantity': quantity,
    };
  }
}

class Inquiry {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String city;
  final String? province;
  final String status;
  final bool hasBlueprint;
  final String? blueprintUrl;
  final List<InquiryItem> items;
  final DateTime createdAt;

  Inquiry({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.city,
    this.province,
    required this.status,
    required this.hasBlueprint,
    this.blueprintUrl,
    required this.items,
    required this.createdAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<InquiryItem> parsedItems = itemsList.map((i) => InquiryItem.fromJson(i as Map<String, dynamic>)).toList();

    return Inquiry(
      id: json['id'] as String? ?? '',
      employerId: json['employerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      hasBlueprint: json['has_blueprint'] as bool? ?? false,
      blueprintUrl: json['blueprint_url'] as String?,
      items: parsedItems,
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
      'status': status,
      'has_blueprint': hasBlueprint,
      'blueprint_url': blueprintUrl,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
