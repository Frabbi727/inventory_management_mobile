import 'package:json_annotation/json_annotation.dart';

import 'product_category_model.dart';
import 'product_unit_model.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  const ProductModel({
    this.id,
    this.name,
    this.sku,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
    this.currentStock,
    this.category,
    this.unit,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? name;
  final String? sku;

  @JsonKey(name: 'purchase_price')
  final num? purchasePrice;

  @JsonKey(name: 'selling_price')
  final num? sellingPrice;

  @JsonKey(name: 'minimum_stock_alert')
  final int? minimumStockAlert;

  final String? status;

  @JsonKey(name: 'current_stock')
  final int? currentStock;

  final ProductCategoryModel? category;
  final ProductUnitModel? unit;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
