// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItemModel _$NotificationItemModelFromJson(
  Map<String, dynamic> json,
) => NotificationItemModel(
  id: NotificationItemModel._toInt(json['id']),
  type: json['type'] as String?,
  title: json['title'] as String?,
  body: json['body'] as String?,
  isRead: json['is_read'] as bool?,
  readAt: json['read_at'] as String?,
  createdAt: json['created_at'] as String?,
  entity: json['entity'] == null
      ? null
      : NotificationEntityModel.fromJson(
          json['entity'] as Map<String, dynamic>,
        ),
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$NotificationItemModelToJson(
  NotificationItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'body': instance.body,
  'is_read': instance.isRead,
  'read_at': instance.readAt,
  'created_at': instance.createdAt,
  'entity': instance.entity?.toJson(),
  'data': instance.data,
};
