import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/customer_search_controller.dart';

class CustomerSearchPage extends GetView<CustomerSearchController> {
  const CustomerSearchPage({super.key});

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
              SearchBar(
                controller: controller.searchController,
                hintText: 'Search by name or phone',
                leading: const Icon(Icons.search),
                onChanged: controller.onSearchChanged,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
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
                    return _MessageState(
                      icon: Icons.cloud_off_outlined,
                      message: controller.errorMessage.value!,
                      actionLabel: 'Retry',
                      onAction: controller.retry,
                    );
                  }

                  if (controller.customers.isEmpty) {
                    return _MessageState(
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
                      for (final customer in controller.customers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomerCard(
                            name: customer.name ?? 'Unnamed customer',
                            phone: customer.phone ?? '-',
                            address: customer.address ?? '-',
                            area: customer.area,
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
  const _CustomerCard({
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    required this.onSelect,
  });

  final String name;
  final String phone;
  final String address;
  final String? area;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            Text(phone),
            const SizedBox(height: 4),
            Text(address),
            if ((area ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(area!),
            ],
          ],
        ),
      ),
    );
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
  final VoidCallback onAction;

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
