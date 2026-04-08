import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import 'auth_dependencies.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    Get.lazyPut(
      () => HomeController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
