// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_filters_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardFiltersModel _$DashboardFiltersModelFromJson(
  Map<String, dynamic> json,
) => DashboardFiltersModel(
  range: json['range'] == null
      ? DashboardRange.today
      : DashboardFiltersModel._rangeFromJson(json['range'] as String?),
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
);

Map<String, dynamic> _$DashboardFiltersModelToJson(
  DashboardFiltersModel instance,
) => <String, dynamic>{
  'range': DashboardFiltersModel._rangeToJson(instance.range),
  'start_date': instance.startDate,
  'end_date': instance.endDate,
};
