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
  final String? projectId;
  final String employerId;
  final String title;
  final String description;
  final String city;
  final String? province;
  final String? address;
  final String status;
  final bool hasBlueprint;
  final String? blueprintUrl;
  final String? estimationType;
  final String? rejectionReason;
  final List<InquiryItem> items;
  final DateTime createdAt;

  final List<dynamic>? offers;
  final double? depositAmount;
  final DateTime? updatedAt;
  final DateTime? dispatchedAt;
  final String? welderId;

  Inquiry({
    required this.id,
    this.projectId,
    required this.employerId,
    required this.title,
    required this.description,
    required this.city,
    this.province,
    this.address,
    required this.status,
    required this.hasBlueprint,
    this.blueprintUrl,
    this.estimationType,
    this.rejectionReason,
    required this.items,
    required this.createdAt,
    this.offers,
    this.depositAmount,
    this.updatedAt,
    this.dispatchedAt,
    this.welderId,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<InquiryItem> parsedItems = itemsList.map((i) => InquiryItem.fromJson(i as Map<String, dynamic>)).toList();

    return Inquiry(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String?,
      employerId: json['employerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      hasBlueprint: json['has_blueprint'] as bool? ?? false,
      blueprintUrl: json['blueprint_url'] as String?,
      estimationType: json['estimation_type'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      items: parsedItems,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      offers: json['offers'] as List<dynamic>?,
      depositAmount: double.tryParse(json['deposit_amount']?.toString() ?? ''),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      dispatchedAt: json['dispatched_at'] != null ? DateTime.tryParse(json['dispatched_at'] as String) : null,
      welderId: json['welderId'] as String? ?? json['welder_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'employerId': employerId,
      'title': title,
      'description': description,
      'city': city,
      'province': province,
      'address': address,
      'status': status,
      'has_blueprint': hasBlueprint,
      'blueprint_url': blueprintUrl,
      'estimation_type': estimationType,
      'rejection_reason': rejectionReason,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'offers': offers,
    };
  }
}
