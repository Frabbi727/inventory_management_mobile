import 'package:json_annotation/json_annotation.dart';

import 'order_model.dart';

part 'order_details_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderDetailsResponseModel {
  const OrderDetailsResponseModel({this.data});

  final OrderModel? data;

  factory OrderDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailsResponseModelToJson(this);
}
