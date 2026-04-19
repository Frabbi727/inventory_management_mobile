import 'package:json_annotation/json_annotation.dart';

import 'inventory_dashboard_summary_model.dart';

part 'inventory_dashboard_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryDashboardDataModel {
  const InventoryDashboardDataModel({this.summary});

  final InventoryDashboardSummaryModel? summary;

  factory InventoryDashboardDataModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryDashboardDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryDashboardDataModelToJson(this);
}
