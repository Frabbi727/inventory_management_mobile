import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/home_binding.dart';
import '../../features/auth/presentation/bindings/login_binding.dart';
import '../../features/auth/presentation/bindings/splash_binding.dart';
import '../../features/auth/presentation/pages/home_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/customers/presentation/bindings/add_customer_binding.dart';
import '../../features/customers/presentation/bindings/customer_binding.dart';
import '../../features/customers/presentation/pages/add_customer_page.dart';
import '../../features/customers/presentation/pages/customer_search_page.dart';
import '../../features/cart_orders/presentation/bindings/new_order_binding.dart';
import '../../features/cart_orders/presentation/pages/new_order_page.dart';
import '../../features/cart_orders/presentation/pages/order_success_page.dart';
import '../../features/invoice/presentation/bindings/order_details_binding.dart';
import '../../features/invoice/presentation/pages/order_details_page.dart';
import '../../features/products/presentation/bindings/product_details_binding.dart';
import '../../features/products/presentation/pages/product_details_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage<SplashScreen>(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: SplashBinding(),
    ),
    GetPage<LoginScreen>(
      name: AppRoutes.login,
      page: LoginScreen.new,
      binding: LoginBinding(),
    ),
    GetPage<HomeScreen>(
      name: AppRoutes.home,
      page: HomeScreen.new,
      binding: HomeBinding(),
    ),
    GetPage<NewOrderPage>(
      name: AppRoutes.newOrder,
      page: NewOrderPage.new,
      binding: NewOrderBinding(),
    ),
    GetPage<CustomerSearchPage>(
      name: AppRoutes.customerSearch,
      page: CustomerSearchPage.new,
      binding: CustomerBinding(),
    ),
    GetPage<AddCustomerPage>(
      name: AppRoutes.addCustomer,
      page: AddCustomerPage.new,
      binding: AddCustomerBinding(),
    ),
    GetPage<ProductDetailsPage>(
      name: AppRoutes.productDetails,
      page: ProductDetailsPage.new,
      binding: ProductDetailsBinding(),
    ),
    GetPage<OrderSuccessPage>(
      name: AppRoutes.orderSuccess,
      page: OrderSuccessPage.new,
    ),
    GetPage<OrderDetailsPage>(
      name: AppRoutes.orderDetails,
      page: OrderDetailsPage.new,
      binding: OrderDetailsBinding(),
    ),
  ];
}
