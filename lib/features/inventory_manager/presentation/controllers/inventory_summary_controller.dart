import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import 'inventory_product_catalog_controller.dart';

class InventorySummaryController extends InventoryProductCatalogController {
  InventorySummaryController({required super.productRepository}) : super();

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  List<ProductModel> get lowStockProducts =>
      products.where(isLowStock).toList(growable: false);

  List<ProductModel> get outOfStockProducts => products
      .where((product) => (product.currentStock ?? 0) <= 0)
      .toList(growable: false);

  int get categoryCount =>
      products.map((e) => e.category?.id).whereType<int>().toSet().length;

  bool isLowStock(ProductModel product) {
    final currentStock = product.currentStock ?? 0;
    final minimumStockAlert = product.minimumStockAlert ?? 0;
    return currentStock <= minimumStockAlert;
  }

  @override
  String buildEmptyMessage(String query, int? categoryId) {
    return 'No inventory summary is available right now.';
  }

  void openLowStock() {
    Get.toNamed(AppRoutes.inventoryLowStock);
  }

  void openDetails(ProductModel product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }
}
