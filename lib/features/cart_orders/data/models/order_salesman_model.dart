import 'package:json_annotation/json_annotation.dart';

part 'order_salesman_model.g.dart';

@JsonSerializable()
class OrderSalesmanModel {
  const OrderSalesmanModel({this.id, this.name});

  final int? id;
  final String? name;

  factory OrderSalesmanModel.fromJson(Map<String, dynamic> json) =>
      _$OrderSalesmanModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSalesmanModelToJson(this);
}
