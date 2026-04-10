import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/barcode_scan_models.dart';

class CreatePurchasePage extends StatefulWidget {
  const CreatePurchasePage({super.key});

  @override
  State<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends State<CreatePurchasePage> {
  final TextEditingController _barcodeController = TextEditingController();
  final List<_PurchaseDraftItem> _items = <_PurchaseDraftItem>[];
  bool _isResolving = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Purchase')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scan or enter a barcode to add a line item to the purchase draft.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                prefixIcon: Icon(Icons.qr_code_2),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addByBarcode(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isResolving ? null : _addByBarcode,
                    icon: _isResolving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task),
                    label: const Text('Add Item'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Draft Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No items added yet. Add a barcode to start building the receiving draft.',
                  ),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Barcode: ${item.barcode}'),
                          const SizedBox(height: 6),
                          Text('Product ID: ${item.productId}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _changeQuantity(index, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${item.quantity}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changeQuantity(index, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const Spacer(),
                              Text(
                                'Unit cost ৳${item.unitCost.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: _items.isEmpty ? null : _submitDraft,
            child: const Text('Submit Purchase Draft'),
          ),
        ),
      ),
    );
  }

  Future<void> _addByBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      Get.snackbar(
        'Barcode required',
        'Enter a barcode before adding an item.',
      );
      return;
    }

    setState(() {
      _isResolving = true;
    });

    try {
      final response = await Get.find<InventoryManagerRepository>()
          .getPurchaseProductByBarcode(barcode);
      final product = response.data;

      if (product == null || product.id == null) {
        Get.snackbar(
          'Product not found',
          'Create the product first, then add it to the purchase draft.',
        );
        return;
      }

      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      setState(() {
        if (existingIndex >= 0) {
          _items[existingIndex] = _items[existingIndex].copyWith(
            quantity: _items[existingIndex].quantity + 1,
          );
        } else {
          _items.add(
            _PurchaseDraftItem(
              productId: product.id!,
              name: product.name ?? 'Unnamed product',
              barcode: product.barcode ?? barcode,
              quantity: 1,
              unitCost: (product.purchasePrice ?? 0).toDouble(),
            ),
          );
        }
      });
      _barcodeController.clear();
    } catch (_) {
      Get.snackbar(
        'Unable to add item',
        'Barcode lookup failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  void _changeQuantity(int index, int delta) {
    final current = _items[index];
    final nextQuantity = current.quantity + delta;
    if (nextQuantity < 1) {
      return;
    }

    setState(() {
      _items[index] = current.copyWith(quantity: nextQuantity);
    });
  }

  void _submitDraft() {
    Get.snackbar(
      'Draft captured',
      'Purchase items were collected in the new receiving flow. Connect the backend purchase save contract next to persist them.',
    );
  }

  Future<void> _openScanner() async {
    final result = await Get.toNamed(
      AppRoutes.inventoryBarcodeScan,
      arguments: const BarcodeScanArgs(
        context: BarcodeScanContext.purchaseLookup,
      ),
    );

    if (result is BarcodeScanResult) {
      _barcodeController.text = result.barcode;
      await _addByBarcode();
    }
  }
}

class _PurchaseDraftItem {
  const _PurchaseDraftItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.quantity,
    required this.unitCost,
  });

  final int productId;
  final String name;
  final String barcode;
  final int quantity;
  final double unitCost;

  _PurchaseDraftItem copyWith({
    int? productId,
    String? name,
    String? barcode,
    int? quantity,
    double? unitCost,
  }) {
    return _PurchaseDraftItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}
