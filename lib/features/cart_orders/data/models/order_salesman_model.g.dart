// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_salesman_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderSalesmanModel _$OrderSalesmanModelFromJson(Map<String, dynamic> json) =>
    OrderSalesmanModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$OrderSalesmanModelToJson(OrderSalesmanModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
