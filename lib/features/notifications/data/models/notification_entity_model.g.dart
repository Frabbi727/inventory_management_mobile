// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_entity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationEntityModel _$NotificationEntityModelFromJson(
  Map<String, dynamic> json,
) => NotificationEntityModel(
  type: json['type'] as String?,
  id: NotificationEntityModel._toInt(json['id']),
);

Map<String, dynamic> _$NotificationEntityModelToJson(
  NotificationEntityModel instance,
) => <String, dynamic>{'type': instance.type, 'id': instance.id};
