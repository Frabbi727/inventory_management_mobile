import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../profile/presentation/pages/profile_page.dart';
import '../controllers/inventory_home_controller.dart';
import 'inventory_products_page.dart';
import 'purchase_list_page.dart';
import '../widgets/inventory_bottom_navigation.dart';

class InventoryHomeScreen extends GetView<InventoryHomeController> {
  const InventoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: [
            const InventoryProductsPage(),
            const PurchaseListPage(),
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
        bottomNavigationBar: InventoryBottomNavigation(
          selectedIndex: controller.selectedIndex.value,
          onTabSelected: controller.changeTab,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: controller.selectedIndex.value == 2
            ? null
            : InventoryScanButton(onPressed: controller.openScan),
      ),
    );
  }
}
