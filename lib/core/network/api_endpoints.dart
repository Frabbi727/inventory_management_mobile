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
  static const dashboardSalesman = '${ApiConfig.apiPrefix}/dashboard/salesman';
  static const categories = '${ApiConfig.apiPrefix}/categories';
  static const subcategories = '${ApiConfig.apiPrefix}/subcategories';
  static const units = '${ApiConfig.apiPrefix}/units';
  static const inventoryManagerBarcodeBase =
      '${ApiConfig.apiPrefix}/inventory-manager/barcode';
  static String productDetails(int id) => '$products/$id';
  static String purchaseDetails(int id) => '$purchases/$id';
  static String customerDetails(int id) => '$customers/$id';
  static String orderDetails(int id) => '$orders/$id';
  static String orderConfirm(int id) => '${orderDetails(id)}/confirm';
  static String subcategoriesByCategory(int categoryId) =>
      '$subcategories?category_id=$categoryId';
  static String resolveBarcodeProduct(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode/resolve';
  static String publicProductByBarcode(String barcode) =>
      '$products/barcode/$barcode';
  static String barcodeProductDetails(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode';
  static String barcodeProducts() => '$inventoryManagerBarcodeBase/products';
  static String updateBarcodeProduct(String barcode) =>
      '$inventoryManagerBarcodeBase/products/$barcode';
  static String purchaseProductByBarcode(String barcode) =>
      '$inventoryManagerBarcodeBase/purchase-products/$barcode';
}
