// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salesman_dashboard_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesmanDashboardResponseModel _$SalesmanDashboardResponseModelFromJson(
  Map<String, dynamic> json,
) => SalesmanDashboardResponseModel(
  success: json['success'] as bool?,
  data: json['data'] == null
      ? null
      : SalesmanDashboardDataModel.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SalesmanDashboardResponseModelToJson(
  SalesmanDashboardResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data?.toJson(),
};
