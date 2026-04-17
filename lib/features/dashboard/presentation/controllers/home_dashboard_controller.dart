import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/controllers/home_controller.dart';
import '../../../invoice/presentation/models/order_list_status_filter.dart';
import '../../data/models/dashboard_filters_model.dart';
import '../../data/models/dashboard_order_preview_model.dart';
import '../../data/models/dashboard_range.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/salesman_dashboard_repository.dart';

class HomeDashboardController extends GetxController {
  HomeDashboardController({
    required SalesmanDashboardRepository dashboardRepository,
  }) : _dashboardRepository = dashboardRepository;

  final SalesmanDashboardRepository _dashboardRepository;

  final isInitialLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();
  final selectedRange = DashboardRange.today.obs;
  final customStartDate = Rxn<DateTime>();
  final customEndDate = Rxn<DateTime>();
  final appliedFilters = Rxn<DashboardFiltersModel>();
  final summary = Rxn<DashboardSummaryModel>();
  final nextDueOrders = <DashboardOrderPreviewModel>[].obs;
  final recentOrders = <DashboardOrderPreviewModel>[].obs;

  bool _hasLoadedOnce = false;
  int _requestGeneration = 0;
  bool _pendingReset = false;

  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get showInlineLoader =>
      isRefreshing.value &&
      (summary.value != null ||
          nextDueOrders.isNotEmpty ||
          recentOrders.isNotEmpty);

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (forceRefresh || !_hasLoadedOnce) {
      await fetchDashboard(reset: true);
    }
  }

  Future<void> onTabActivated() => fetchDashboard(reset: true);

  Future<void> retry() => fetchDashboard(reset: true);

  @override
  Future<void> refresh() => fetchDashboard(reset: true);

  Future<void> applyRange(
    DashboardRange range, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    selectedRange.value = range;
    if (range == DashboardRange.custom) {
      customStartDate.value = startDate;
      customEndDate.value = endDate;
      if (startDate == null || endDate == null) {
        infoMessage.value = 'Choose both start and end dates.';
        return;
      }
    } else {
      customStartDate.value = null;
      customEndDate.value = null;
    }

    infoMessage.value = null;
    await fetchDashboard(reset: true);
  }

  Future<void> fetchDashboard({required bool reset}) async {
    final hasExistingData =
        summary.value != null ||
        nextDueOrders.isNotEmpty ||
        recentOrders.isNotEmpty;

    if (selectedRange.value == DashboardRange.custom &&
        (customStartDate.value == null || customEndDate.value == null)) {
      infoMessage.value = 'Choose both start and end dates.';
      return;
    }

    if (reset) {
      if (isInitialLoading.value || isRefreshing.value) {
        _pendingReset = true;
        return;
      }
      _pendingReset = false;
      isInitialLoading.value = !hasExistingData;
      isRefreshing.value = hasExistingData;
      errorMessage.value = null;
      _requestGeneration++;
    }

    final requestGeneration = _requestGeneration;

    try {
      final response = await _dashboardRepository.fetchDashboard(
        range: selectedRange.value,
        startDate: customStartDate.value,
        endDate: customEndDate.value,
      );

      if (requestGeneration != _requestGeneration) {
        return;
      }

      final data = response.data;
      summary.value = data?.summary;
      nextDueOrders.assignAll(data?.nextDueOrders ?? const []);
      recentOrders.assignAll(data?.recentOrders ?? const []);
      appliedFilters.value = data?.filters;
      if (data?.filters != null) {
        selectedRange.value = data!.filters!.range;
      }
      _hasLoadedOnce = true;

      if (summary.value == null &&
          nextDueOrders.isEmpty &&
          recentOrders.isEmpty) {
        infoMessage.value = 'No dashboard data is available right now.';
      } else {
        infoMessage.value = null;
      }
    } on ApiException catch (error) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = error.message;
      if (!hasExistingData) {
        summary.value = null;
        nextDueOrders.clear();
        recentOrders.clear();
      }
    } catch (_) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      errorMessage.value = 'Unable to load the dashboard right now.';
      if (!hasExistingData) {
        summary.value = null;
        nextDueOrders.clear();
        recentOrders.clear();
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        isInitialLoading.value = false;
        isRefreshing.value = false;
        if (_pendingReset) {
          _pendingReset = false;
          unawaited(fetchDashboard(reset: true));
        }
      }
    }
  }

  Future<void> openOrderDetails(DashboardOrderPreviewModel order) async {
    if (order.id == null) {
      return;
    }
    await Get.toNamed(AppRoutes.orderDetails, arguments: order.id);
  }

  String formatCurrency(num? value) {
    if (value == null) {
      return '৳0';
    }
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }
    return '৳${value.toStringAsFixed(2)}';
  }

  String formatDate(String? value) {
    final date = _tryParseDate(value);
    if (date == null) {
      return '-';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) {
      return value;
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute';
  }

  Future<DateTimeRange?> pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange =
        customStartDate.value != null && customEndDate.value != null
        ? DateTimeRange(
            start: customStartDate.value!,
            end: customEndDate.value!,
          )
        : DateTimeRange(start: now, end: now);

    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.split('T').first);
  }

  Future<void> openSummaryMetric(String metricKey) async {
    final filters = appliedFilters.value;
    final startDate = _tryParseDate(filters?.startDate);
    final endDate = _tryParseDate(filters?.endDate);

    switch (metricKey) {
      case 'sales_amount':
        await _openOrders(
          statusFilter: OrderListStatusFilter.confirmed,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case 'total_orders_count':
        await _openOrders(
          statusFilter: OrderListStatusFilter.all,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case 'draft_orders_count':
        await _openOrders(
          statusFilter: OrderListStatusFilter.draft,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case 'confirmed_orders_count':
        await _openOrders(
          statusFilter: OrderListStatusFilter.confirmed,
          startDate: startDate,
          endDate: endDate,
        );
        break;
      case 'overdue_deliveries_count':
        await _openOrders(
          statusFilter: OrderListStatusFilter.all,
          startDate: startDate,
          endDate: endDate,
          deliveryState: 'overdue',
        );
        break;
    }
  }

  Future<void> _openOrders({
    required OrderListStatusFilter statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? deliveryState,
  }) async {
    final homeController = Get.find<HomeController>();
    await homeController.openOrdersTab(
      statusFilter: statusFilter,
      startDate: startDate,
      endDate: endDate,
      deliveryState: deliveryState,
    );
  }
}
