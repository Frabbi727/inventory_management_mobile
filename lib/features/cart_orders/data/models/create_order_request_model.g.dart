// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_order_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrderRequestModel _$CreateOrderRequestModelFromJson(
  Map<String, dynamic> json,
) => CreateOrderRequestModel(
  customerId: (json['customer_id'] as num?)?.toInt(),
  orderDate: json['order_date'] as String?,
  note: json['note'] as String?,
  discountType: json['discount_type'] as String?,
  discountValue: json['discount_value'] as num?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItemRequestModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreateOrderRequestModelToJson(
  CreateOrderRequestModel instance,
) => <String, dynamic>{
  'customer_id': instance.customerId,
  'order_date': instance.orderDate,
  'note': instance.note,
  'discount_type': instance.discountType,
  'discount_value': instance.discountValue,
  'items': instance.items?.map((e) => e.toJson()).toList(),
};
