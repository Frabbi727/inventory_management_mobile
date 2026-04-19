// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dashboard_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryDashboardDataModel _$InventoryDashboardDataModelFromJson(
  Map<String, dynamic> json,
) => InventoryDashboardDataModel(
  summary: json['summary'] == null
      ? null
      : InventoryDashboardSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$InventoryDashboardDataModelToJson(
  InventoryDashboardDataModel instance,
) => <String, dynamic>{'summary': instance.summary?.toJson()};
