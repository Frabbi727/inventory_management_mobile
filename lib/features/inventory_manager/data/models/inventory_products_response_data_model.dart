import 'package:json_annotation/json_annotation.dart';

import 'inventory_products_page_model.dart';

part 'inventory_products_response_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryProductsResponseDataModel {
  const InventoryProductsResponseDataModel({this.products});

  final InventoryProductsPageModel? products;

  factory InventoryProductsResponseDataModel.fromJson(
    Map<String, dynamic> json,
  ) => _$InventoryProductsResponseDataModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$InventoryProductsResponseDataModelToJson(this);
}
