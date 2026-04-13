import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.product,
    required this.quantity,
    this.variant,
  });

  final ProductModel product;
  final int quantity;
  final ProductVariantModel? variant;

  int? get productId => product.id;
  int? get productVariantId => variant?.id;
  String get lineKey =>
      '${productId ?? 'unknown'}:${productVariantId ?? 'base'}';
  String? get variantLabel =>
      variant?.combinationLabel ?? variant?.combinationKey;
  int? get availableStock => variant?.currentStock ?? product.currentStock;

  num get unitPrice => variant?.sellingPrice ?? product.sellingPrice ?? 0;

  num get lineTotal => unitPrice * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    ProductVariantModel? variant,
    bool clearVariant = false,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: clearVariant ? null : variant ?? this.variant,
    );
  }
}
