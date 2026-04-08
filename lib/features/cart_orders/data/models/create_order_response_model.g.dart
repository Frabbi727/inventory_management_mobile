// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_order_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrderResponseModel _$CreateOrderResponseModelFromJson(
  Map<String, dynamic> json,
) => CreateOrderResponseModel(
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : OrderModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateOrderResponseModelToJson(
  CreateOrderResponseModel instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data?.toJson(),
};
