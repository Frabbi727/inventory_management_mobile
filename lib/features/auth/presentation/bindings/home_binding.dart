import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../cart_orders/presentation/bindings/cart_dependencies.dart';
import '../../../customers/presentation/bindings/customer_dependencies.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../dashboard/data/repositories/salesman_dashboard_repository.dart';
import '../../../dashboard/presentation/controllers/home_dashboard_controller.dart';
import '../../../invoice/presentation/controllers/invoice_controller.dart';
import '../../../notifications/presentation/bindings/notification_dependencies.dart';
import '../controllers/home_controller.dart';
import 'auth_dependencies.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    AuthDependencies.ensureRegistered();
    NotificationDependencies.ensureRegistered();
    CustomerDependencies.ensureRegistered();
    CartDependencies.ensureRegistered();

    if (!Get.isRegistered<CustomerSearchController>(
      tag: ControllerTags.homeCustomerSearch,
    )) {
      Get.lazyPut(
        () => CustomerSearchController(customerRepository: Get.find()),
        tag: ControllerTags.homeCustomerSearch,
      );
    }

    if (!Get.isRegistered<InvoiceController>()) {
      Get.lazyPut(
        () => InvoiceController(orderRepository: Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SalesmanDashboardRepository>()) {
      Get.lazyPut(
        () => SalesmanDashboardRepository(
          apiClient: Get.find(),
          tokenStorage: Get.find(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<HomeDashboardController>()) {
      Get.lazyPut(
        () => HomeDashboardController(
          dashboardRepository: Get.find<SalesmanDashboardRepository>(),
        ),
        fenix: true,
      );
    }

    Get.lazyPut(
      () => HomeController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        userStorage: Get.find(),
      ),
    );
  }
}
