import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../controllers/purchase_view_controller.dart';

class PurchaseViewPage extends GetView<PurchaseViewController> {
  const PurchaseViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Details'),
        actions: [
          IconButton(
            tooltip: 'Edit purchase',
            onPressed: controller.openEditPurchase,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null &&
              controller.purchase.value == null) {
            return AppMessageState(
              icon: Icons.cloud_off_outlined,
              message: controller.errorMessage.value!,
              actionLabel: 'Retry',
              onAction: controller.loadPurchase,
            );
          }

          final purchase = controller.purchase.value;
          if (purchase == null) {
            return AppMessageState(
              icon: Icons.inventory_2_outlined,
              message: 'Purchase details are not available.',
              actionLabel: 'Retry',
              onAction: controller.loadPurchase,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadPurchase,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.purchaseNo?.isNotEmpty == true
                              ? purchase.purchaseNo!
                              : 'Purchase #${purchase.id ?? '-'}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          purchase.note?.trim().isNotEmpty == true
                              ? purchase.note!.trim()
                              : 'No note added for this purchase.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoPill(
                              label: 'Purchase Date',
                              value: controller.formatDate(
                                purchase.purchaseDate,
                              ),
                            ),
                            _InfoPill(
                              label: 'Total Amount',
                              value: controller.formatCurrency(
                                purchase.totalAmount,
                              ),
                            ),
                            _InfoPill(
                              label: 'Items',
                              value: '${purchase.itemsCount ?? 0}',
                            ),
                            _InfoPill(
                              label: 'Creator',
                              value: purchase.creator?.name ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MetaTile(
                                label: 'Created',
                                value: controller.formatDateTime(
                                  purchase.createdAt,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetaTile(
                                label: 'Updated',
                                value: controller.formatDateTime(
                                  purchase.updatedAt,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...(purchase.items ?? const []).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product?.name ??
                                  item.productName ??
                                  'Unnamed product',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.product?.sku?.isNotEmpty == true
                                  ? item.product!.sku!
                                  : item.productBarcode ?? '-',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoPill(
                                  label: 'Category',
                                  value: item.product?.category?.name ?? '-',
                                ),
                                _InfoPill(
                                  label: 'Unit',
                                  value:
                                      item.product?.unit?.shortName ??
                                      item.product?.unit?.name ??
                                      '-',
                                ),
                                _InfoPill(
                                  label: 'Quantity',
                                  value: '${item.quantity ?? 0}',
                                ),
                                _InfoPill(
                                  label: 'Unit Cost',
                                  value: controller.formatCurrency(
                                    item.unitCost,
                                  ),
                                ),
                                _InfoPill(
                                  label: 'Line Total',
                                  value: controller.formatCurrency(
                                    item.lineTotal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.75,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
