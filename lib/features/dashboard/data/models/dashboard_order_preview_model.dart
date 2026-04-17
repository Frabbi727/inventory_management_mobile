import 'package:json_annotation/json_annotation.dart';

import '../../../cart_orders/data/models/order_status.dart';
import 'dashboard_customer_model.dart';

part 'dashboard_order_preview_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DashboardOrderPreviewModel {
  const DashboardOrderPreviewModel({
    this.id,
    this.orderNo,
    this.status,
    this.orderDate,
    this.intendedDeliveryAt,
    this.grandTotal,
    this.customer,
  });

  final int? id;

  @JsonKey(name: 'order_no')
  final String? orderNo;

  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final OrderStatus? status;

  @JsonKey(name: 'order_date')
  final String? orderDate;

  @JsonKey(name: 'intended_delivery_at')
  final String? intendedDeliveryAt;

  @JsonKey(name: 'grand_total')
  final num? grandTotal;

  final DashboardCustomerModel? customer;

  factory DashboardOrderPreviewModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardOrderPreviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardOrderPreviewModelToJson(this);

  static OrderStatus? _statusFromJson(String? value) =>
      OrderStatus.fromApi(value);

  static String? _statusToJson(OrderStatus? value) => value?.apiValue;
}
