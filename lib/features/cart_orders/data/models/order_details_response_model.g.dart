// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_details_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetailsResponseModel _$OrderDetailsResponseModelFromJson(
  Map<String, dynamic> json,
) => OrderDetailsResponseModel(
  data: json['data'] == null
      ? null
      : OrderModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderDetailsResponseModelToJson(
  OrderDetailsResponseModel instance,
) => <String, dynamic>{'data': instance.data?.toJson()};
