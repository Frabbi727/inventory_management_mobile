import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/data/models/order_model.dart';
import '../controllers/invoice_controller.dart';

class InvoicePage extends GetView<InvoiceController> {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Orders',
              subtitle:
                  'View recent orders and open any order for full details.',
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
                  return AppMessageState(
                    icon: Icons.cloud_off_outlined,
                    message: controller.errorMessage.value!,
                    actionLabel: 'Retry',
                    onAction: controller.retry,
                  );
                }

                if (controller.orders.isEmpty) {
                  return AppMessageState(
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNo ?? 'Order',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.customer?.name ?? '-',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OrderPill(text: _titleCase(order.status)),
                        _OrderPill(text: formatDate(order.orderDate)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(order.grandTotal),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _OrderPill extends StatelessWidget {
  const _OrderPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}
