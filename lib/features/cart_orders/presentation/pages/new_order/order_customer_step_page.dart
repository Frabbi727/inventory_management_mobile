import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../shared/widgets/app_message_state.dart';
import '../../../../customers/data/models/customer_model.dart';
import '../../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../controllers/order_customer_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';

class OrderCustomerStepPage extends GetView<OrderCustomerStepController> {
  const OrderCustomerStepPage({super.key});

  CustomerSearchController get searchController =>
      controller.customerSearchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final cartController = controller.cartController;
      final selectedCustomer = cartController.selectedCustomer.value;
      final customers = controller.customers;

      controller.syncSearchField();

      final showInitialLoader =
          searchController.isInitialLoading.value && customers.isEmpty;
      final showErrorState = searchController.hasErrorState;
      final showEmptyState = searchController.hasEmptyState;

      return RefreshIndicator(
        onRefresh: searchController.retry,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchActionPanel(
                    searchController: controller.searchController,
                    isSearching: searchController.isSearching.value,
                    onChanged: controller.onSearchChanged,
                    onClear: controller.clearSearch,
                    onAddCustomer: controller.openAddCustomer,
                  ),
                  if (selectedCustomer != null) ...[
                    const SizedBox(height: 16),
                    _SelectedCustomerBanner(
                      customer: selectedCustomer,
                      onClear: () => controller.selectCustomer(null),
                    ),
                  ],
                  if (searchController.errorMessage.value != null &&
                      customers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InlineWarningBanner(
                      message: searchController.errorMessage.value!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          searchController.hasActiveSearch
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
                  message: searchController.errorMessage.value!,
                  actionLabel: 'Retry',
                  onAction: searchController.retry,
                ),
              )
            else if (showEmptyState)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppMessageState(
                  icon: Icons.person_search_outlined,
                  message:
                      searchController.infoMessage.value ??
                      'No customers matched your search.',
                  actionLabel: searchController.hasActiveSearch
                      ? 'Clear Search'
                      : 'Refresh',
                  onAction: searchController.hasActiveSearch
                      ? () async => controller.clearSearch()
                      : () async => searchController.retry(),
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
                    onTap: () => controller.selectCustomer(customer),
                    trailing: FilledButton(
                      onPressed: () => controller.selectCustomer(customer),
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
                child: searchController.isLoadingMore.value
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
