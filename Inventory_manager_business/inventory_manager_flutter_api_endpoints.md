# Inventory Manager Flutter Endpoint Guide

Use these endpoint constants for the inventory-manager mobile app.
They match the current Laravel API contract.

## ApiEndpoints additions

Add the missing subcategory endpoints:

```dart
import '../constants/api_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const login = '${ApiConfig.apiPrefix}/login';
  static const logout = '${ApiConfig.apiPrefix}/logout';
  static const me = '${ApiConfig.apiPrefix}/me';
  static const products = '${ApiConfig.apiPrefix}/products';
  static const purchases = '${ApiConfig.apiPrefix}/purchases';
  static const customers = '${ApiConfig.apiPrefix}/customers';
  static const orders = '${ApiConfig.apiPrefix}/orders';
  static const categories = '${ApiConfig.apiPrefix}/categories';
  static const subcategories = '${ApiConfig.apiPrefix}/subcategories';
  static const units = '${ApiConfig.apiPrefix}/units';
  static const inventoryManagerBarcodeBase =
      '${ApiConfig.apiPrefix}/inventory-manager/barcode';

  static String productDetails(int id) => '$products/$id';
  static String purchaseDetails(int id) => '$purchases/$id';
  static String customerDetails(int id) => '$customers/$id';
  static String orderDetails(int id) => '$orders/$id';
  static String subcategoriesByCategory(int categoryId) =>
      '$subcategories?category_id=$categoryId';
  static String resolveBarcodeProduct(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode/resolve';
  static String barcodeProductDetails(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode';
  static String barcodeProducts() => '$inventoryManagerBarcodeBase/products';
  static String updateBarcodeProduct(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode';
  static String purchaseProductByBarcode(String barcode) =>
      '$inventoryManagerBarcodeBase/purchase-products/$barcode';
}
```

## Expected service usage

### Auth

- login: `POST /api/login`
- me: `GET /api/me`
- logout: `POST /api/logout`

### Master data

- categories: `GET /api/categories`
- subcategories: `GET /api/subcategories`
- subcategories by category: `GET /api/subcategories?category_id={id}`
- units: `GET /api/units`

### Products

- list products: `GET /api/products`
- product details: `GET /api/products/{id}`
- manual create: `POST /api/products`
- manual update: `PUT /api/products/{id}`
- list search `q` now supports partial product name, SKU, and barcode matching
- exact barcode scanner flows should still use the dedicated barcode endpoints

### Purchases

- list purchases: `GET /api/purchases`
- purchase details: `GET /api/purchases/{id}`
- create purchase: `POST /api/purchases`
- update purchase: `PUT /api/purchases/{id}`

### Barcode inventory-manager flow

- resolve scanned barcode: `GET /api/inventory-manager/barcode/products/{barcode}/resolve`
- get existing product by barcode: `GET /api/inventory-manager/barcode/products/{barcode}`
- create product from barcode flow: `POST /api/inventory-manager/barcode/products`
- update product from barcode flow: `PUT /api/inventory-manager/barcode/products/{barcode}`
- purchase lookup by barcode: `GET /api/inventory-manager/barcode/purchase-products/{barcode}`

## Flutter behavior notes

- use `X-Authorization: Bearer {token}` as the default protected header for production
- do not calculate product stock or stock status in Flutter
- when category changes, clear existing `subcategory_id` and reload subcategories
- for variant purchase lines, send `product_variant_id`
- for simple purchase lines, omit `product_variant_id` or send null
