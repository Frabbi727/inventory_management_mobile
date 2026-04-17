import 'package:json_annotation/json_annotation.dart';

part 'dashboard_summary_model.g.dart';

@JsonSerializable()
class DashboardSummaryModel {
  const DashboardSummaryModel({
    this.salesAmount,
    this.totalOrdersCount,
    this.draftOrdersCount,
    this.confirmedOrdersCount,
    this.overdueDeliveriesCount,
  });

  @JsonKey(name: 'sales_amount')
  final num? salesAmount;

  @JsonKey(name: 'total_orders_count')
  final int? totalOrdersCount;

  @JsonKey(name: 'draft_orders_count')
  final int? draftOrdersCount;

  @JsonKey(name: 'confirmed_orders_count')
  final int? confirmedOrdersCount;

  @JsonKey(name: 'overdue_deliveries_count')
  final int? overdueDeliveriesCount;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardSummaryModelToJson(this);
}
