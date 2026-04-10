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
import '../../features/inventory_manager/presentation/bindings/inventory_home_binding.dart';
import '../../features/inventory_manager/presentation/bindings/barcode_scan_binding.dart';
import '../../features/inventory_manager/presentation/bindings/create_purchase_binding.dart';
import '../../features/inventory_manager/presentation/bindings/edit_purchase_binding.dart';
import '../../features/inventory_manager/presentation/bindings/low_stock_binding.dart';
import '../../features/inventory_manager/presentation/bindings/purchase_records_binding.dart';
import '../../features/inventory_manager/presentation/bindings/product_form_binding.dart';
import '../../features/inventory_manager/presentation/bindings/purchase_details_binding.dart';
import '../../features/inventory_manager/presentation/pages/barcode_scan_page.dart';
import '../../features/inventory_manager/presentation/pages/create_purchase_page.dart';
import '../../features/inventory_manager/presentation/pages/edit_purchase_page.dart';
import '../../features/inventory_manager/presentation/pages/inventory_home_screen.dart';
import '../../features/inventory_manager/presentation/pages/low_stock_page.dart';
import '../../features/inventory_manager/presentation/pages/product_form_page.dart';
import '../../features/inventory_manager/presentation/pages/purchase_details_page.dart';
import '../../features/inventory_manager/presentation/pages/purchase_records_page.dart';
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
    GetPage<InventoryHomeScreen>(
      name: AppRoutes.inventoryHome,
      page: InventoryHomeScreen.new,
      binding: InventoryHomeBinding(),
    ),
    GetPage<BarcodeScanPage>(
      name: AppRoutes.inventoryBarcodeScan,
      page: BarcodeScanPage.new,
      binding: BarcodeScanBinding(),
    ),
    GetPage<ProductFormPage>(
      name: AppRoutes.inventoryProductForm,
      page: ProductFormPage.new,
      binding: ProductFormBinding(),
    ),
    GetPage<PurchaseRecordsPage>(
      name: AppRoutes.inventoryPurchases,
      page: PurchaseRecordsPage.new,
      binding: PurchaseRecordsBinding(),
    ),
    GetPage<CreatePurchasePage>(
      name: AppRoutes.inventoryPurchaseCreate,
      page: CreatePurchasePage.new,
      binding: CreatePurchaseBinding(),
    ),
    GetPage<PurchaseDetailsPage>(
      name: AppRoutes.inventoryPurchaseDetails,
      page: PurchaseDetailsPage.new,
      binding: PurchaseDetailsBinding(),
    ),
    GetPage<EditPurchasePage>(
      name: AppRoutes.inventoryPurchaseEdit,
      page: EditPurchasePage.new,
      binding: EditPurchaseBinding(),
    ),
    GetPage<LowStockPage>(
      name: AppRoutes.inventoryLowStock,
      page: LowStockPage.new,
      binding: LowStockBinding(),
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
