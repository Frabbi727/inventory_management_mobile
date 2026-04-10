class CreateOrUpdateBarcodeProductRequest {
  const CreateOrUpdateBarcodeProductRequest({
    required this.name,
    required this.sku,
    required this.barcode,
    required this.categoryId,
    required this.unitId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.status,
  });

  final String name;
  final String sku;
  final String barcode;
  final int categoryId;
  final int unitId;
  final num purchasePrice;
  final num sellingPrice;
  final int minimumStockAlert;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'unit_id': unitId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'minimum_stock_alert': minimumStockAlert,
      'status': status,
    };
  }

  Map<String, String> toMultipartFields() {
    return <String, String>{
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': '$categoryId',
      'unit_id': '$unitId',
      'purchase_price': '$purchasePrice',
      'selling_price': '$sellingPrice',
      'minimum_stock_alert': '$minimumStockAlert',
      'status': status,
    };
  }
}
