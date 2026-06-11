import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

class AllocationItemModel {
  const AllocationItemModel({
    required this.id,
    required this.productId,
    this.productVariantId,
    required this.productNameSnapshot,
    required this.unitPriceSnapshot,
    required this.quantityAllocated,
    required this.quantitySold,
    required this.quantityReturned,
    this.product,
    this.productVariant,
  });

  final int id;
  final int productId;
  final int? productVariantId;
  final String productNameSnapshot;
  final double unitPriceSnapshot;
  final double quantityAllocated;
  final double quantitySold;
  final double quantityReturned;
  final ProductModel? product;
  final ProductVariantModel? productVariant;

  double get remainingQuantity =>
      (quantityAllocated - quantitySold - quantityReturned).clamp(
        0,
        double.infinity,
      );

  bool get isFullyAccounted => remainingQuantity <= 0;

  ProductModel toProductModel() {
    final base = product;
    if (base != null) {
      return ProductModel(
        id: base.id,
        name: base.name,
        sku: base.sku,
        barcode: base.barcode,
        purchasePrice: base.purchasePrice,
        sellingPrice: base.sellingPrice,
        minimumStockAlert: base.minimumStockAlert,
        stockStatus: base.stockStatus,
        status: base.status,
        currentStock: remainingQuantity.toInt(),
        primaryPhoto: base.primaryPhoto,
        photos: base.photos,
        photoCount: base.photoCount,
        category: base.category,
        subcategory: base.subcategory,
        unit: base.unit,
        hasVariants: base.hasVariants,
        variantSummary: base.variantSummary,
        variantAttributes: base.variantAttributes,
        variants: base.variants,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );
    }
    return ProductModel(
      id: productId,
      name: productNameSnapshot,
      sellingPrice: unitPriceSnapshot,
      currentStock: remainingQuantity.toInt(),
    );
  }

  factory AllocationItemModel.fromJson(Map<String, dynamic> json) {
    return AllocationItemModel(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num?)?.toInt(),
      productNameSnapshot: json['product_name_snapshot'] as String? ?? '',
      unitPriceSnapshot:
          double.tryParse(json['unit_price_snapshot']?.toString() ?? '0') ?? 0,
      quantityAllocated:
          double.tryParse(json['quantity_allocated']?.toString() ?? '0') ?? 0,
      quantitySold:
          double.tryParse(json['quantity_sold']?.toString() ?? '0') ?? 0,
      quantityReturned:
          double.tryParse(json['quantity_returned']?.toString() ?? '0') ?? 0,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      productVariant: json['product_variant'] != null
          ? ProductVariantModel.fromJson(
              json['product_variant'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AllocationModel {
  const AllocationModel({
    required this.id,
    required this.allocationNo,
    required this.status,
    this.note,
    this.dispatchedAt,
    this.closedAt,
    this.items,
  });

  final int id;
  final String allocationNo;
  final String status;
  final String? note;
  final String? dispatchedAt;
  final String? closedAt;
  final List<AllocationItemModel>? items;

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  factory AllocationModel.fromJson(Map<String, dynamic> json) {
    return AllocationModel(
      id: (json['id'] as num).toInt(),
      allocationNo: json['allocation_no'] as String? ?? '',
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
      dispatchedAt: json['dispatched_at'] as String?,
      closedAt: json['closed_at'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => AllocationItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
