class InventoryPurchaseItemRequest {
  const InventoryPurchaseItemRequest({
    required this.productId,
    required this.quantity,
    required this.unitCost,
  });

  final int productId;
  final int quantity;
  final num unitCost;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
    };
  }
}
