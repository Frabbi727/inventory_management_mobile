import 'package:get/get.dart';

import '../../data/repositories/product_cache_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../controllers/product_list_controller.dart';
import 'product_dependencies.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    ProductDependencies.ensureRegistered();

    if (!Get.isRegistered<ProductListController>()) {
      Get.lazyPut(
        () => ProductListController(
          productRepository: Get.find<ProductRepository>(),
          productCacheRepository: Get.find<ProductCacheRepository>(),
        ),
      );
    }
  }
}
