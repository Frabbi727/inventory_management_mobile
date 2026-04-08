// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCustomerModel _$OrderCustomerModelFromJson(Map<String, dynamic> json) =>
    OrderCustomerModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$OrderCustomerModelToJson(OrderCustomerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
    };
