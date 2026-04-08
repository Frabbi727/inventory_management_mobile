// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductUnitModel _$ProductUnitModelFromJson(Map<String, dynamic> json) =>
    ProductUnitModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      shortName: json['short_name'] as String?,
    );

Map<String, dynamic> _$ProductUnitModelToJson(ProductUnitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'short_name': instance.shortName,
    };
