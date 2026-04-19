// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dashboard_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryDashboardResponseModel _$InventoryDashboardResponseModelFromJson(
  Map<String, dynamic> json,
) => InventoryDashboardResponseModel(
  success: json['success'] as bool?,
  data: json['data'] == null
      ? null
      : InventoryDashboardDataModel.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$InventoryDashboardResponseModelToJson(
  InventoryDashboardResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data?.toJson(),
};
