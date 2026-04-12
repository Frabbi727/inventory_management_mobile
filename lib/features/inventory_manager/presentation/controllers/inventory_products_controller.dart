import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
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
  Future<void> onTabActivated() => ensureLoaded(forceRefresh: true);

  @override
  String buildEmptyMessage(
    String query,
    int? categoryId,
    int? subcategoryId,
    ProductStockStatus? stockStatus,
  ) {
    final categoryName = categoryId != null
        ? categories.firstWhereOrNull((c) => c.id == categoryId)?.name
        : null;
    final subcategoryName = subcategoryId != null
        ? subcategories.firstWhereOrNull((s) => s.id == subcategoryId)?.name
        : null;
    final stockLabel = stockStatus?.displayLabel;

    if (query.isNotEmpty &&
        categoryName != null &&
        subcategoryName != null &&
        stockLabel != null) {
      return 'No $stockLabel products found for "$query" in $categoryName / $subcategoryName.';
    }
    if (query.isNotEmpty && categoryName != null && subcategoryName != null) {
      return 'No products found for "$query" in $categoryName / $subcategoryName.';
    }
    if (query.isNotEmpty && categoryName != null && stockLabel != null) {
      return 'No $stockLabel products found for "$query" in $categoryName.';
    }
    if (query.isNotEmpty && categoryName != null) {
      return 'No products found for "$query" in $categoryName.';
    }
    if (query.isNotEmpty && stockLabel != null) {
      return 'No $stockLabel products found for "$query".';
    }
    if (query.isNotEmpty) {
      return 'No products found for "$query".';
    }
    if (subcategoryName != null && stockLabel != null) {
      return 'No $stockLabel products found in $subcategoryName.';
    }
    if (subcategoryName != null) {
      return 'No products found in $subcategoryName.';
    }
    if (categoryName != null && stockLabel != null) {
      return 'No $stockLabel products found in $categoryName.';
    }
    if (categoryName != null) {
      return 'No products found in $categoryName.';
    }
    if (stockLabel != null) {
      return 'No $stockLabel products found.';
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
