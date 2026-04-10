enum ProductFormMode { create, edit }

class ProductFormArgs {
  const ProductFormArgs({
    required this.mode,
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  });

  const ProductFormArgs.create({
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  }) : mode = ProductFormMode.create;

  const ProductFormArgs.edit({
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  }) : mode = ProductFormMode.edit;

  final ProductFormMode mode;
  final String? name;
  final String? sku;
  final String? barcode;
  final int? categoryId;
  final int? unitId;
  final num? purchasePrice;
  final num? sellingPrice;
  final int? minimumStockAlert;
  final String? status;
}
