import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../controllers/invoice_controller.dart';

class InvoicePage extends GetView<InvoiceController> {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orders',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isInitialLoading.value &&
                    controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value != null &&
                    controller.orders.isEmpty) {
                  return _MessageState(
                    icon: Icons.cloud_off_outlined,
                    message: controller.errorMessage.value!,
                    actionLabel: 'Retry',
                    onAction: controller.retry,
                  );
                }

                if (controller.orders.isEmpty) {
                  return _MessageState(
                    icon: Icons.receipt_long_outlined,
                    message:
                        controller.infoMessage.value ??
                        'No orders have been created yet.',
                    actionLabel: 'Refresh',
                    onAction: controller.retry,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.retry,
                  child: ListView.separated(
                    controller: controller.scrollController,
                    itemCount:
                        controller.orders.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= controller.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final order = controller.orders[index];
                      return _OrderCard(
                        order: order,
                        formatCurrency: controller.formatCurrency,
                        formatDate: controller.formatDate,
                        onTap: () => _openOrderDetails(order),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrderDetails(OrderModel order) {
    if (order.id == null) {
      return;
    }

    Get.toNamed(AppRoutes.orderDetails, arguments: order);
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.formatCurrency,
    required this.formatDate,
    required this.onTap,
  });

  final OrderModel order;
  final String Function(num? value) formatCurrency;
  final String Function(String? value) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(order.orderNo ?? 'Order'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${order.customer?.name ?? '-'}\n${_titleCase(order.status)} • ${formatDate(order.orderDate)}',
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(order.grandTotal),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text('View'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _titleCase(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
