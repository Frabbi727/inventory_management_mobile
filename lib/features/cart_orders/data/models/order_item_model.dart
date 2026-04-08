import 'package:json_annotation/json_annotation.dart';

part 'order_item_model.g.dart';

int? _nullableIntFromAny(dynamic value) {
  if (value == null) {
    return null;
  }

  return int.tryParse(value.toString());
}

@JsonSerializable()
class OrderItemModel {
  const OrderItemModel({
    this.id,
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
  });

  final int? id;

  @JsonKey(name: 'product_id', fromJson: _nullableIntFromAny)
  final int? productId;

  @JsonKey(name: 'product_name')
  final String? productName;

  final int? quantity;

  @JsonKey(name: 'unit_price')
  final num? unitPrice;

  @JsonKey(name: 'line_total')
  final num? lineTotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}
