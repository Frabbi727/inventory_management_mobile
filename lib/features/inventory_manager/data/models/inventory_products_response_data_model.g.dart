// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_products_response_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryProductsResponseDataModel _$InventoryProductsResponseDataModelFromJson(
  Map<String, dynamic> json,
) => InventoryProductsResponseDataModel(
  products: json['products'] == null
      ? null
      : InventoryProductsPageModel.fromJson(
          json['products'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$InventoryProductsResponseDataModelToJson(
  InventoryProductsResponseDataModel instance,
) => <String, dynamic>{'products': instance.products?.toJson()};
