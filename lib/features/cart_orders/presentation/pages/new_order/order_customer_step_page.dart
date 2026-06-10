import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../shared/widgets/app_message_state.dart';
import '../../../../customers/data/models/customer_model.dart';
import '../../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_customer_step_controller.dart';
import '../../widgets/order_flow_widgets.dart';

class OrderCustomerStepPage extends GetView<OrderCustomerStepController> {
  const OrderCustomerStepPage({super.key});

  CustomerSearchController get searchController =>
      controller.customerSearchController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cartController = controller.cartController;
      final customers = controller.customers;
      // Read inside the Obx body so selection changes trigger a rebuild —
      // sliver itemBuilders run during layout, outside Obx's reactive scope.
      final selectedCustomerId = cartController.selectedCustomer.value?.id;

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
                  if (searchController.errorMessage.value != null &&
                      customers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InlineWarningBanner(
                      message: searchController.errorMessage.value!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SectionTitle(
                    title: 'Customer',
                    required: true,
                    trailing: customers.isEmpty
                        ? null
                        : '${customers.length} found',
                  ),
                  const SizedBox(height: 10),
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
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final isSelected =
                      customer.id != null && selectedCustomerId == customer.id;

                  return _CustomerOptionRow(
                    customer: customer,
                    selected: isSelected,
                    onTap: () =>
                        controller.selectCustomer(isSelected ? null : customer),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: searchController.isLoadingMore.value
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const _SectionTitle(title: 'Schedule'),
                  const SizedBox(height: 10),
                  _ScheduleCard(cartController: cartController),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.required = false, this.trailing});

  final String title;
  final bool required;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _CustomerOptionRow extends StatelessWidget {
  const _CustomerOptionRow({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  final CustomerModel customer;
  final bool selected;
  final VoidCallback onTap;

  static const _avatarColors = <Color>[
    Color(0xFF1A237E),
    Color(0xFF00897B),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFFEF6C00),
    Color(0xFF283593),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = customer.name ?? 'Unnamed customer';
    final subtitleParts = <String>[
      if ((customer.area ?? '').isNotEmpty) customer.area!,
      if ((customer.phone ?? '').isNotEmpty) customer.phone!,
    ];
    final avatarColor = _avatarColors[name.hashCode % _avatarColors.length];

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: avatarColor,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: 2,
        ),
      ),
      child: selected
          ? const Center(
              child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
            )
          : null,
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.cartController});

  final CartController cartController;

  static DateTime _dayFromNow(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  static const _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')} ${_months[value.month - 1]}';

  Future<void> _pickCustomDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _dayFromNow(0);
    final tomorrow = _dayFromNow(1);
    final inTwoDays = _dayFromNow(2);

    return Obx(() {
      final orderDate = cartController.selectedOrderDate.value;
      final deliveryAt = cartController.selectedIntendedDeliveryAt.value;
      final orderIsCustom =
          !_isSameDay(orderDate, today) && !_isSameDay(orderDate, tomorrow);
      final deliveryIsCustomDay =
          deliveryAt != null &&
          !_isSameDay(deliveryAt, today) &&
          !_isSameDay(deliveryAt, tomorrow) &&
          !_isSameDay(deliveryAt, inTwoDays);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(label: 'Order date', required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickChip(
                  label: 'Today',
                  selected: _isSameDay(orderDate, today),
                  onTap: () => cartController.setOrderDate(today),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: 'Tomorrow',
                  selected: _isSameDay(orderDate, tomorrow),
                  onTap: () => cartController.setOrderDate(tomorrow),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: orderIsCustom ? _shortDate(orderDate) : 'Pick date',
                  selected: orderIsCustom,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickCustomDate(
                    context,
                    initial: orderDate,
                    onPicked: cartController.setOrderDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 14),
            _FieldLabel(label: 'Delivery day', required: true),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickChip(
                  label: 'Today',
                  selected: _isSameDay(deliveryAt, today),
                  onTap: () => cartController.setDeliveryDay(today),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: 'Tomorrow',
                  selected: _isSameDay(deliveryAt, tomorrow),
                  onTap: () => cartController.setDeliveryDay(tomorrow),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: 'In 2 days',
                  selected: _isSameDay(deliveryAt, inTwoDays),
                  onTap: () => cartController.setDeliveryDay(inTwoDays),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: deliveryIsCustomDay
                      ? _shortDate(deliveryAt)
                      : 'Pick',
                  selected: deliveryIsCustomDay,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickCustomDate(
                    context,
                    initial: deliveryAt ?? tomorrow,
                    onPicked: cartController.setDeliveryDay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldLabel(label: 'Delivery time'),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickChip(
                  label: 'Morning',
                  selected: deliveryAt?.hour == 10 && deliveryAt?.minute == 0,
                  onTap: () => cartController.setDeliveryTime(10),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: 'Afternoon',
                  selected: deliveryAt?.hour == 14 && deliveryAt?.minute == 0,
                  onTap: () => cartController.setDeliveryTime(14),
                ),
                const SizedBox(width: 6),
                _QuickChip(
                  label: 'Evening',
                  selected: deliveryAt?.hour == 18 && deliveryAt?.minute == 0,
                  onTap: () => cartController.setDeliveryTime(18),
                ),
              ],
            ),
            if (deliveryAt != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7DBFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Scheduled for ',
                          children: [
                            TextSpan(
                              text:
                                  '${_shortDate(deliveryAt)}, '
                                  '${deliveryAt.hour.toString().padLeft(2, '0')}:'
                                  '${deliveryAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search customer by name or phone',
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onAddCustomer,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(Icons.person_add_alt_1),
          ),
        ),
      ],
    );
  }
}
