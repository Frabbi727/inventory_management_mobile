// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: (json['id'] as num?)?.toInt(),
  orderNo: json['order_no'] as String?,
  orderDate: json['order_date'] as String?,
  subtotal: json['subtotal'] as num?,
  discountType: json['discount_type'] as String?,
  discountValue: json['discount_value'] as num?,
  discountAmount: json['discount_amount'] as num?,
  grandTotal: json['grand_total'] as num?,
  status: json['status'] as String?,
  note: json['note'] as String?,
  customer: json['customer'] == null
      ? null
      : OrderCustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
  salesman: json['salesman'] == null
      ? null
      : OrderSalesmanModel.fromJson(json['salesman'] as Map<String, dynamic>),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_no': instance.orderNo,
      'order_date': instance.orderDate,
      'subtotal': instance.subtotal,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'discount_amount': instance.discountAmount,
      'grand_total': instance.grandTotal,
      'status': instance.status,
      'note': instance.note,
      'customer': instance.customer?.toJson(),
      'salesman': instance.salesman?.toJson(),
      'items': instance.items?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
