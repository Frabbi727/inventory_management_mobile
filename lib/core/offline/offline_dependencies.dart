import 'package:get/get.dart';
import '../../features/cart_orders/data/repositories/order_cache_repository.dart';
import 'repositories/pending_actions_repository.dart';

class OfflineDependencies {
  OfflineDependencies._();

  static void ensureRegistered() {
    if (!Get.isRegistered<PendingActionsRepository>()) {
      Get.lazyPut(
        PendingActionsRepository.new,
        fenix: true,
      );
    }

    if (!Get.isRegistered<OrderCacheRepository>()) {
      Get.lazyPut(
        OrderCacheRepository.new,
        fenix: true,
      );
    }
  }
}
