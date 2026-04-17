import 'package:json_annotation/json_annotation.dart';

import 'dashboard_range.dart';

part 'dashboard_filters_model.g.dart';

@JsonSerializable()
class DashboardFiltersModel {
  const DashboardFiltersModel({
    this.range = DashboardRange.today,
    this.startDate,
    this.endDate,
  });

  @JsonKey(fromJson: _rangeFromJson, toJson: _rangeToJson)
  final DashboardRange range;

  @JsonKey(name: 'start_date')
  final String? startDate;

  @JsonKey(name: 'end_date')
  final String? endDate;

  factory DashboardFiltersModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardFiltersModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardFiltersModelToJson(this);

  static DashboardRange _rangeFromJson(String? value) =>
      DashboardRange.fromApi(value);

  static String _rangeToJson(DashboardRange value) => value.apiValue;
}
