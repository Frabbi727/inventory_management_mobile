import '../../../products/data/models/product_model.dart';

class InventoryPurchaseItemModel {
  const InventoryPurchaseItemModel({
    this.id,
    this.productId,
    this.quantity,
    this.unitCost,
    this.lineTotal,
    this.product,
  });

  final int? id;
  final int? productId;
  final num? quantity;
  final num? unitCost;
  final num? lineTotal;
  final ProductModel? product;

  factory InventoryPurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryPurchaseItemModel(
      id: json['id'] as int?,
      productId: json['product_id'] as int?,
      quantity: json['quantity'] as num?,
      unitCost: json['unit_cost'] as num?,
      lineTotal: json['line_total'] as num?,
      product: json['product'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}
