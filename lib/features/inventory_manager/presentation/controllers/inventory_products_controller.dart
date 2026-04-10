import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../models/barcode_scan_models.dart';
import 'inventory_product_catalog_controller.dart';

class InventoryProductsController extends InventoryProductCatalogController {
  InventoryProductsController({required super.productRepository}) : super();

  @override
  bool get loadCategoriesOnInit => true;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  @override
  String buildEmptyMessage(String query, int? categoryId) {
    final categoryName = categoryId != null
        ? categories.firstWhereOrNull((c) => c.id == categoryId)?.name
        : null;

    if (query.isNotEmpty && categoryName != null) {
      return 'No products found for "$query" in $categoryName.';
    }
    if (query.isNotEmpty) {
      return 'No products found for "$query".';
    }
    if (categoryName != null) {
      return 'No products found in $categoryName.';
    }
    return 'No active products found.';
  }

  void openScan() {
    Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.productLookup,
      ),
    );
  }

  void openDetails(ProductModel product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }
}
