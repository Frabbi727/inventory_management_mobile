import 'package:json_annotation/json_annotation.dart';

part 'notification_entity_model.g.dart';

@JsonSerializable()
class NotificationEntityModel {
  const NotificationEntityModel({this.type, this.id});

  final String? type;

  @JsonKey(fromJson: _toInt)
  final int? id;

  factory NotificationEntityModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationEntityModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationEntityModelToJson(this);

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
