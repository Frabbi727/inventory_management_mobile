import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'notification_tap_payload_model.g.dart';

@JsonSerializable()
class NotificationTapPayloadModel {
  const NotificationTapPayloadModel({
    this.notificationId,
    this.entityType,
    this.entityId,
  });

  @JsonKey(name: 'notification_id', fromJson: _toInt)
  final int? notificationId;

  @JsonKey(name: 'entity_type')
  final String? entityType;

  @JsonKey(name: 'entity_id', fromJson: _toInt)
  final int? entityId;

  factory NotificationTapPayloadModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationTapPayloadModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTapPayloadModelToJson(this);

  factory NotificationTapPayloadModel.fromMessageData(
    Map<String, dynamic> data,
  ) {
    return NotificationTapPayloadModel.fromJson(Map<String, dynamic>.from(data));
  }

  static NotificationTapPayloadModel? fromPayloadString(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return NotificationTapPayloadModel.fromJson(decoded);
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
