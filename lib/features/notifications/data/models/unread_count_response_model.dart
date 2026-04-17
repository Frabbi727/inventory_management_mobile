import 'package:json_annotation/json_annotation.dart';

part 'unread_count_response_model.g.dart';

@JsonSerializable()
class UnreadCountResponseModel {
  const UnreadCountResponseModel({this.count});

  @JsonKey(fromJson: _toInt)
  final int? count;

  factory UnreadCountResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadCountResponseModelToJson(this);

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
