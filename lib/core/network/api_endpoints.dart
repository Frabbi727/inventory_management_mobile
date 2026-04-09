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

  static String productDetails(int id) => '$products/$id';
  static String customerDetails(int id) => '$customers/$id';
  static String orderDetails(int id) => '$orders/$id';
}
