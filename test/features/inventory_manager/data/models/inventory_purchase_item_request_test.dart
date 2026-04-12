import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/models/inventory_purchase_item_request.dart';

void main() {
  test('omits product_variant_id for simple product purchase item', () {
    const request = InventoryPurchaseItemRequest(
      productId: 8,
      quantity: 10,
      unitCost: 90,
    );

    final json = request.toJson();

    expect(json['product_id'], 8);
    expect(json.containsKey('product_variant_id'), isFalse);
    expect(json['quantity'], 10);
    expect(json['unit_cost'], 90);
  });

  test('includes product_variant_id for variant product purchase item', () {
    const request = InventoryPurchaseItemRequest(
      productId: 10,
      productVariantId: 11,
      quantity: 5,
      unitCost: 220,
    );

    final json = request.toJson();

    expect(json['product_id'], 10);
    expect(json['product_variant_id'], 11);
    expect(json['quantity'], 5);
    expect(json['unit_cost'], 220);
  });
}
