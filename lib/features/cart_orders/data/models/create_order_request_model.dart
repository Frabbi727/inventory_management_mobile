import 'package:json_annotation/json_annotation.dart';

import 'order_item_request_model.dart';

part 'create_order_request_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateOrderRequestModel {
  const CreateOrderRequestModel({
    this.customerId,
    this.customerMobileRef,
    this.allocationId,
    this.orderDate,
    this.intendedDeliveryAt,
    this.note,
    this.discountType,
    this.discountValue,
    this.paymentAmount,
    this.items,
    this.mobileRef,
    this.confirmOnCreate,
  });

  @JsonKey(name: 'customer_id')
  final int? customerId;

  /// Set when customer was created offline (temp negative ID).
  /// Backend resolves the real customer by this mobile_ref.
  @JsonKey(name: 'customer_mobile_ref')
  final String? customerMobileRef;

  @JsonKey(name: 'allocation_id')
  final int? allocationId;

  @JsonKey(name: 'order_date')
  final String? orderDate;

  @JsonKey(name: 'intended_delivery_at')
  final String? intendedDeliveryAt;

  final String? note;

  @JsonKey(name: 'discount_type')
  final String? discountType;

  @JsonKey(name: 'discount_value')
  final num? discountValue;

  @JsonKey(name: 'payment_amount')
  final num? paymentAmount;

  final List<OrderItemRequestModel>? items;

  @JsonKey(name: 'mobile_ref')
  final String? mobileRef;

  /// When true, backend creates draft AND confirms it atomically.
  /// Used when salesman confirms an order while offline.
  @JsonKey(name: 'confirm_on_create')
  final bool? confirmOnCreate;

  factory CreateOrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderRequestModelToJson(this);
}
