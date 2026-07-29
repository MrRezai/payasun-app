class SupplyItem {
  final int id;
  final String title;
  final String unit;

  SupplyItem({
    required this.id,
    required this.title,
    required this.unit,
  });

  factory SupplyItem.fromJson(Map<String, dynamic> json) {
    return SupplyItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
    };
  }
}
