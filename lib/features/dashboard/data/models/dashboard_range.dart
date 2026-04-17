enum DashboardRange {
  today('today'),
  thisWeek('this_week'),
  thisMonth('this_month'),
  thisYear('this_year'),
  custom('custom');

  const DashboardRange(this.apiValue);

  final String apiValue;

  static DashboardRange fromApi(String? value) {
    for (final range in values) {
      if (range.apiValue == value) {
        return range;
      }
    }
    return DashboardRange.today;
  }
}

extension DashboardRangeX on DashboardRange {
  String get label => switch (this) {
    DashboardRange.today => 'Today',
    DashboardRange.thisWeek => 'This Week',
    DashboardRange.thisMonth => 'This Month',
    DashboardRange.thisYear => 'This Year',
    DashboardRange.custom => 'Custom',
  };
}
