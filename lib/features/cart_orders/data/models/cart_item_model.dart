import '../../../products/data/models/product_model.dart';

class CartItemModel {
  const CartItemModel({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  int? get productId => product.id;

  num get unitPrice => product.sellingPrice ?? 0;

  num get lineTotal => unitPrice * quantity;

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
