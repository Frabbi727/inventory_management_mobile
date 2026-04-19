// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_products_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryProductsResponseModel _$InventoryProductsResponseModelFromJson(
  Map<String, dynamic> json,
) => InventoryProductsResponseModel(
  success: json['success'] as bool?,
  data: json['data'] == null
      ? null
      : InventoryProductsResponseDataModel.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$InventoryProductsResponseModelToJson(
  InventoryProductsResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data?.toJson(),
};
