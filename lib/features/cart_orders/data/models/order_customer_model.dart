import 'package:json_annotation/json_annotation.dart';

part 'order_customer_model.g.dart';

@JsonSerializable()
class OrderCustomerModel {
  const OrderCustomerModel({this.id, this.name, this.phone});

  final int? id;
  final String? name;
  final String? phone;

  factory OrderCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$OrderCustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCustomerModelToJson(this);
}
