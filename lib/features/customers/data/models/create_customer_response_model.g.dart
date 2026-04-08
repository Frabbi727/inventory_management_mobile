// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_customer_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCustomerResponseModel _$CreateCustomerResponseModelFromJson(
  Map<String, dynamic> json,
) => CreateCustomerResponseModel(
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : CustomerModel.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateCustomerResponseModelToJson(
  CreateCustomerResponseModel instance,
) => <String, dynamic>{
  'message': instance.message,
  'data': instance.data?.toJson(),
};
