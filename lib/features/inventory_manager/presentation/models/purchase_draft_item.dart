class PurchaseDraftItem {
  const PurchaseDraftItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.quantity,
    required this.unitCost,
    required this.currentStock,
    required this.categoryName,
  });

  final int productId;
  final String name;
  final String barcode;
  final int quantity;
  final double unitCost;
  final int currentStock;
  final String categoryName;

  double get totalAmount => quantity * unitCost;

  PurchaseDraftItem copyWith({
    int? productId,
    String? name,
    String? barcode,
    int? quantity,
    double? unitCost,
    int? currentStock,
    String? categoryName,
  }) {
    return PurchaseDraftItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      currentStock: currentStock ?? this.currentStock,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
