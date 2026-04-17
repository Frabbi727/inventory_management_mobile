import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_token_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/services/device_token_provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_lifecycle_service.dart';
import '../controllers/notification_controller.dart';

class NotificationDependencies {
  NotificationDependencies._();

  static void ensureRegistered() {
    if (!Get.isRegistered<NotificationRepository>()) {
      Get.lazyPut(
        () => NotificationRepository(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<NotificationController>()) {
      Get.lazyPut(
        () => NotificationController(
          notificationRepository: Get.find<NotificationRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<NotificationLifecycleService>()) {
      Get.put(
        NotificationLifecycleService(
          deviceTokenProvider: Get.find<DeviceTokenProvider>(),
          tokenStorage: Get.find<TokenStorage>(),
          deviceTokenStorage: Get.find<DeviceTokenStorage>(),
          authRepository: Get.find<AuthRepository>(),
        ),
        permanent: true,
      );
    }

    Get.find<NotificationLifecycleService>().ensureInitialized();
  }
}
