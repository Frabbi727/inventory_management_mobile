// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerListResponseModel _$CustomerListResponseModelFromJson(
  Map<String, dynamic> json,
) => CustomerListResponseModel(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  links: json['links'] == null
      ? null
      : PaginationLinksModel.fromJson(json['links'] as Map<String, dynamic>),
  meta: json['meta'] == null
      ? null
      : PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerListResponseModelToJson(
  CustomerListResponseModel instance,
) => <String, dynamic>{
  'data': instance.data?.map((e) => e.toJson()).toList(),
  'links': instance.links?.toJson(),
  'meta': instance.meta?.toJson(),
};
