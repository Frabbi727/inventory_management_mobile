import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.product,
    required this.quantity,
    this.variant,
    this.allocationItemId,
    this.allocationRemainingQty,
  });

  final ProductModel product;
  final int quantity;
  final ProductVariantModel? variant;
  final int? allocationItemId;
  final double? allocationRemainingQty;

  bool get isAllocationItem => allocationItemId != null;

  int? get productId => product.id;
  int? get productVariantId => variant?.id;
  String get lineKey =>
      '${productId ?? 'unknown'}:${productVariantId ?? 'base'}';
  String? get variantLabel =>
      variant?.combinationLabel ?? variant?.combinationKey;
  int? get availableStock {
    if (allocationRemainingQty != null) return allocationRemainingQty!.toInt();
    return variant?.currentStock ?? product.currentStock;
  }

  bool get hasStockLimit => availableStock != null;
  bool get isOutOfStock => hasStockLimit && (availableStock ?? 0) <= 0;
  bool get exceedsAvailableStock =>
      hasStockLimit && quantity > (availableStock ?? 0);
  bool get hasLowStockWarning =>
      hasStockLimit &&
      !isOutOfStock &&
      quantity > (availableStock ?? 0);

  num get unitPrice => variant?.sellingPrice ?? product.sellingPrice ?? 0;

  num get lineTotal => unitPrice * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    ProductVariantModel? variant,
    bool clearVariant = false,
    int? allocationItemId,
    double? allocationRemainingQty,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: clearVariant ? null : variant ?? this.variant,
      allocationItemId: allocationItemId ?? this.allocationItemId,
      allocationRemainingQty:
          allocationRemainingQty ?? this.allocationRemainingQty,
    );
  }
}
