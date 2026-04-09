import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../cart_orders/presentation/controllers/cart_controller.dart';
import '../../../customers/presentation/pages/customer_directory_page.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'home_dashboard_page.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: [
            HomeDashboardPage(
              salesmanName: controller.user.value?.name ?? 'Sales',
              draftCustomerName:
                  cartController.selectedCustomer.value?.name ??
                  'No customer selected',
              draftItemCount: cartController.totalUnits,
              draftTotal: cartController.formatCurrency(
                cartController.grandTotal,
              ),
              onStartOrder: () {
                cartController.startNewOrder();
                controller.openNewOrder();
              },
            ),
            const InvoicePage(),
            const CustomerDirectoryPage(),
            ProfilePage(
              name: controller.user.value?.name ?? '-',
              email: controller.user.value?.email ?? '-',
              phone: controller.user.value?.phone ?? '-',
              role: controller.user.value?.role?.name ?? '-',
              isLoggingOut: controller.isLoggingOut.value,
              onLogout: controller.logout,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Customers',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.find<CartController>().startNewOrder();
            Get.toNamed(AppRoutes.newOrder);
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('New Order'),
        ),
      ),
    );
  }
}
