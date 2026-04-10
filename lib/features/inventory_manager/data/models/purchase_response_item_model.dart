import '../../../products/data/models/product_model.dart';

class PurchaseResponseItemModel {
  const PurchaseResponseItemModel({
    this.id,
    this.productId,
    this.productName,
    this.productBarcode,
    this.quantity,
    this.unitCost,
    this.lineTotal,
    this.product,
  });

  final int? id;
  final int? productId;
  final String? productName;
  final String? productBarcode;
  final num? quantity;
  final num? unitCost;
  final num? lineTotal;
  final ProductModel? product;

  factory PurchaseResponseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseResponseItemModel(
      id: json['id'] as int?,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String?,
      productBarcode: json['product_barcode'] as String?,
      quantity: json['quantity'] as num?,
      unitCost: json['unit_cost'] as num?,
      lineTotal: json['line_total'] as num?,
      product: json['product'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}
