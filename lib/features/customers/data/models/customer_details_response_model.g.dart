// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_details_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetailsResponseModel _$CustomerDetailsResponseModelFromJson(
  Map<String, dynamic> json,
) => CustomerDetailsResponseModel(
  data: json['data'] == null
      ? null
      : CustomerModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerDetailsResponseModelToJson(
  CustomerDetailsResponseModel instance,
) => <String, dynamic>{'data': instance.data?.toJson()};
