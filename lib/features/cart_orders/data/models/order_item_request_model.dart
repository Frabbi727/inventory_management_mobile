import 'package:json_annotation/json_annotation.dart';

part 'order_item_request_model.g.dart';

@JsonSerializable()
class OrderItemRequestModel {
  const OrderItemRequestModel({this.productId, this.quantity});

  @JsonKey(name: 'product_id')
  final int? productId;

  final int? quantity;

  factory OrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemRequestModelToJson(this);
}
