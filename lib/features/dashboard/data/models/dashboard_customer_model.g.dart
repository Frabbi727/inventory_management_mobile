// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardCustomerModel _$DashboardCustomerModelFromJson(
  Map<String, dynamic> json,
) => DashboardCustomerModel(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$DashboardCustomerModelToJson(
  DashboardCustomerModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
};
