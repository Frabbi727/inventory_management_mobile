// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderListResponseModel _$OrderListResponseModelFromJson(
  Map<String, dynamic> json,
) => OrderListResponseModel(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  links: json['links'] == null
      ? null
      : PaginationLinksModel.fromJson(json['links'] as Map<String, dynamic>),
  meta: json['meta'] == null
      ? null
      : PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderListResponseModelToJson(
  OrderListResponseModel instance,
) => <String, dynamic>{
  'data': instance.data?.map((e) => e.toJson()).toList(),
  'links': instance.links?.toJson(),
  'meta': instance.meta?.toJson(),
};
