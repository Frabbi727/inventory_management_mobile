import 'package:get/get.dart';

import '../controllers/splash_controller.dart';
import 'auth_dependencies.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    Get.lazyPut(
      () => SplashController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
