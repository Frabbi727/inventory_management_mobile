import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_searchable_select.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../products/presentation/controllers/product_list_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/order_flow_widgets.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  static const _steps = ['Customer', 'Products', 'Cart', 'Confirm'];

  late final CartController controller;
  late final CustomerSearchController customerController;
  late final ProductListController productController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CartController>();
    customerController = Get.find<CustomerSearchController>(
      tag: ControllerTags.newOrderCustomerSearch,
    );
    productController = Get.find<ProductListController>(
      tag: ControllerTags.newOrderProductSearch,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      productController.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('New Order')),
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepperWidget(
                      steps: _steps,
                      currentStep: controller.currentStep.value,
                      onStepTap: controller.goToStep,
                    ),
                    if (controller.infoMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineInfoBanner(
                        message: controller.infoMessage.value!,
                      ),
                    ],
                    if (controller.errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      InlineWarningBanner(
                        message: controller.errorMessage.value!,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Padding(
                    key: ValueKey(controller.currentStep.value),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: switch (controller.currentStep.value) {
                      CartController.customerStep => _CustomerStep(
                        cartController: controller,
                        customerController: customerController,
                      ),
                      CartController.productsStep => _ProductsStep(
                        cartController: controller,
                        productController: productController,
                      ),
                      CartController.cartStep => _CartStep(
                        controller: controller,
                      ),
                      _ => _ConfirmStep(controller: controller),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => SummaryFooter(
          showTotals: false,
          primaryLabel: _primaryLabel(controller.currentStep.value),
          tertiaryLabel: controller.currentStep.value == CartController.confirmStep
              ? (controller.hasSavedDraft ? 'Update Draft' : 'Save Draft')
              : null,
          onTertiaryPressed:
              controller.currentStep.value == CartController.confirmStep &&
                  controller.canSaveDraft
              ? () async {
                  await controller.saveDraft();
                }
              : null,
          secondaryLabel:
              controller.currentStep.value == CartController.customerStep
              ? null
              : 'Back',
          onSecondaryPressed:
              controller.currentStep.value == CartController.customerStep
              ? null
              : controller.previousStep,
          isLoading: controller.isSubmitting.value,
          onPrimaryPressed:
              controller.currentStep.value == CartController.confirmStep
              ? (controller.canConfirm
                    ? () async {
                        final shouldConfirm = await _showConfirmOrderDialog();
                        if (shouldConfirm == true) {
                          await controller.confirmOrder();
                        }
                      }
                    : null)
              : (controller.canContinueCurrentStep
                    ? controller.nextStep
                    : null),
        ),
      ),
    );
  }

  String _primaryLabel(int step) {
    if (step == CartController.confirmStep && !controller.canConfirm) {
      return 'Resolve Stock Warnings';
    }

    return controller.submitButtonLabel();
  }

  Future<bool?> _showConfirmOrderDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text(
          'Are you sure you want to confirm this order? You can still save it as a draft if you need more changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _CustomerStep extends StatefulWidget {
  const _CustomerStep({
    required this.cartController,
    required this.customerController,
  });

  final CartController cartController;
  final CustomerSearchController customerController;

  @override
  State<_CustomerStep> createState() => _CustomerStepState();
}

class _CustomerStepState extends State<_CustomerStep> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.customerController.searchQuery.value,
    );
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    widget.customerController.loadMoreIfNeeded(_scrollController.position);
  }

  Future<void> _openAddCustomer() async {
    final result = await Get.toNamed(AppRoutes.addCustomer);
    if (result is CustomerModel) {
      widget.cartController.setSelectedCustomer(result);
      _searchController.clear();
      widget.customerController.clearSearch();
      await widget.customerController.retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = widget.cartController;
      final customerController = widget.customerController;
      final selectedCustomer = cartController.selectedCustomer.value;
      final customers = customerController.customers;

      if (_searchController.text != customerController.searchQuery.value) {
        _searchController.value = TextEditingValue(
          text: customerController.searchQuery.value,
          selection: TextSelection.collapsed(
            offset: customerController.searchQuery.value.length,
          ),
        );
      }

      final showInitialLoader =
          customerController.isInitialLoading.value && customers.isEmpty;
      final showErrorState = customerController.hasErrorState;
      final showEmptyState = customerController.hasEmptyState;

      return RefreshIndicator(
        onRefresh: customerController.retry,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchActionPanel(
                    searchController: _searchController,
                    isSearching: customerController.isSearching.value,
                    onChanged: customerController.onSearchChanged,
                    onClear: () {
                      _searchController.clear();
                      customerController.clearSearch();
                    },
                    onAddCustomer: _openAddCustomer,
                  ),
                  if (selectedCustomer != null) ...[
                    const SizedBox(height: 16),
                    _SelectedCustomerBanner(
                      customer: selectedCustomer,
                      onClear: () => cartController.setSelectedCustomer(null),
                    ),
                  ],
                  if (customerController.errorMessage.value != null &&
                      customers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InlineWarningBanner(
                      message: customerController.errorMessage.value!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerController.hasActiveSearch
                              ? 'Search results'
                              : 'Available customers',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (customers.isNotEmpty)
                        Text(
                          '${customers.length} found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (showInitialLoader)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (showErrorState)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppMessageState(
                  icon: Icons.cloud_off_outlined,
                  message: customerController.errorMessage.value!,
                  actionLabel: 'Retry',
                  onAction: customerController.retry,
                ),
              )
            else if (showEmptyState)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppMessageState(
                  icon: Icons.person_search_outlined,
                  message:
                      customerController.infoMessage.value ??
                      'No customers matched your search.',
                  actionLabel: customerController.hasActiveSearch
                      ? 'Clear Search'
                      : 'Refresh',
                  onAction: customerController.hasActiveSearch
                      ? () async {
                          _searchController.clear();
                          customerController.clearSearch();
                        }
                      : () async {
                          await customerController.retry();
                        },
                ),
              )
            else
              SliverList.separated(
                itemCount: customers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final isSelected =
                      cartController.selectedCustomer.value?.id == customer.id;

                  return CustomerTile(
                    customerName: customer.name ?? 'Unnamed customer',
                    phone: customer.phone ?? '-',
                    address: customer.address ?? '-',
                    area: customer.area,
                    onTap: () => cartController.setSelectedCustomer(customer),
                    trailing: FilledButton(
                      onPressed: () =>
                          cartController.setSelectedCustomer(customer),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(92, 42),
                        backgroundColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.primary,
                        foregroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary,
                      ),
                      child: Text(isSelected ? 'Selected' : 'Select'),
                    ),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: customerController.isLoadingMore.value
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SearchActionPanel extends StatelessWidget {
  const _SearchActionPanel({
    required this.searchController,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
    required this.onAddCustomer,
  });

  final TextEditingController searchController;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search customer name or phone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddCustomer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Customer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCustomerBanner extends StatelessWidget {
  const _SelectedCustomerBanner({
    required this.customer,
    required this.onClear,
  });

  final CustomerModel customer;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.check_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected customer',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.name ?? '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone ?? customer.address ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _ProductsStep extends StatefulWidget {
  const _ProductsStep({
    required this.cartController,
    required this.productController,
  });

  final CartController cartController;
  final ProductListController productController;

  @override
  State<_ProductsStep> createState() => _ProductsStepState();
}

class _ProductsStepState extends State<_ProductsStep> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.productController.searchQuery.value,
    );
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    widget.productController.loadMoreIfNeeded(_scrollController.position);
  }

  void _applyProductQuantity(
    CartController cartController,
    ProductModel product,
    int quantity, {
    ProductVariantModel? variant,
  }) {
    final existingQuantity = cartController.quantityForLine(
      product.id,
      productVariantId: variant?.id,
    );

    if (existingQuantity > 0) {
      cartController.setLineQuantity(
        cartController.lineKeyFor(product.id, productVariantId: variant?.id),
        quantity,
      );
      return;
    }

    if (quantity <= 0) {
      return;
    }

    cartController.addProduct(product, variant: variant, quantity: quantity);
  }

  Future<ProductModel> _resolveVariantProduct(ProductModel product) async {
    if ((product.variants ?? const <ProductVariantModel>[]).isNotEmpty) {
      return product;
    }

    final repository = Get.find<ProductRepository>();
    final response = await repository.fetchProductDetails(product.id!);
    return response.data ?? product;
  }

  Future<void> _openVariantPicker(
    BuildContext context,
    ProductModel product,
    CartController cartController,
    ProductListController productController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: FutureBuilder<ProductModel>(
              future: _resolveVariantProduct(product),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final resolvedProduct = snapshot.data ?? product;
                final variants = resolvedProduct.variants ?? const [];

                if (snapshot.hasError || variants.isEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedProduct.name ?? 'Select Variant',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variant information is not available right now. Open the details page to review this product.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                Get.toNamed(
                                  AppRoutes.productDetails,
                                  arguments: resolvedProduct,
                                );
                              },
                              child: const Text('View Details'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Obx(
                  () {
                    final _ = cartController.items.length;

                    return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedProduct.name ?? 'Select Variant',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose a variant and type the quantity you want to add.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: variants.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final variant = variants[index];
                            final availableStock = variant.currentStock ?? 0;
                            final isUnavailable = availableStock <= 0;
                            final quantity = cartController.quantityForLine(
                              resolvedProduct.id,
                              productVariantId: variant.id,
                            );

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              variant.combinationLabel ??
                                                  variant.combinationKey ??
                                                  'Variant',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${productController.formatPrice(variant.sellingPrice)} • Stock $availableStock',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      QuantityStepper(
                                        key: ValueKey(
                                          'variant-qty-${resolvedProduct.id}-${variant.id}',
                                        ),
                                        quantity: quantity,
                                        onIncrement: isUnavailable
                                            ? null
                                            : () => _applyProductQuantity(
                                                cartController,
                                                resolvedProduct,
                                                quantity + 1,
                                                variant: variant,
                                              ),
                                        onDecrement: quantity <= 0
                                            ? null
                                            : () => _applyProductQuantity(
                                                cartController,
                                                resolvedProduct,
                                                quantity - 1,
                                                variant: variant,
                                              ),
                                        onSubmitted: isUnavailable
                                            ? null
                                            : (value) => _applyProductQuantity(
                                                cartController,
                                                resolvedProduct,
                                                value,
                                                variant: variant,
                                              ),
                                        canIncrement: !isUnavailable,
                                        enabled: !isUnavailable,
                                      ),
                                    ],
                                  ),
                                  if (isUnavailable) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'This variant is out of stock.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                Get.toNamed(
                                  AppRoutes.productDetails,
                                  arguments: resolvedProduct,
                                );
                              },
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    ProductListController productController,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Obx(
              () {
                final categoryOptions = productController.categories
                    .where((category) => category.id != null)
                    .map(
                      (category) => AppSearchableSelectOption<int>(
                        value: category.id!,
                        label: category.name ?? 'Category',
                      ),
                    )
                    .toList(growable: false);
                final subcategoryOptions = productController.subcategories
                    .where((subcategory) => subcategory.id != null)
                    .map(
                      (subcategory) => AppSearchableSelectOption<int>(
                        value: subcategory.id!,
                        label: subcategory.name ?? 'Subcategory',
                        searchTerms: [
                          subcategory.name ?? '',
                          productController.categories
                                  .firstWhereOrNull(
                                    (category) =>
                                        category.id == subcategory.categoryId,
                                  )
                                  ?.name ??
                              '',
                        ],
                      ),
                    )
                    .toList(growable: false);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Products',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a category and subcategory to narrow the item list.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppSearchableSelectField<int>(
                      label: 'Category',
                      searchHint: 'Search category',
                      options: categoryOptions,
                      value: productController.selectedCategoryId.value,
                      placeholder: productController.categories.isEmpty
                          ? 'No categories available'
                          : 'All categories',
                      prefixIcon: Icons.category_outlined,
                      onChanged: productController.onCategoryChanged,
                      enabled: productController.categories.isNotEmpty,
                      isLoading: productController.isCategoriesLoading.value,
                      helperText: 'Filter products by category.',
                      clearLabel: 'All categories',
                    ),
                    const SizedBox(height: 12),
                    AppSearchableSelectField<int>(
                      label: 'Subcategory',
                      searchHint: 'Search subcategory',
                      options: subcategoryOptions,
                      value: productController.selectedSubcategoryId.value,
                      placeholder: productController.selectedCategoryId.value == null
                          ? 'Select a category first'
                          : productController.subcategories.isEmpty
                          ? 'No subcategories available'
                          : 'All subcategories',
                      prefixIcon: Icons.account_tree_outlined,
                      onChanged: productController.selectedCategoryId.value == null
                          ? null
                          : productController.onSubcategoryChanged,
                      enabled: productController.selectedCategoryId.value != null,
                      isLoading: productController.isSubcategoriesLoading.value,
                      helperText: productController.selectedCategoryId.value == null
                          ? 'Choose a category to load subcategories.'
                          : 'Refine the selected category.',
                      clearLabel: productController.selectedCategoryId.value == null
                          ? null
                          : 'All subcategories',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              productController.clearFilters();
                              _searchController.clear();
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final productController = widget.productController;
      final cartController = widget.cartController;
      final _ = cartController.items.length;

      if (_searchController.text != productController.searchQuery.value) {
        _searchController.value = TextEditingValue(
          text: productController.searchQuery.value,
          selection: TextSelection.collapsed(
            offset: productController.searchQuery.value.length,
          ),
        );
      }

      final products = productController.products;
      final categories = productController.categories;
      final selectedCategoryId = productController.selectedCategoryId.value;
      final selectedSubcategoryId =
          productController.selectedSubcategoryId.value;
      final showInitialLoader =
          productController.isInitialLoading.value && products.isEmpty;
      final showErrorState = productController.hasErrorState;
      final showEmptyState = productController.hasEmptyState;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderSearchField(
                  controller: _searchController,
                  hintText: 'Search by product name or SKU',
                  isLoading: productController.isSearching.value,
                  onChanged: productController.onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    productController.clearSearch();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productController.hasActiveSearch
                            ? 'Search results'
                            : productController.hasActiveCategory ||
                                  productController.hasActiveSubcategory
                            ? 'Filtered products'
                            : 'Available products',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _openFilterSheet(
                        context,
                        productController,
                      ),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune),
                          if (productController.hasActiveCategory ||
                              productController.hasActiveSubcategory)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${(selectedCategoryId != null ? 1 : 0) + (selectedSubcategoryId != null ? 1 : 0)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: const Text('Filters'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (products.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${products.length} FOUND',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (productController.hasActiveCategory) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categories
                                  .firstWhereOrNull(
                                    (category) =>
                                        category.id == selectedCategoryId,
                                  )
                                  ?.name ??
                              'Category selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (productController.hasActiveFilter)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          productController.clearFilters();
                        },
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                if (productController.errorMessage.value != null &&
                    products.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InlineWarningBanner(
                    message: productController.errorMessage.value!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: productController.retry,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
            if (showInitialLoader)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (showErrorState)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppMessageState(
                  icon: Icons.cloud_off_outlined,
                  message: productController.errorMessage.value!,
                  actionLabel: 'Retry',
                  onAction: productController.retry,
                ),
              )
            else if (showEmptyState)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppMessageState(
                  icon: Icons.inventory_2_outlined,
                  message:
                      productController.infoMessage.value ??
                      'No products matched your search.',
                  actionLabel: productController.hasActiveFilter
                      ? 'Clear Filters'
                      : 'Refresh',
                  onAction: productController.hasActiveFilter
                      ? () async {
                          _searchController.clear();
                          productController.clearFilters();
                        }
                      : () async {
                          await productController.retry();
                        },
                ),
              )
            else
              SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final selectedQuantity = cartController.quantityForProduct(
                    product.id,
                  );
                  final unitLabel =
                      product.unit?.shortName ?? product.unit?.name;
                  final displayPrice = product.hasVariants == true
                      ? product.lowestVariantSellingPrice
                      : product.sellingPrice;

                  return ProductCard(
                    key: ValueKey('product-card-${product.id}'),
                    name: product.name ?? 'Unnamed product',
                    sku: product.sku ?? '-',
                    price: product.hasVariants == true
                        ? 'From ${productController.formatPrice(displayPrice)}'
                        : productController.formatPrice(displayPrice),
                    stock: product.currentStock ?? 0,
                    selectedQuantity: selectedQuantity,
                    imageUrl: product.primaryPhotoUrl,
                    unitLabel: unitLabel == null ? null : 'Unit $unitLabel',
                    categoryLabel: product.category?.name,
                    buttonLabel: 'Add',
                    showQuantityControls: product.hasVariants != true,
                    onViewDetails: () {
                      Get.toNamed(AppRoutes.productDetails, arguments: product);
                    },
                    onAdd: () => product.hasVariants == true
                        ? _openVariantPicker(
                            context,
                            product,
                            cartController,
                            productController,
                          )
                        : cartController.addProduct(product),
                    onIncrement: product.hasVariants == true
                        ? null
                        : () => cartController.incrementQuantity(
                            '${product.id}:base',
                          ),
                    onDecrement: product.hasVariants == true
                        ? null
                        : () => cartController.decrementQuantity(
                            '${product.id}:base',
                          ),
                    onQuantitySubmitted: product.hasVariants == true
                        ? null
                        : (value) => _applyProductQuantity(
                            cartController,
                            product,
                            value,
                          ),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: productController.isLoadingMore.value
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              ),
            ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CartStep extends StatelessWidget {
  const _CartStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.items.isEmpty) {
        return AppMessageState(
          icon: Icons.shopping_bag_outlined,
          message:
              'Your cart is empty. Add products before confirming the order.',
          actionLabel: 'Back to Products',
          onAction: () async =>
              controller.goToStep(CartController.productsStep),
        );
      }

      final customer = controller.selectedCustomer.value;
      final discountType = controller.discountType.value;
      final showDiscountField = discountType != null;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          if (customer != null) ...[
            _CartCustomerSummaryCard(customer: customer),
            const SizedBox(height: 20),
          ],
          Text(
            'Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in controller.items) ...[
            CartItemWidget(
              title: item.product.name ?? 'Unnamed product',
              subtitle: item.product.sku ?? '-',
              variantLabel: item.variantLabel,
              quantity: item.quantity,
              unitPrice: controller.formatCurrency(item.unitPrice),
              lineTotal: controller.formatCurrency(item.lineTotal),
              availableStock: item.availableStock,
              canIncrement: controller.canIncrementQuantity(item.lineKey),
              onIncrement: () => controller.incrementQuantity(item.lineKey),
              onDecrement: () => controller.decrementQuantity(item.lineKey),
              onQuantitySubmitted: (value) =>
                  controller.setLineQuantity(item.lineKey, value),
              onRemove: () => controller.removeItem(item.lineKey),
              warningMessage: item.isOutOfStock
                  ? 'This item is currently out of stock. Keep it only if you plan to revise the draft.'
                  : item.exceedsAvailableStock
                  ? 'Requested quantity is above available stock (${item.availableStock ?? 0}). Draft save is allowed, but confirm is blocked.'
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          _CartSectionCard(
            title: 'Discount',
            subtitle:
                'Select the discount type first, then enter a value if needed.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DiscountChip(
                      label: 'None',
                      selected: discountType == null,
                      onTap: () => controller.setDiscountType(null),
                    ),
                    _DiscountChip(
                      label: 'Amount',
                      selected: discountType == 'amount',
                      onTap: () => controller.setDiscountType('amount'),
                    ),
                    _DiscountChip(
                      label: 'Percent',
                      selected: discountType == 'percentage',
                      onTap: () => controller.setDiscountType('percentage'),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: showDiscountField
                      ? Padding(
                          key: ValueKey(discountType),
                          padding: const EdgeInsets.only(top: 14),
                          child: TextField(
                            controller: controller.discountValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}$'),
                              ),
                            ],
                            onChanged: controller.onDiscountValueChanged,
                            onEditingComplete: () {
                              controller.normalizeDiscountInputText();
                              FocusScope.of(context).unfocus();
                            },
                            decoration: InputDecoration(
                              labelText: discountType == 'percentage'
                                  ? 'Discount percent'
                                  : 'Discount amount',
                              hintText: discountType == 'percentage'
                                  ? 'Enter percentage discount'
                                  : 'Enter fixed discount amount',
                              helperText: discountType == 'percentage'
                                  ? 'Allowed range: 0.00% to 100.00%'
                                  : null,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CartSectionCard(
            title: 'Order note',
            subtitle: 'Optional delivery instructions or internal order note.',
            child: TextField(
              controller: controller.noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add an optional note',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _CartSectionCard(
            title: 'Order totals',
            child: Column(
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: controller.formatCurrency(controller.subtotal),
                ),
                const SizedBox(height: 12),
                _TotalRow(
                  label: 'Discount',
                  value: controller.formatCurrency(
                    controller.estimatedDiscountAmount,
                  ),
                ),
                const SizedBox(height: 12),
                _TotalRow(
                  label: 'Total',
                  value: controller.formatCurrency(controller.grandTotal),
                  strong: true,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _CartCustomerSummaryCard extends StatefulWidget {
  const _CartCustomerSummaryCard({required this.customer});

  final CustomerModel customer;

  @override
  State<_CartCustomerSummaryCard> createState() =>
      _CartCustomerSummaryCardState();
}

class _CartCustomerSummaryCardState extends State<_CartCustomerSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = widget.customer;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customer.name ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CartDetailRow(
                          icon: Icons.phone_outlined,
                          text: customer.phone ?? '-',
                        ),
                        if ((customer.area ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _CartDetailRow(
                            icon: Icons.location_on_outlined,
                            text: customer.area!,
                          ),
                        ],
                        if ((customer.address ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _CartDetailRow(
                            icon: Icons.map_outlined,
                            text: customer.address!,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CartSectionCard extends StatelessWidget {
  const _CartSectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  const _DiscountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _CartDetailRow extends StatelessWidget {
  const _CartDetailRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final customer = controller.selectedCustomer.value;

      return ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Text(
            'Confirm order',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (controller.hasSavedDraft) ...[
            _DraftStatusCard(controller: controller),
            const SizedBox(height: 16),
          ],
          if (controller.stockWarningSummary != null) ...[
            InlineWarningBanner(message: controller.stockWarningSummary!),
            const SizedBox(height: 16),
          ],
          if (customer != null) ...[
            _CartCustomerSummaryCard(customer: customer),
            const SizedBox(height: 16),
          ],
          _CartSectionCard(
            title: 'Items',
            child: controller.items.isEmpty
                ? Text(
                    'No products selected yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < controller.items.length;
                        index++
                      ) ...[
                        _ConfirmRow(
                          count: index + 1,
                          title:
                              controller.items[index].product.name ??
                              'Unnamed product',
                          subtitle: [
                            if ((controller.items[index].variantLabel ?? '')
                                .isNotEmpty)
                              controller.items[index].variantLabel!,
                            '${controller.items[index].quantity} x ${controller.formatCurrency(controller.items[index].unitPrice)}',
                          ].join(' • '),
                          value: controller.formatCurrency(
                            controller.items[index].lineTotal,
                          ),
                        ),
                        if (index != controller.items.length - 1) ...[
                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _CartSectionCard(
            title: 'Order summary',
            child: Column(
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: controller.formatCurrency(controller.displaySubtotal),
                ),
                const SizedBox(height: 12),
                _TotalRow(
                  label: 'Discount',
                  value: controller.formatCurrency(
                    controller.displayDiscountAmount,
                  ),
                  highlighted: true,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _TotalRow(
                    label: 'Total',
                    value: controller.formatCurrency(controller.displayGrandTotal),
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          if (controller.noteText.value.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _CartSectionCard(
              title: 'Note',
              child: Text(
                controller.noteText.value.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _DraftStatusCard extends StatelessWidget {
  const _DraftStatusCard({required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = controller.savedDraftOrder.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.save_outlined,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.hasUnsavedDraftChanges.value
                      ? 'Draft has local changes'
                      : 'Draft synced with server',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  draft?.orderNo == null
                      ? 'Save this order as a draft before final confirm.'
                      : 'Order ${draft!.orderNo} is in draft status. You can keep editing and update it before confirm.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final int count;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = strong
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : highlighted
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          )
        : theme.textTheme.bodyMedium;

    return Container(
      padding: highlighted
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: highlighted
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(value, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
