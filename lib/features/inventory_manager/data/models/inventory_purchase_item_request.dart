class InventoryPurchaseItemRequest {
  const InventoryPurchaseItemRequest({
    required this.productId,
    this.productVariantId,
    required this.quantity,
    required this.unitCost,
  });

  final int productId;
  final int? productVariantId;
  final int quantity;
  final num unitCost;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      if (productVariantId != null) 'product_variant_id': productVariantId,
      'quantity': quantity,
      'unit_cost': unitCost,
    };
  }
}
