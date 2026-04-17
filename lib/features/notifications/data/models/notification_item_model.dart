import 'package:json_annotation/json_annotation.dart';

import 'notification_entity_model.dart';

part 'notification_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationItemModel {
  const NotificationItemModel({
    this.id,
    this.type,
    this.title,
    this.body,
    this.isRead,
    this.readAt,
    this.createdAt,
    this.entity,
    this.data,
  });

  @JsonKey(fromJson: _toInt)
  final int? id;

  final String? type;
  final String? title;
  final String? body;

  @JsonKey(name: 'is_read')
  final bool? isRead;

  @JsonKey(name: 'read_at')
  final String? readAt;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  final NotificationEntityModel? entity;
  final Map<String, dynamic>? data;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationItemModelToJson(this);

  NotificationItemModel copyWith({
    int? id,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    String? readAt,
    String? createdAt,
    NotificationEntityModel? entity,
    Map<String, dynamic>? data,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      entity: entity ?? this.entity,
      data: data ?? this.data,
    );
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
