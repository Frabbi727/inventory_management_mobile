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
    this.productVariantId,
    this.productName,
    this.variantLabel,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
  });

  final int? id;

  @JsonKey(name: 'product_id', fromJson: _nullableIntFromAny)
  final int? productId;

  @JsonKey(name: 'product_variant_id', fromJson: _nullableIntFromAny)
  final int? productVariantId;

  @JsonKey(name: 'product_name')
  final String? productName;

  @JsonKey(name: 'variant_label')
  final String? variantLabel;

  final int? quantity;

  @JsonKey(name: 'unit_price')
  final num? unitPrice;

  @JsonKey(name: 'line_total')
  final num? lineTotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}
