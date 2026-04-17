import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:b2b_inventory_management/core/network/api_client.dart';
import 'package:b2b_inventory_management/core/storage/token_storage.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/dashboard_filters_model.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/dashboard_order_preview_model.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/dashboard_range.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/salesman_dashboard_data_model.dart';
import 'package:b2b_inventory_management/features/dashboard/data/models/salesman_dashboard_response_model.dart';
import 'package:b2b_inventory_management/features/dashboard/data/repositories/salesman_dashboard_repository.dart';
import 'package:b2b_inventory_management/features/dashboard/presentation/controllers/home_dashboard_controller.dart';

class FakeSalesmanDashboardRepository extends SalesmanDashboardRepository {
  FakeSalesmanDashboardRepository()
    : super(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final List<(DashboardRange range, DateTime? startDate, DateTime? endDate)>
  calls = [];

  @override
  Future<SalesmanDashboardResponseModel> fetchDashboard({
    required DashboardRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    calls.add((range, startDate, endDate));
    return SalesmanDashboardResponseModel(
      success: true,
      data: SalesmanDashboardDataModel(
        filters: DashboardFiltersModel(
          range: range,
          startDate: '2026-04-17',
          endDate: '2026-04-17',
        ),
        summary: const DashboardSummaryModel(
          salesAmount: 850,
          totalOrdersCount: 5,
          draftOrdersCount: 2,
          confirmedOrdersCount: 3,
          overdueDeliveriesCount: 1,
        ),
        nextDueOrders: const [
          DashboardOrderPreviewModel(orderNo: 'ORD-1', grandTotal: 200),
        ],
        recentOrders: const [
          DashboardOrderPreviewModel(orderNo: 'ORD-2', grandTotal: 300),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensureLoaded uses today on first load', () async {
    final repository = FakeSalesmanDashboardRepository();
    final controller = HomeDashboardController(dashboardRepository: repository);

    await controller.ensureLoaded();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.$1, DashboardRange.today);
    expect(controller.selectedRange.value, DashboardRange.today);
    expect(controller.summary.value?.totalOrdersCount, equals(5));
  });

  test('custom range without both dates does not fetch', () async {
    final repository = FakeSalesmanDashboardRepository();
    final controller = HomeDashboardController(dashboardRepository: repository);

    await controller.applyRange(DashboardRange.custom);

    expect(repository.calls, isEmpty);
    expect(
      controller.infoMessage.value,
      equals('Choose both start and end dates.'),
    );
  });

  test('onTabActivated refreshes current range', () async {
    final repository = FakeSalesmanDashboardRepository();
    final controller = HomeDashboardController(dashboardRepository: repository);

    await controller.applyRange(DashboardRange.thisMonth);
    await controller.onTabActivated();

    expect(repository.calls, hasLength(2));
    expect(repository.calls.first.$1, DashboardRange.thisMonth);
    expect(repository.calls.last.$1, DashboardRange.thisMonth);
  });
}
