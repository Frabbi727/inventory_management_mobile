// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummaryModel _$DashboardSummaryModelFromJson(
  Map<String, dynamic> json,
) => DashboardSummaryModel(
  salesAmount: json['sales_amount'] as num?,
  totalOrdersCount: (json['total_orders_count'] as num?)?.toInt(),
  draftOrdersCount: (json['draft_orders_count'] as num?)?.toInt(),
  confirmedOrdersCount: (json['confirmed_orders_count'] as num?)?.toInt(),
  overdueDeliveriesCount: (json['overdue_deliveries_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$DashboardSummaryModelToJson(
  DashboardSummaryModel instance,
) => <String, dynamic>{
  'sales_amount': instance.salesAmount,
  'total_orders_count': instance.totalOrdersCount,
  'draft_orders_count': instance.draftOrdersCount,
  'confirmed_orders_count': instance.confirmedOrdersCount,
  'overdue_deliveries_count': instance.overdueDeliveriesCount,
};
