import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import 'auth_dependencies.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    Get.lazyPut(
      () => LoginController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
