// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salesman_dashboard_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesmanDashboardDataModel _$SalesmanDashboardDataModelFromJson(
  Map<String, dynamic> json,
) => SalesmanDashboardDataModel(
  filters: json['filters'] == null
      ? null
      : DashboardFiltersModel.fromJson(json['filters'] as Map<String, dynamic>),
  summary: json['summary'] == null
      ? null
      : DashboardSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
  nextDueOrders: (json['next_due_orders'] as List<dynamic>?)
      ?.map(
        (e) => DashboardOrderPreviewModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  recentOrders: (json['recent_orders'] as List<dynamic>?)
      ?.map(
        (e) => DashboardOrderPreviewModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$SalesmanDashboardDataModelToJson(
  SalesmanDashboardDataModel instance,
) => <String, dynamic>{
  'filters': instance.filters?.toJson(),
  'summary': instance.summary?.toJson(),
  'next_due_orders': instance.nextDueOrders?.map((e) => e.toJson()).toList(),
  'recent_orders': instance.recentOrders?.map((e) => e.toJson()).toList(),
};
