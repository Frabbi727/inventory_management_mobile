import 'package:json_annotation/json_annotation.dart';

import 'inventory_dashboard_data_model.dart';

part 'inventory_dashboard_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryDashboardResponseModel {
  const InventoryDashboardResponseModel({this.success, this.data});

  final bool? success;
  final InventoryDashboardDataModel? data;

  factory InventoryDashboardResponseModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryDashboardResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryDashboardResponseModelToJson(this);
}
