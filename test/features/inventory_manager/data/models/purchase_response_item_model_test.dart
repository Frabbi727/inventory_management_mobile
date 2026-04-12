import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/models/purchase_response_item_model.dart';

void main() {
  test('parses variant-aware purchase response items defensively', () {
    final item = PurchaseResponseItemModel.fromJson({
      'id': 3,
      'product_id': 1,
      'product_variant_id': 1,
      'product_name': 'Samsung S28',
      'variant_label': '128',
      'product_barcode': 'BC-20260412-274247',
      'quantity': 100,
      'unit_cost': 100,
      'line_total': 10000,
      'product': {
        'id': 1,
        'name': 'Samsung S28',
        'sku': 'SKU-MP-SS',
        'barcode': 'BC-20260412-274247',
        'category': {'id': 1, 'name': 'Mobile Phone'},
        'unit': {'id': 1, 'name': 'Piece', 'short_name': 'pc'},
        'variant': {
          'id': 1,
          'label': '128',
          'option_values': {'Storage': '128'},
        },
      },
    });

    expect(item.productVariantId, 1);
    expect(item.variantLabel, '128');
    expect(item.product?.variant?.label, '128');
    expect(item.product?.variant?.optionValues?['Storage'], '128');
    expect(item.product?.category?.name, 'Mobile Phone');
  });
}
