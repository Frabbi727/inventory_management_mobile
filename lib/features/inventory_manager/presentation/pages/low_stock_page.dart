import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  late final ProductListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProductListController>();
    _controller.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock')),
      body: SafeArea(
        child: Obx(() {
          final lowStockProducts = _controller.products
              .where(_isLowStock)
              .toList(growable: false);

          if (_controller.isInitialLoading.value && lowStockProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage.value != null &&
              lowStockProducts.isEmpty) {
            return AppMessageState(
              icon: Icons.cloud_off_outlined,
              message: _controller.errorMessage.value!,
              actionLabel: 'Retry',
              onAction: _controller.retry,
            );
          }

          if (lowStockProducts.isEmpty) {
            return const AppMessageState(
              icon: Icons.check_circle_outline,
              message: 'No products are below the minimum stock alert.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => _controller.ensureLoaded(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lowStockProducts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = lowStockProducts[index];
                return Card(
                  child: ListTile(
                    title: Text(product.name ?? 'Unnamed product'),
                    subtitle: Text(
                      'Current stock ${product.currentStock ?? 0} | Minimum ${product.minimumStockAlert ?? 0}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(
                      AppRoutes.productDetails,
                      arguments: product,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  bool _isLowStock(ProductModel product) {
    final currentStock = product.currentStock ?? 0;
    final minimumStockAlert = product.minimumStockAlert ?? 0;
    return currentStock <= minimumStockAlert;
  }
}
