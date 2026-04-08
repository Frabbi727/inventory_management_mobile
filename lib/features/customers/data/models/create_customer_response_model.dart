import 'package:json_annotation/json_annotation.dart';

import 'customer_model.dart';

part 'create_customer_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateCustomerResponseModel {
  const CreateCustomerResponseModel({this.message, this.data});

  final String? message;
  final CustomerModel? data;

  factory CreateCustomerResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomerResponseModelToJson(this);
}
