import '../../../products/data/models/product_category_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import 'purchase_product_variant_ref_model.dart';

class PurchaseProductRefModel {
  const PurchaseProductRefModel({
    this.id,
    this.name,
    this.sku,
    this.barcode,
    this.currentStock,
    this.category,
    this.unit,
    this.variant,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? barcode;
  final int? currentStock;
  final ProductCategoryModel? category;
  final ProductUnitModel? unit;
  final PurchaseProductVariantRefModel? variant;

  factory PurchaseProductRefModel.fromJson(Map<String, dynamic> json) {
    return PurchaseProductRefModel(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      currentStock: _asInt(json['current_stock']),
      category: json['category'] is Map<String, dynamic>
          ? ProductCategoryModel.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
      unit: json['unit'] is Map<String, dynamic>
          ? ProductUnitModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      variant: json['variant'] is Map<String, dynamic>
          ? PurchaseProductVariantRefModel.fromJson(
              json['variant'] as Map<String, dynamic>,
            )
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
}
