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
      variants: [
        ProductVariantRowPayload(
          attributes: {'Storage': '128'},
          sku: 'SKU-128',
          barcode: 'BC-001-128',
          quantity: 5,
          buyingPrice: 120000.89,
          sellingPrice: 150000.88,
          status: 'active',
        ),
        ProductVariantRowPayload(
          attributes: {'Storage': '256'},
          sku: 'SKU-256',
          barcode: 'BC-001-256',
          quantity: 2,
          buyingPrice: 135000,
          sellingPrice: 170000,
          status: 'inactive',
        ),
      ],
    );

    final json = request.toJson();
    final multipart = request.toMultipartFields();

    expect(json['subcategory_id'], 2);
    expect(json['has_variants'], true);
    expect(json['purchase_price'], isNull);
    expect(json['selling_price'], isNull);
    expect((json['variants'] as List).length, 2);
    expect((json['variants'] as List).first['sku'], 'SKU-128');
    expect((json['variants'] as List).first['barcode'], 'BC-001-128');
    expect((json['variants'] as List).first['quantity'], 5);
    expect((json['variants'] as List).first['buying_price'], 120000.89);
    expect((json['variants'] as List).last['selling_price'], 170000);
    expect((json['variants'] as List).last['status'], 'inactive');
    expect(multipart['variants[0][attributes][Storage]'], '128');
    expect(multipart['variants[1][attributes][Storage]'], '256');
    expect(multipart['variants[0][sku]'], 'SKU-128');
    expect(multipart['variants[1][barcode]'], 'BC-001-256');
    expect(multipart['variants[0][quantity]'], '5');
    expect(multipart['purchase_price'], '');
    expect(multipart['selling_price'], '');
    expect(multipart['variants[0][buying_price]'], '120000.89');
    expect(multipart['variants[1][selling_price]'], '170000');
    expect(multipart['variants[1][status]'], 'inactive');
  });
}
