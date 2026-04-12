class ProductSubcategoryModel {
  const ProductSubcategoryModel({
    this.id,
    this.name,
    this.categoryId,
  });

  final int? id;
  final String? name;
  final int? categoryId;

  factory ProductSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductSubcategoryModel(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      categoryId: _asInt(json['category_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category_id': categoryId,
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
