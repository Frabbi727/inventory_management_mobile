import 'package:json_annotation/json_annotation.dart';

part 'dashboard_customer_model.g.dart';

@JsonSerializable()
class DashboardCustomerModel {
  const DashboardCustomerModel({this.id, this.name, this.phone});

  final int? id;
  final String? name;
  final String? phone;

  factory DashboardCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardCustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardCustomerModelToJson(this);
}
