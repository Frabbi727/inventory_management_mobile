// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationListResponseModel _$NotificationListResponseModelFromJson(
  Map<String, dynamic> json,
) => NotificationListResponseModel(
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  links: json['links'] == null
      ? null
      : PaginationLinksModel.fromJson(json['links'] as Map<String, dynamic>),
  meta: json['meta'] == null
      ? null
      : PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NotificationListResponseModelToJson(
  NotificationListResponseModel instance,
) => <String, dynamic>{
  'data': instance.data?.map((e) => e.toJson()).toList(),
  'links': instance.links?.toJson(),
  'meta': instance.meta?.toJson(),
};
