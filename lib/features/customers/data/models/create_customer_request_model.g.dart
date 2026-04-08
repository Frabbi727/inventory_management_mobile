// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_customer_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCustomerRequestModel _$CreateCustomerRequestModelFromJson(
  Map<String, dynamic> json,
) => CreateCustomerRequestModel(
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  area: json['area'] as String?,
);

Map<String, dynamic> _$CreateCustomerRequestModelToJson(
  CreateCustomerRequestModel instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'phone': ?instance.phone,
  'address': ?instance.address,
  'area': ?instance.area,
};
