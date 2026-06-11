import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/allocation_model.dart';
import '../controllers/allocation_controller.dart';

class AllocationDetailPage extends GetView<AllocationController> {
  const AllocationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trip Details'),
                if (controller.activeAllocationNo.value != null)
                  Text(
                    controller.activeAllocationNo.value!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            )),
        centerTitle: false,
        actions: [
          Obx(() => controller.isRefreshing.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.refreshActiveAllocation,
                  tooltip: 'Refresh',
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isRefreshing.value &&
            controller.activeAllocationItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.hasActiveAllocation) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active trip',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask your admin to dispatch an allocation.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: Get.back,
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = controller.activeAllocationItems;

        return Column(
          children: [
            _SummaryBar(items: items),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshActiveAllocation,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ItemCard(item: items[index]),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.items});
  final List<AllocationItemModel> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withStock = items.where((i) => !i.isFullyAccounted).length;

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Chip(label: 'Products', value: '${items.length}'),
          const SizedBox(width: 8),
          _Chip(label: 'With stock', value: '$withStock'),
          const SizedBox(width: 8),
          _Chip(
            label: 'Fully sold',
            value: '${items.length - withStock}',
            muted: true,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.muted = false});
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: muted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final AllocationItemModel item;

  String _formatQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = item.remainingQuantity;
    final isSoldOut = item.isFullyAccounted;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isSoldOut
                  ? theme.colorScheme.outline
                  : const Color(0xFF166534),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productNameSnapshot,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSoldOut
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                if (isSoldOut)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sold out',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _QtyBadge(
                  label: 'Allocated',
                  value: _formatQty(item.quantityAllocated),
                  color: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                _QtyBadge(
                  label: 'Sold',
                  value: _formatQty(item.quantitySold),
                  color: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                _QtyBadge(
                  label: 'Remaining',
                  value: _formatQty(remaining),
                  color: isSoldOut
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFDFF7EA),
                  textColor: isSoldOut
                      ? theme.colorScheme.onSurfaceVariant
                      : const Color(0xFF166534),
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
