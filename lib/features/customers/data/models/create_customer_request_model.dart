import 'package:json_annotation/json_annotation.dart';

part 'create_customer_request_model.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateCustomerRequestModel {
  const CreateCustomerRequestModel({
    this.name,
    this.phone,
    this.address,
    this.area,
  });

  final String? name;
  final String? phone;
  final String? address;
  final String? area;

  factory CreateCustomerRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomerRequestModelToJson(this);
}
