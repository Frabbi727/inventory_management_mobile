import 'package:json_annotation/json_annotation.dart';

part 'order_item_request_model.g.dart';

@JsonSerializable()
class OrderItemRequestModel {
  const OrderItemRequestModel({
    this.productId,
    this.productVariantId,
    this.quantity,
    this.allocationItemId,
  });

  @JsonKey(name: 'product_id')
  final int? productId;

  @JsonKey(name: 'product_variant_id')
  final int? productVariantId;

  final int? quantity;

  @JsonKey(name: 'allocation_item_id', includeIfNull: false)
  final int? allocationItemId;

  factory OrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemRequestModelToJson(this);
}
