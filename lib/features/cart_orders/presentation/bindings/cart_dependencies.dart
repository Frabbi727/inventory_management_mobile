import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/bindings/auth_dependencies.dart';
import '../../data/repositories/order_repository.dart';
import '../controllers/cart_controller.dart';

class CartDependencies {
  CartDependencies._();

  static void ensureRegistered() {
    AuthDependencies.ensureRegistered();

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
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CartController>()) {
      Get.put(
        CartController(orderRepository: Get.find<OrderRepository>()),
        permanent: true,
      );
    }
  }
}
