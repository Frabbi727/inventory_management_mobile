import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../data/models/customer_model.dart';
import '../controllers/customer_search_controller.dart';

class CustomerSearchPage extends StatelessWidget {
  const CustomerSearchPage({super.key});

  CustomerSearchController get controller => Get.find<CustomerSearchController>(
    tag: ControllerTags.customerSearchRoute,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Customer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller.searchTextController,
                onChanged: controller.onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(
                    () => controller.isSearching.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : controller.searchTextController.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: controller.clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.infoMessage.value == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    controller.infoMessage.value!,
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
              Expanded(
                child: Obx(() {
                  if (controller.isInitialLoading.value &&
                      controller.customers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.errorMessage.value != null &&
                      controller.customers.isEmpty) {
                    return AppMessageState(
                      icon: Icons.cloud_off_outlined,
                      message: controller.errorMessage.value!,
                      actionLabel: 'Retry',
                      onAction: controller.retry,
                    );
                  }

                  if (controller.customers.isEmpty) {
                    return AppMessageState(
                      icon: Icons.person_search_outlined,
                      message: controller.searchQuery.value.isEmpty
                          ? 'No customers available.'
                          : 'No customer matched your search.',
                      actionLabel: 'Add Customer',
                      onAction: controller.openAddCustomer,
                    );
                  }

                  return ListView(
                    controller: controller.scrollController,
                    children: [
                      if (controller.searchQuery.value.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'All customers',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      for (final customer in controller.customers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomerCard(
                            customer: customer,
                            onSelect: () => controller.selectCustomer(customer),
                          ),
                        ),
                      if (controller.isLoadingMore.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton.icon(
            onPressed: controller.openAddCustomer,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add New Customer'),
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onSelect});

  final CustomerModel customer;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customer.name ?? 'Unnamed customer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onSelect,
                  child: const Text('Select'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.phone_outlined,
                  text: customer.phone ?? '-',
                ),
                if ((customer.area ?? '').isNotEmpty)
                  _InfoPill(icon: Icons.place_outlined, text: customer.area!),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              customer.address ?? '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
