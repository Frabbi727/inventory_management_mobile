import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/models/allocation_model.dart';
import '../controllers/allocation_controller.dart';

class EndTripPage extends StatefulWidget {
  const EndTripPage({super.key});

  @override
  State<EndTripPage> createState() => _EndTripPageState();
}

class _EndTripPageState extends State<EndTripPage> {
  final AllocationController _controller = Get.find<AllocationController>();
  final _noteController = TextEditingController();
  final Map<int, TextEditingController> _qtyControllers = {};
  final _isSubmitting = false.obs;
  final _errorMessage = RxnString();

  @override
  void initState() {
    super.initState();
    for (final item in _controller.activeAllocationItems) {
      final ctrl = TextEditingController(
        text: item.remainingQuantity > 0
            ? item.remainingQuantity.toStringAsFixed(
                item.remainingQuantity % 1 == 0 ? 0 : 2)
            : '',
      );
      _qtyControllers[item.id] = ctrl;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final items = <Map<String, dynamic>>[];
    for (final item in _controller.activeAllocationItems) {
      final text = _qtyControllers[item.id]?.text.trim() ?? '';
      final qty = double.tryParse(text) ?? 0;
      if (qty < 0) {
        _errorMessage.value =
            '${item.productNameSnapshot}: quantity cannot be negative.';
        return;
      }
      if (qty > item.remainingQuantity) {
        final display = item.remainingQuantity % 1 == 0
            ? item.remainingQuantity.toInt().toString()
            : item.remainingQuantity.toString();
        _errorMessage.value =
            '${item.productNameSnapshot}: cannot return more than remaining ($display).';
        return;
      }
      if (qty > 0) {
        items.add({
          'allocation_item_id': item.id,
          'quantity_returned': qty,
        });
      }
    }

    if (items.isEmpty) {
      _errorMessage.value = 'Enter at least one return quantity.';
      return;
    }

    _isSubmitting.value = true;
    _errorMessage.value = null;

    try {
      await _controller.submitReturns(
        items: items,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Returns submitted successfully.')),
        );
        Get.back();
      }
    } on ApiException catch (e) {
      _errorMessage.value = e.message;
    } catch (_) {
      _errorMessage.value = 'Failed to submit returns. Please try again.';
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _controller.activeAllocationItems
        .where((i) => !i.isFullyAccounted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('End Trip / Return Stock'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _TripSummaryBanner(
                  allocationNo:
                      _controller.activeAllocationNo.value ?? '',
                  itemCount: items.length,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter Return Quantities',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only items with a quantity > 0 will be submitted.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      'All items in this allocation are fully accounted for.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReturnItemRow(
                        item: item,
                        controller: _qtyControllers[item.id]!,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. End of day returns',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final msg = _errorMessage.value;
                  if (msg == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Obx(
                () => FilledButton(
                  onPressed:
                      _isSubmitting.value || items.isEmpty ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Returns',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripSummaryBanner extends StatelessWidget {
  const _TripSummaryBanner({
    required this.allocationNo,
    required this.itemCount,
  });

  final String allocationNo;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocationNo,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$itemCount unsold item type${itemCount == 1 ? '' : 's'} remaining',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnItemRow extends StatelessWidget {
  const _ReturnItemRow({
    required this.item,
    required this.controller,
  });

  final AllocationItemModel item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productNameSnapshot,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${item.remainingQuantity % 1 == 0 ? item.remainingQuantity.toInt() : item.remainingQuantity}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
