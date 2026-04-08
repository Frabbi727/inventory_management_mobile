import 'package:json_annotation/json_annotation.dart';

import 'customer_model.dart';

part 'customer_details_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomerDetailsResponseModel {
  const CustomerDetailsResponseModel({this.data});

  final CustomerModel? data;

  factory CustomerDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailsResponseModelToJson(this);
}
