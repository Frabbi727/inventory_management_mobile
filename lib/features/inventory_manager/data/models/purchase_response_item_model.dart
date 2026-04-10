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
      id: _asInt(json['id']),
      productId: _asInt(json['product_id']),
      productName: json['product_name'] as String?,
      productBarcode: json['product_barcode'] as String?,
      quantity: _asNum(json['quantity']),
      unitCost: _asNum(json['unit_cost']),
      lineTotal: _asNum(json['line_total']),
      product: json['product'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static num? _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }
}
