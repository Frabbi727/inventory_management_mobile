import 'package:get/get.dart';
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
  }
}
