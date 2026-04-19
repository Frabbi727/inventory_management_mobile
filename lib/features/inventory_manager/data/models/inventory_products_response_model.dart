import 'package:json_annotation/json_annotation.dart';

import 'inventory_products_response_data_model.dart';

part 'inventory_products_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryProductsResponseModel {
  const InventoryProductsResponseModel({this.success, this.data});

  final bool? success;
  final InventoryProductsResponseDataModel? data;

  factory InventoryProductsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryProductsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryProductsResponseModelToJson(this);
}
