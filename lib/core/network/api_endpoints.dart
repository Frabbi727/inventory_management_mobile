import '../constants/api_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const login = '${ApiConfig.apiPrefix}/login';
  static const logout = '${ApiConfig.apiPrefix}/logout';
  static const me = '${ApiConfig.apiPrefix}/me';
  static const products = '${ApiConfig.apiPrefix}/products';
  static const customers = '${ApiConfig.apiPrefix}/customers';
  static const orders = '${ApiConfig.apiPrefix}/orders';
  static const categories = '${ApiConfig.apiPrefix}/categories';
  static const units = '${ApiConfig.apiPrefix}/units';
  static const inventoryManagerBarcodeBase =
      '${ApiConfig.apiPrefix}/inventory-manager/barcode';

  static String productDetails(int id) => '$products/$id';
  static String customerDetails(int id) => '$customers/$id';
  static String orderDetails(int id) => '$orders/$id';
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
