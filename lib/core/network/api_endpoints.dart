import '../constants/api_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const login = '${ApiConfig.apiPrefix}/login';
  static const logout = '${ApiConfig.apiPrefix}/logout';
  static const me = '${ApiConfig.apiPrefix}/me';
  static const deviceRegister = '${ApiConfig.apiPrefix}/devices/register';
  static const deviceUnregister = '${ApiConfig.apiPrefix}/devices/unregister';
  static const notifications = '${ApiConfig.apiPrefix}/notifications';
  static const notificationsUnreadCount =
      '${ApiConfig.apiPrefix}/notifications/unread-count';
  static const notificationsReadAll =
      '${ApiConfig.apiPrefix}/notifications/read-all';
  static const products = '${ApiConfig.apiPrefix}/products';
  static const purchases = '${ApiConfig.apiPrefix}/purchases';
  static const customers = '${ApiConfig.apiPrefix}/customers';
  static const orders = '${ApiConfig.apiPrefix}/orders';
  static const dashboardSalesman = '${ApiConfig.apiPrefix}/dashboard/salesman';
  static const dashboardInventoryManager =
      '${ApiConfig.apiPrefix}/dashboard/inventory-manager';
  static const inventoryProducts =
      '${ApiConfig.apiPrefix}/inventory/products';
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
  static String notificationRead(int id) => '$notifications/$id/read';
  static String notificationUnread(int id) => '$notifications/$id/unread';
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
