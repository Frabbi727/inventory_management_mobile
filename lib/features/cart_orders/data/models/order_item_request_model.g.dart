// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemRequestModel _$OrderItemRequestModelFromJson(
  Map<String, dynamic> json,
) => OrderItemRequestModel(
  productId: (json['product_id'] as num?)?.toInt(),
  productVariantId: (json['product_variant_id'] as num?)?.toInt(),
  quantity: (json['quantity'] as num?)?.toInt(),
);

Map<String, dynamic> _$OrderItemRequestModelToJson(
  OrderItemRequestModel instance,
) => <String, dynamic>{
  'product_id': instance.productId,
  'product_variant_id': instance.productVariantId,
  'quantity': instance.quantity,
};
