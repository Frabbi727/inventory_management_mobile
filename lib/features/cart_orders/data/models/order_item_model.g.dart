// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      id: (json['id'] as num?)?.toInt(),
      productId: _nullableIntFromAny(json['product_id']),
      productVariantId: _nullableIntFromAny(json['product_variant_id']),
      productName: json['product_name'] as String?,
      variantLabel: json['variant_label'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitPrice: json['unit_price'] as num?,
      lineTotal: json['line_total'] as num?,
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'product_variant_id': instance.productVariantId,
      'product_name': instance.productName,
      'variant_label': instance.variantLabel,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
    };
