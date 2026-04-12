class ProductVariantAttributeModel {
  const ProductVariantAttributeModel({
    this.id,
    this.name,
    this.values,
  });

  final int? id;
  final String? name;
  final List<String>? values;

  factory ProductVariantAttributeModel.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    return ProductVariantAttributeModel(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      values: rawValues is List
          ? rawValues.map((value) => value?.toString() ?? '').toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'values': values,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
