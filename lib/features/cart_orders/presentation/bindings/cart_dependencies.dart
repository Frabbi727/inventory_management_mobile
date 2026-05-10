import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/offline/offline_dependencies.dart';
import '../../../../core/offline/repositories/pending_actions_repository.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../../products/presentation/bindings/product_dependencies.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/data/repositories/customer_cache_repository.dart';
import '../../../products/data/repositories/product_cache_repository.dart';
import '../../data/repositories/order_cache_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../controllers/cart_controller.dart';

class CartDependencies {
  CartDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();
    ProductDependencies.ensureRegistered();
    OfflineDependencies.ensureRegistered();

    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut(ApiClient.new, fenix: true);
    }

    if (!Get.isRegistered<TokenStorage>()) {
      Get.lazyPut(TokenStorage.new, fenix: true);
    }

    if (!Get.isRegistered<OrderRepository>()) {
      Get.lazyPut(
        () => OrderRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
          pendingActionsRepository: Get.find<PendingActionsRepository>(),
          customerCacheRepository: Get.find<CustomerCacheRepository>(),
          orderCacheRepository: Get.find<OrderCacheRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CartController>()) {
      Get.put(
        CartController(
          orderRepository: Get.find<OrderRepository>(),
          productRepository: Get.find<ProductRepository>(),
        ),
        permanent: true,
      );
    }
  }
}

