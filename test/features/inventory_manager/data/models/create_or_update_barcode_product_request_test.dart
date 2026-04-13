import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/models/create_or_update_barcode_product_request.dart';

void main() {
  test('serializes optional subcategory and variant fields', () {
    const request = CreateOrUpdateBarcodeProductRequest(
      name: 'Samsung S28',
      sku: 'SKU-001',
      barcode: 'BC-001',
      categoryId: 1,
      subcategoryId: 2,
      unitId: 3,
      purchasePrice: null,
      sellingPrice: null,
      minimumStockAlert: 10,
      status: 'active',
      hasVariants: true,
      variantAttributes: [
        ProductVariantAttributePayload(name: 'Storage', values: ['128', '256']),
      ],
      variantQuantities: {'storage-128': 5, 'storage-256': 2},
      variantPurchasePrices: {'storage-128': 120000.89, 'storage-256': 135000},
      variantSellingPrices: {'storage-128': 150000.88, 'storage-256': 170000},
    );

    final json = request.toJson();
    final multipart = request.toMultipartFields();

    expect(json['subcategory_id'], 2);
    expect(json['has_variants'], true);
    expect(json['purchase_price'], isNull);
    expect(json['selling_price'], isNull);
    expect((json['variant_attributes'] as List).length, 1);
    expect((json['variant_quantities'] as Map)['storage-128'], 5);
    expect((json['variant_purchase_prices'] as Map)['storage-128'], 120000.89);
    expect((json['variant_selling_prices'] as Map)['storage-256'], 170000);
    expect(multipart['variant_attributes[0][name]'], 'Storage');
    expect(multipart['variant_attributes[0][values][1]'], '256');
    expect(multipart['variant_quantities[storage-128]'], '5');
    expect(multipart['purchase_price'], '');
    expect(multipart['selling_price'], '');
    expect(multipart['variant_purchase_prices[storage-128]'], '120000.89');
    expect(multipart['variant_selling_prices[storage-256]'], '170000');
  });
}
