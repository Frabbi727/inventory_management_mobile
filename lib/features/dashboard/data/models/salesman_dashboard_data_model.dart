import 'package:json_annotation/json_annotation.dart';

import 'dashboard_filters_model.dart';
import 'dashboard_order_preview_model.dart';
import 'dashboard_summary_model.dart';

part 'salesman_dashboard_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SalesmanDashboardDataModel {
  const SalesmanDashboardDataModel({
    this.filters,
    this.summary,
    this.nextDueOrders,
    this.recentOrders,
  });

  final DashboardFiltersModel? filters;
  final DashboardSummaryModel? summary;

  @JsonKey(name: 'next_due_orders')
  final List<DashboardOrderPreviewModel>? nextDueOrders;

  @JsonKey(name: 'recent_orders')
  final List<DashboardOrderPreviewModel>? recentOrders;

  factory SalesmanDashboardDataModel.fromJson(Map<String, dynamic> json) =>
      _$SalesmanDashboardDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalesmanDashboardDataModelToJson(this);
}
