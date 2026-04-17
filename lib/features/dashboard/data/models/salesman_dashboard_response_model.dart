import 'package:json_annotation/json_annotation.dart';

import 'salesman_dashboard_data_model.dart';

part 'salesman_dashboard_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SalesmanDashboardResponseModel {
  const SalesmanDashboardResponseModel({this.success, this.data});

  final bool? success;
  final SalesmanDashboardDataModel? data;

  factory SalesmanDashboardResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SalesmanDashboardResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SalesmanDashboardResponseModelToJson(this);
}
