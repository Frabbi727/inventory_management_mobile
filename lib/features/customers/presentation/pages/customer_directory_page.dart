import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../cart_orders/presentation/widgets/order_flow_widgets.dart';
import '../controllers/customer_search_controller.dart';

class CustomerDirectoryPage extends StatefulWidget {
  const CustomerDirectoryPage({super.key});

  @override
  State<CustomerDirectoryPage> createState() => _CustomerDirectoryPageState();
}

class _CustomerDirectoryPageState extends State<CustomerDirectoryPage> {
  late final CustomerSearchController controller;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerSearchController>(
      tag: ControllerTags.homeCustomerSearch,
    );
    _searchController = TextEditingController(
      text: controller.searchQuery.value,
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

    controller.loadMoreIfNeeded(_scrollController.position);
  }

  @override
  Widget build(BuildContext context) {
    if (_searchController.text != controller.searchQuery.value) {
      _searchController.value = TextEditingValue(
        text: controller.searchQuery.value,
        selection: TextSelection.collapsed(
          offset: controller.searchQuery.value.length,
        ),
      );
    }

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
            TextField(
              controller: _searchController,
              onChanged: controller.onSearchChanged,
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
                      : _searchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            controller.clearSearch();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
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
                    controller: _scrollController,
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
