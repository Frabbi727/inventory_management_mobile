import '../../../products/data/models/product_model.dart';

class PurchaseDraftItem {
  const PurchaseDraftItem({
    required this.lineKey,
    required this.productId,
    this.productVariantId,
    this.variantLabel,
    this.optionValues,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.quantity,
    required this.unitCost,
    required this.currentStock,
    required this.categoryName,
    this.product,
  });

  final String lineKey;
  final int productId;
  final int? productVariantId;
  final String? variantLabel;
  final Map<String, String>? optionValues;
  final String name;
  final String sku;
  final String barcode;
  final int quantity;
  final double unitCost;
  final int currentStock;
  final String categoryName;
  final ProductModel? product;

  double get totalAmount => quantity * unitCost;
  bool get hasVariant => productVariantId != null;

  PurchaseDraftItem copyWith({
    String? lineKey,
    int? productId,
    int? productVariantId,
    bool clearProductVariantId = false,
    String? variantLabel,
    bool clearVariantLabel = false,
    Map<String, String>? optionValues,
    bool clearOptionValues = false,
    String? name,
    String? sku,
    String? barcode,
    int? quantity,
    double? unitCost,
    int? currentStock,
    String? categoryName,
    ProductModel? product,
    bool clearProduct = false,
  }) {
    return PurchaseDraftItem(
      lineKey: lineKey ?? this.lineKey,
      productId: productId ?? this.productId,
      productVariantId: clearProductVariantId
          ? null
          : productVariantId ?? this.productVariantId,
      variantLabel: clearVariantLabel
          ? null
          : variantLabel ?? this.variantLabel,
      optionValues: clearOptionValues
          ? null
          : optionValues ?? this.optionValues,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      currentStock: currentStock ?? this.currentStock,
      categoryName: categoryName ?? this.categoryName,
      product: clearProduct ? null : product ?? this.product,
    );
  }
}
