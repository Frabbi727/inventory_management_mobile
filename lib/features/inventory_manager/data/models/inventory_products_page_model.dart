import 'package:json_annotation/json_annotation.dart';

import '../../../products/data/models/product_model.dart';

part 'inventory_products_page_model.g.dart';

@JsonSerializable()
class InventoryProductsPageModel {
  const InventoryProductsPageModel({
    this.data,
    this.currentPage,
    this.perPage,
    this.total,
    this.lastPage,
  });

  @JsonKey(fromJson: _productsFromJson, toJson: _productsToJson)
  final List<ProductModel>? data;

  @JsonKey(name: 'current_page')
  final int? currentPage;

  @JsonKey(name: 'per_page')
  final int? perPage;

  final int? total;

  @JsonKey(name: 'last_page')
  final int? lastPage;

  factory InventoryProductsPageModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryProductsPageModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryProductsPageModelToJson(this);

  static List<ProductModel>? _productsFromJson(List<dynamic>? items) {
    return items
        ?.whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>>? _productsToJson(List<ProductModel>? items) {
    return items?.map((item) => item.toJson()).toList(growable: false);
  }
}
