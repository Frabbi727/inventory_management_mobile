import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../controllers/low_stock_controller.dart';

class LowStockPage extends GetView<LowStockController> {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitialLoading.value &&
              controller.lowStockProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null &&
              controller.lowStockProducts.isEmpty) {
            return AppMessageState(
              icon: Icons.cloud_off_outlined,
              message: controller.errorMessage.value!,
              actionLabel: 'Retry',
              onAction: controller.retry,
            );
          }

          if (controller.lowStockProducts.isEmpty) {
            return const AppMessageState(
              icon: Icons.check_circle_outline,
              message: 'No products are below the minimum stock alert.',
            );
          }

          return RefreshIndicator(
            onRefresh: controller.retry,
            child: ListView.separated(
              controller: controller.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: controller.lowStockProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = controller.lowStockProducts[index];
                return Card(
                  child: ListTile(
                    title: Text(product.name ?? 'Unnamed product'),
                    subtitle: Text(
                      'Current stock ${product.currentStock ?? 0} | Minimum ${product.minimumStockAlert ?? 0}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.openDetails(product),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
