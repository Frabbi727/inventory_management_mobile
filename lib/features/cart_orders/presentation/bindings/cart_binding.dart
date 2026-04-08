import 'package:get/get.dart';

import 'cart_dependencies.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    CartDependencies.ensureRegistered();
  }
}
