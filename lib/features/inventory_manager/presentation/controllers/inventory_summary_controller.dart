import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_stock_status.dart';
import 'inventory_product_catalog_controller.dart';

enum InventoryStatusFilter {
  all,
  inStock,
  low,
  out;

  String get label => switch (this) {
    InventoryStatusFilter.all => 'Total',
    InventoryStatusFilter.inStock => 'In Stock',
    InventoryStatusFilter.low => 'Low Stock',
    InventoryStatusFilter.out => 'Out of Stock',
  };

  IconData get icon => switch (this) {
    InventoryStatusFilter.all => Icons.inventory_2_outlined,
    InventoryStatusFilter.inStock => Icons.check_circle_rounded,
    InventoryStatusFilter.low => Icons.warning_amber_rounded,
    InventoryStatusFilter.out => Icons.cancel_rounded,
  };

  String get sectionTitle => switch (this) {
    InventoryStatusFilter.all => 'All Products',
    InventoryStatusFilter.inStock => 'In-Stock Products',
    InventoryStatusFilter.low => 'Low-Stock Products',
    InventoryStatusFilter.out => 'Out-of-Stock Products',
  };

  ProductStockStatus? get status => switch (this) {
    InventoryStatusFilter.all => null,
    InventoryStatusFilter.inStock => ProductStockStatus.inStock,
    InventoryStatusFilter.low => ProductStockStatus.lowStock,
    InventoryStatusFilter.out => ProductStockStatus.outOfStock,
  };
}

class InventorySummaryController extends InventoryProductCatalogController {
  InventorySummaryController({required super.productRepository}) : super();

  final selectedFilter = InventoryStatusFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  List<ProductModel> get allProducts => products.toList(growable: false);

  List<ProductModel> get inStockProducts => products
      .where(
        (product) => product.effectiveStockStatus == ProductStockStatus.inStock,
      )
      .toList(growable: false);

  List<ProductModel> get lowStockProducts =>
      products.where(isLowStock).toList(growable: false);

  List<ProductModel> get outOfStockProducts => products
      .where(
        (product) =>
            product.effectiveStockStatus == ProductStockStatus.outOfStock,
      )
      .toList(growable: false);

  List<ProductModel> get filteredProducts => switch (selectedFilter.value) {
    InventoryStatusFilter.all => allProducts,
    InventoryStatusFilter.inStock => inStockProducts,
    InventoryStatusFilter.low => lowStockProducts,
    InventoryStatusFilter.out => outOfStockProducts,
  };

  bool isLowStock(ProductModel product) {
    return product.effectiveStockStatus == ProductStockStatus.lowStock;
  }

  void selectFilter(InventoryStatusFilter filter) {
    selectedFilter.value = filter;
  }

  @override
  String buildEmptyMessage(
    String query,
    int? categoryId,
    int? subcategoryId,
    ProductStockStatus? stockStatus,
  ) {
    return 'No inventory summary is available right now.';
  }

  void openDetails(ProductModel product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }
}
