import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../data/models/customer_model.dart';
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

  Future<void> _openAddCustomer() async {
    final result = await Get.toNamed(AppRoutes.addCustomer);
    if (result is CustomerModel) {
      await controller.retry();
    }
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'Customers',
              trailing: Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${controller.customers.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CustomerToolbar(
              searchController: _searchController,
              controller: controller,
              onAddCustomer: _openAddCustomer,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.isInitialLoading.value &&
                    controller.customers.isEmpty) {
                  return const _CustomerLoadingState();
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

                return Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child:
                          controller.errorMessage.value != null &&
                              controller.customers.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _InlineErrorBanner(
                                message: controller.errorMessage.value!,
                                onRetry: controller.retry,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: controller.showInlineLoader
                          ? const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(minHeight: 3),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.retry,
                        edgeOffset: 12,
                        displacement: 28,
                        child: controller.customers.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                    child: AppMessageState(
                                      icon: controller.hasActiveSearch
                                          ? Icons.search_off_outlined
                                          : Icons.groups_outlined,
                                      message:
                                          controller.infoMessage.value ??
                                          'No customers are available right now.',
                                      actionLabel: controller.hasActiveSearch
                                          ? 'Clear search'
                                          : 'Refresh',
                                      onAction: controller.hasActiveSearch
                                          ? () async {
                                              _searchController.clear();
                                              controller.clearSearch();
                                            }
                                          : controller.retry,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 96,
                                ),
                                itemCount:
                                    controller.customers.length +
                                    (controller.isLoadingMore.value ? 1 : 0),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= controller.customers.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final customer = controller.customers[index];
                                  return _CustomerCard(customer: customer);
                                },
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerToolbar extends StatelessWidget {
  const _CustomerToolbar({
    required this.searchController,
    required this.controller,
    required this.onAddCustomer,
  });

  final TextEditingController searchController;
  final CustomerSearchController controller;
  final Future<void> Function() onAddCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search customers',
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
                      : searchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            controller.clearSearch();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => Text(
                      controller.hasActiveSearch
                          ? 'Results update with your current search.'
                          : 'Pull down to refresh the latest customers.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  onPressed: onAddCustomer,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = (customer.area ?? '').trim();
    final address = (customer.address ?? '').trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name ?? 'Unnamed customer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CustomerMetaLine(
                      icon: Icons.phone_outlined,
                      text: customer.phone ?? '-',
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _CustomerMetaLine(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _CustomerMetaLine(
                        icon: Icons.map_outlined,
                        text: address,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerMetaLine extends StatelessWidget {
  const _CustomerMetaLine({
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
        Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7A271A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CustomerLoadingState extends StatelessWidget {
  const _CustomerLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _CustomerSkeletonCard(),
    );
  }
}

class _CustomerSkeletonCard extends StatelessWidget {
  const _CustomerSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SkeletonBox(size: const Size(48, 48), color: baseColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(size: const Size(132, 14), color: baseColor),
                  const SizedBox(height: 10),
                  _SkeletonBox(size: const Size(150, 12), color: baseColor),
                  const SizedBox(height: 8),
                  _SkeletonBox(size: const Size(120, 12), color: baseColor),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SkeletonBox(size: const Size(34, 34), color: baseColor),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.size, required this.color});

  final Size size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
