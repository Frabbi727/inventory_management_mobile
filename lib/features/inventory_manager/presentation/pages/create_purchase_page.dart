import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../../data/models/create_or_update_purchase_request.dart';
import '../../data/models/inventory_purchase_item_request.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../controllers/purchase_draft_controller.dart';
import '../models/barcode_scan_models.dart';
import 'product_form_page.dart';

class CreatePurchasePage extends StatefulWidget {
  const CreatePurchasePage({super.key});

  @override
  State<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends State<CreatePurchasePage> {
  late final ProductListController _productListController;
  late final PurchaseDraftController _purchaseDraftController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isResolvingBarcode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _productListController = Get.find<ProductListController>();
    _purchaseDraftController = Get.find<PurchaseDraftController>();
    _productListController.ensureLoaded();
    final argument = Get.arguments;
    if (argument is PurchaseResponseModel) {
      _purchaseDraftController.loadFromPurchaseResponse(argument);
    }
    _noteController.text = _purchaseDraftController.note.value;
    _noteController.addListener(_syncDraftHeader);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController
      ..removeListener(_syncDraftHeader)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: SafeArea(
        child: Obx(() {
          final products = _productListController.products.toList();
          final draftItems = _purchaseDraftController.items.toList(
            growable: false,
          );

          return RefreshIndicator(
            onRefresh: () =>
                _productListController.ensureLoaded(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  'Search products, filter by category, or scan a barcode to open purchase details for one product at a time.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _PurchaseHeaderCard(
                  controller: _purchaseDraftController,
                  noteController: _noteController,
                  onPickDate: _pickDate,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _productListController.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by product name, SKU, or barcode',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _productListController.hasActiveSearch
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _productListController.clearSearch();
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isResolvingBarcode ? null : _openScanner,
                      icon: _isResolvingBarcode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PurchaseCategoryFilterSection(
                  controller: _productListController,
                ),
                const SizedBox(height: 20),
                if (draftItems.isNotEmpty) ...[
                  _DraftSummaryCard(
                    controller: _purchaseDraftController,
                    onReset: _resetDraft,
                    onSubmit: _submitPurchase,
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_productListController.isInitialLoading.value &&
                    products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_productListController.hasErrorState)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productListController.errorMessage.value ??
                                'Unable to load products.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _productListController.retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (products.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No products found for the current search and category filters.',
                      ),
                    ),
                  )
                else
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PurchaseProductCard(
                        product: product,
                        alreadyAdded:
                            product.id != null &&
                            _purchaseDraftController.hasItem(product.id!),
                        onTap: () => _openPurchaseDetails(product),
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

  void _syncDraftHeader() {
    _purchaseDraftController.setPurchaseHeader(
      purchaseDateValue: _purchaseDraftController.purchaseDate.value,
      noteValue: _noteController.text,
    );
  }

  Future<void> _pickDate() async {
    final current = _purchaseDraftController.purchaseDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    _purchaseDraftController.setPurchaseHeader(
      purchaseDateValue: picked,
      noteValue: _noteController.text,
    );
  }

  Future<void> _openScanner() async {
    setState(() {
      _isResolvingBarcode = true;
    });

    try {
      final result = await Get.toNamed(
        AppRoutes.inventoryBarcodeScan,
        arguments: const BarcodeScanArgs(
          context: BarcodeScanContext.purchaseLookup,
        ),
      );

      if (result is! BarcodeScanResult) {
        return;
      }

      final response = await Get.find<InventoryManagerRepository>()
          .getPurchaseProductByBarcode(result.barcode);
      final product = response.data;
      if (product?.id == null) {
        _showProductNotFoundDialog(result.barcode);
        return;
      }

      _openPurchaseDetails(product!);
    } catch (_) {
      Get.snackbar(
        'Unable to resolve barcode',
        'The barcode could not be matched right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingBarcode = false;
        });
      }
    }
  }

  void _openPurchaseDetails(ProductModel product) {
    Get.toNamed(AppRoutes.inventoryPurchaseDetails, arguments: product);
  }

  Future<void> _submitPurchase() async {
    final draftItems = _purchaseDraftController.items.toList(growable: false);
    if (draftItems.isEmpty) {
      setState(() {
        _errorMessage = 'Add at least one item before submitting the purchase.';
      });
      return;
    }

    final request = CreateOrUpdatePurchaseRequest(
      purchaseDate: _formatDate(_purchaseDraftController.purchaseDate.value),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      items: draftItems
          .map(
            (item) => InventoryPurchaseItemRequest(
              productId: item.productId,
              quantity: item.quantity,
              unitCost: item.unitCost,
            ),
          )
          .toList(),
    );

    setState(() {
      _errorMessage = null;
    });
    _purchaseDraftController.beginSubmit();
    final wasEditing = _purchaseDraftController.isEditingPurchase;

    try {
      final repository = Get.find<InventoryManagerRepository>();
      final response = wasEditing
          ? await repository.updatePurchase(
              _purchaseDraftController.purchaseId.value!,
              request,
            )
          : await repository.createPurchase(request);

      if (!mounted) {
        return;
      }

      _purchaseDraftController.resetDraft();
      _noteController.clear();
      Get.snackbar(
        wasEditing ? 'Purchase updated' : 'Purchase created',
        response.purchaseNo == null
            ? 'Purchase saved successfully.'
            : 'Purchase ${response.purchaseNo} saved successfully.',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _buildPurchaseError(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to save the purchase right now.';
      });
    } finally {
      _purchaseDraftController.endSubmit();
    }
  }

  void _resetDraft() {
    _purchaseDraftController.resetDraft();
    _noteController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  String _buildPurchaseError(ApiException error) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return error.message;
    }

    final itemsError = errors['items'];
    if (itemsError is List && itemsError.isNotEmpty) {
      return itemsError.first.toString();
    }

    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return error.message;
  }

  void _showProductNotFoundDialog(String barcode) {
    Get.dialog(
      AlertDialog(
        title: const Text('Product not found'),
        content: Text(
          'No existing product matched "$barcode". You can create a new product or return to the list.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Back')),
          FilledButton(
            onPressed: () {
              Get.back();
              Get.toNamed(
                AppRoutes.inventoryProductForm,
                arguments: ProductFormArgs.create(barcode: barcode),
              );
            },
            child: const Text('Create Product'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _PurchaseHeaderCard extends StatelessWidget {
  const _PurchaseHeaderCard({
    required this.controller,
    required this.noteController,
    required this.onPickDate,
  });

  final PurchaseDraftController controller;
  final TextEditingController noteController;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(controller.purchaseDate.value)),
                    ),
                  ),
                ),
                if (controller.isEditingPurchase) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      controller.purchaseNo.value ?? 'Editing',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _PurchaseCategoryFilterSection extends StatelessWidget {
  const _PurchaseCategoryFilterSection({required this.controller});

  final ProductListController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.categories.toList(growable: false);
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: controller.selectedCategoryId.value == null,
            onSelected: (_) => controller.clearCategory(),
          ),
          const SizedBox(width: 8),
          ...categories.expand(
            (category) => <Widget>[
              FilterChip(
                label: Text(category.name ?? 'Category'),
                selected: controller.selectedCategoryId.value == category.id,
                onSelected: (_) => controller.onCategoryChanged(category.id),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseProductCard extends StatelessWidget {
  const _PurchaseProductCard({
    required this.product,
    required this.alreadyAdded,
    required this.onTap,
  });

  final ProductModel product;
  final bool alreadyAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unnamed product',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('SKU: ${product.sku ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Barcode: ${product.barcode ?? '-'}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          label: 'Stock',
                          value: '${product.currentStock ?? 0}',
                        ),
                        _MetaPill(
                          label: 'Category',
                          value: product.category?.name ?? '-',
                        ),
                        _MetaPill(
                          label: 'Cost',
                          value: '৳${(product.purchasePrice ?? 0).toString()}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (alreadyAdded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF4E6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Added',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DraftSummaryCard extends StatelessWidget {
  const _DraftSummaryCard({
    required this.controller,
    required this.onReset,
    required this.onSubmit,
  });

  final PurchaseDraftController controller;
  final VoidCallback onReset;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = controller.items.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.isEditingPurchase
                  ? 'Editing Purchase'
                  : 'Purchase Draft',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text('$itemCount item${itemCount == 1 ? '' : 's'} selected'),
            const SizedBox(height: 4),
            Text(
              'Total ৳${controller.draftTotal.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.isSubmitting.value ? null : onReset,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.isSubmitting.value ? null : onSubmit,
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            controller.isEditingPurchase
                                ? 'Update Purchase'
                                : 'Submit Purchase',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
