class PurchaseDraftItem {
  const PurchaseDraftItem({
    required this.lineKey,
    required this.productId,
    this.productVariantId,
    this.variantLabel,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.quantity,
    required this.unitCost,
    required this.currentStock,
    required this.categoryName,
  });

  final String lineKey;
  final int productId;
  final int? productVariantId;
  final String? variantLabel;
  final String name;
  final String sku;
  final String barcode;
  final int quantity;
  final double unitCost;
  final int currentStock;
  final String categoryName;

  double get totalAmount => quantity * unitCost;

  PurchaseDraftItem copyWith({
    String? lineKey,
    int? productId,
    int? productVariantId,
    bool clearProductVariantId = false,
    String? variantLabel,
    bool clearVariantLabel = false,
    String? name,
    String? sku,
    String? barcode,
    int? quantity,
    double? unitCost,
    int? currentStock,
    String? categoryName,
  }) {
    return PurchaseDraftItem(
      lineKey: lineKey ?? this.lineKey,
      productId: productId ?? this.productId,
      productVariantId: clearProductVariantId
          ? null
          : productVariantId ?? this.productVariantId,
      variantLabel: clearVariantLabel ? null : variantLabel ?? this.variantLabel,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      currentStock: currentStock ?? this.currentStock,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
