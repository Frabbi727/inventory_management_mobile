import 'package:json_annotation/json_annotation.dart';

import 'order_customer_model.dart';
import 'order_item_model.dart';
import 'order_salesman_model.dart';

part 'order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderModel {
  const OrderModel({
    this.id,
    this.orderNo,
    this.orderDate,
    this.intendedDeliveryAt,
    this.confirmedAt,
    this.deliveredAt,
    this.subtotal,
    this.discountType,
    this.discountValue,
    this.discountAmount,
    this.grandTotal,
    this.status,
    this.note,
    this.customer,
    this.salesman,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;

  @JsonKey(name: 'order_no')
  final String? orderNo;

  @JsonKey(name: 'order_date')
  final String? orderDate;

  @JsonKey(name: 'intended_delivery_at')
  final String? intendedDeliveryAt;

  @JsonKey(name: 'confirmed_at')
  final String? confirmedAt;

  @JsonKey(name: 'delivered_at')
  final String? deliveredAt;

  final num? subtotal;

  @JsonKey(name: 'discount_type')
  final String? discountType;

  @JsonKey(name: 'discount_value')
  final num? discountValue;

  @JsonKey(name: 'discount_amount')
  final num? discountAmount;

  @JsonKey(name: 'grand_total')
  final num? grandTotal;

  final String? status;
  final String? note;
  final OrderCustomerModel? customer;
  final OrderSalesmanModel? salesman;
  final List<OrderItemModel>? items;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
