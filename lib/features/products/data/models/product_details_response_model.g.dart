// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_details_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDetailsResponseModel _$ProductDetailsResponseModelFromJson(
  Map<String, dynamic> json,
) => ProductDetailsResponseModel(
  data: json['data'] == null
      ? null
      : ProductModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProductDetailsResponseModelToJson(
  ProductDetailsResponseModel instance,
) => <String, dynamic>{'data': instance.data?.toJson()};
