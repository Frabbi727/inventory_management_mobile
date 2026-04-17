enum OrderStatus {
  draft('draft'),
  confirmed('confirmed'),
  cancelled('cancelled');

  const OrderStatus(this.apiValue);

  final String apiValue;

  static OrderStatus? fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) {
        return status;
      }
    }
    return null;
  }
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.draft => 'Draft',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.cancelled => 'Cancelled',
  };
}
