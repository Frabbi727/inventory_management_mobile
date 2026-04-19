// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_tap_payload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationTapPayloadModel _$NotificationTapPayloadModelFromJson(
  Map<String, dynamic> json,
) => NotificationTapPayloadModel(
  notificationId: NotificationTapPayloadModel._toInt(json['notification_id']),
  entityType: json['entity_type'] as String?,
  entityId: NotificationTapPayloadModel._toInt(json['entity_id']),
);

Map<String, dynamic> _$NotificationTapPayloadModelToJson(
  NotificationTapPayloadModel instance,
) => <String, dynamic>{
  'notification_id': instance.notificationId,
  'entity_type': instance.entityType,
  'entity_id': instance.entityId,
};
