import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import 'inventory_product_catalog_controller.dart';

class LowStockController extends InventoryProductCatalogController {
  LowStockController({required super.productRepository}) : super();

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  List<ProductModel> get lowStockProducts =>
      products.where(_isLowStock).toList(growable: false);

  @override
  String buildEmptyMessage(String query, int? categoryId) {
    return 'No products are below the minimum stock alert.';
  }

  void openDetails(ProductModel product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }

  bool _isLowStock(ProductModel product) {
    final currentStock = product.currentStock ?? 0;
    final minimumStockAlert = product.minimumStockAlert ?? 0;
    return currentStock <= minimumStockAlert;
  }
}
