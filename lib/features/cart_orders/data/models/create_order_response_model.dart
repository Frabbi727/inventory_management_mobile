import 'package:json_annotation/json_annotation.dart';

import 'order_model.dart';

part 'create_order_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateOrderResponseModel {
  const CreateOrderResponseModel({this.message, this.data});

  final String? message;
  final OrderModel? data;

  factory CreateOrderResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderResponseModelToJson(this);
}
