import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_sales/features/inventory_manager/data/models/create_or_update_barcode_product_request.dart';

void main() {
  test('serializes optional subcategory and variant fields', () {
    const request = CreateOrUpdateBarcodeProductRequest(
      name: 'Samsung S28',
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
          quantity: 5,
          buyingPrice: 120000.89,
          sellingPrice: 150000.88,
          status: 'active',
        ),
        ProductVariantRowPayload(
          attributes: {'Storage': '256'},
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
    expect(json.containsKey('sku'), isFalse);
    expect((json['variants'] as List).first['quantity'], 5);
    expect((json['variants'] as List).first['buying_price'], 120000.89);
    expect((json['variants'] as List).last['selling_price'], 170000);
    expect((json['variants'] as List).last['status'], 'inactive');
    expect(multipart['variants[0][attributes][Storage]'], '128');
    expect(multipart['variants[1][attributes][Storage]'], '256');
    expect(multipart.containsKey('variants[0][sku]'), isFalse);
    expect(multipart.containsKey('variants[1][barcode]'), isFalse);
    expect(multipart['variants[0][quantity]'], '5');
    expect(multipart['purchase_price'], '');
    expect(multipart['selling_price'], '');
    expect(multipart['variants[0][buying_price]'], '120000.89');
    expect(multipart['variants[1][selling_price]'], '170000');
    expect(multipart['variants[1][status]'], 'inactive');
  });

  test('omits parent barcode when it is missing', () {
    const request = CreateOrUpdateBarcodeProductRequest(
      name: 'Manual Product',
      categoryId: 1,
      unitId: 3,
      purchasePrice: 10,
      sellingPrice: 12,
      minimumStockAlert: 2,
      status: 'active',
    );

    final json = request.toJson();
    final multipart = request.toMultipartFields();

    expect(json.containsKey('barcode'), isFalse);
    expect(multipart.containsKey('barcode'), isFalse);
  });
}
