import '../../../cart_orders/data/models/order_status.dart';

enum OrderListStatusFilter {
  all(null),
  draft(OrderStatus.draft),
  confirmed(OrderStatus.confirmed);

  const OrderListStatusFilter(this.status);

  final OrderStatus? status;

  String? get apiValue => status?.apiValue;

  String get label => switch (this) {
    OrderListStatusFilter.all => 'All',
    OrderListStatusFilter.draft => 'Draft',
    OrderListStatusFilter.confirmed => 'Confirm',
  };
}
