import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/presentation/widgets/order_flow_widgets.dart';
import '../controllers/customer_search_controller.dart';

class CustomerDirectoryPage extends GetView<CustomerSearchController> {
  const CustomerDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Customers',
              subtitle:
                  'Search customers by name or phone and add new accounts when needed.',
            ),
            const SizedBox(height: 16),
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
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: controller.openAddCustomer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Customer'),
              ),
            ),
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
                    message:
                        controller.infoMessage.value ??
                        'No customers are available right now.',
                    actionLabel: 'Refresh',
                    onAction: controller.retry,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.retry,
                  child: ListView.separated(
                    controller: controller.scrollController,
                    itemCount:
                        controller.customers.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= controller.customers.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final customer = controller.customers[index];
                      return CustomerTile(
                        customerName: customer.name ?? 'Unnamed customer',
                        phone: customer.phone ?? '-',
                        address: customer.address ?? '-',
                        area: customer.area,
                        trailing: const Icon(Icons.chevron_right),
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
}
