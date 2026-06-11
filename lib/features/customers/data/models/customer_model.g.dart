// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerModel _$CustomerModelFromJson(Map<String, dynamic> json) =>
    CustomerModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      area: json['area'] as String?,
      createdBy: json['created_by'] == null
          ? null
          : CustomerCreatedByModel.fromJson(
              json['created_by'] as Map<String, dynamic>,
            ),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$CustomerModelToJson(CustomerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
      'area': instance.area,
      'created_by': instance.createdBy?.toJson(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
