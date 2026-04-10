import '../../../products/data/models/product_unit_model.dart';

class ProductUnitListResponseModel {
  const ProductUnitListResponseModel({this.success, this.data});

  final bool? success;
  final List<ProductUnitModel>? data;

  factory ProductUnitListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ProductUnitListResponseModel(
      success: json['success'] as bool?,
      data: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(ProductUnitModel.fromJson)
                .toList()
          : null,
    );
  }
}
