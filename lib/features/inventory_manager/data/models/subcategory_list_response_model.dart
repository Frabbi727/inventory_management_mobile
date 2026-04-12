import '../../../products/data/models/product_subcategory_model.dart';

class SubcategoryListResponseModel {
  const SubcategoryListResponseModel({
    this.success,
    this.data,
  });

  final bool? success;
  final List<ProductSubcategoryModel>? data;

  factory SubcategoryListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return SubcategoryListResponseModel(
      success: json['success'] as bool?,
      data: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(ProductSubcategoryModel.fromJson)
                .toList()
          : null,
    );
  }
}
