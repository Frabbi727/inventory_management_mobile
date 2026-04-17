import 'package:get/get.dart';

import '../../../notifications/presentation/bindings/notification_dependencies.dart';
import '../controllers/splash_controller.dart';
import 'auth_dependencies.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    NotificationDependencies.ensureRegistered();
    Get.lazyPut(
      () => SplashController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
