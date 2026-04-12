import '../../../products/data/models/product_variant_attribute_model.dart';
import '../../../products/data/models/product_variant_model.dart';

enum ProductFormMode { create, edit }

class ProductFormArgs {
  const ProductFormArgs({
    required this.mode,
    this.productId,
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.subcategoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
    this.hasVariants,
    this.variantAttributes,
    this.variants,
  });

  const ProductFormArgs.create({
    this.productId,
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.subcategoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
    this.hasVariants,
    this.variantAttributes,
    this.variants,
  }) : mode = ProductFormMode.create;

  const ProductFormArgs.edit({
    this.productId,
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.subcategoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
    this.hasVariants,
    this.variantAttributes,
    this.variants,
  }) : mode = ProductFormMode.edit;

  final ProductFormMode mode;
  final int? productId;
  final String? name;
  final String? sku;
  final String? barcode;
  final int? categoryId;
  final int? subcategoryId;
  final int? unitId;
  final num? purchasePrice;
  final num? sellingPrice;
  final int? minimumStockAlert;
  final String? status;
  final bool? hasVariants;
  final List<ProductVariantAttributeModel>? variantAttributes;
  final List<ProductVariantModel>? variants;
}
