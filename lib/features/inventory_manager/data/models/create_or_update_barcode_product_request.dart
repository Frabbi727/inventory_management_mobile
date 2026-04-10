import 'package:json_annotation/json_annotation.dart';

part 'create_or_update_barcode_product_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateOrUpdateBarcodeProductRequest {
  const CreateOrUpdateBarcodeProductRequest({
    required this.name,
    this.sku,
    required this.barcode,
    required this.categoryId,
    required this.unitId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.status,
  });

  final String name;

  @JsonKey(includeIfNull: false)
  final String? sku;

  final String barcode;

  @JsonKey(name: 'category_id')
  final int categoryId;

  @JsonKey(name: 'unit_id')
  final int unitId;

  @JsonKey(name: 'purchase_price')
  final num purchasePrice;

  @JsonKey(name: 'selling_price')
  final num sellingPrice;

  @JsonKey(name: 'minimum_stock_alert')
  final int minimumStockAlert;

  final String status;

  factory CreateOrUpdateBarcodeProductRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$CreateOrUpdateBarcodeProductRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrUpdateBarcodeProductRequestToJson(
    this,
  );

  Map<String, String> toMultipartFields() {
    return toJson().map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }
}
