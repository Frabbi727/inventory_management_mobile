import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../controllers/inventory_home_controller.dart';
import 'inventory_products_page.dart';
import 'inventory_summary_page.dart';

class InventoryHomeScreen extends GetView<InventoryHomeController> {
  const InventoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = controller.selectedIndex.value == 1
          ? 0
          : controller.selectedIndex.value;

      return Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            const InventoryProductsPage(),
            const SizedBox.shrink(),
            const InventorySummaryPage(),
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
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == 1) {
              Get.toNamed(AppRoutes.inventoryPurchaseCreate);
              return;
            }

            controller.changeTab(index);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Purchases',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );
    });
  }
}
