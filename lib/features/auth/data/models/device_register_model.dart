import 'package:json_annotation/json_annotation.dart';

part 'device_register_model.g.dart';

@JsonSerializable(includeIfNull: false)
class DeviceRegisterModel {
  @JsonKey(name: 'device_token')
  final String? deviceToken;

  @JsonKey(name: 'platform')
  final String? platform;

  @JsonKey(name: 'device_name')
  final String? deviceName;

  DeviceRegisterModel({
    this.deviceToken,
    this.platform,
    this.deviceName,
  });

  factory DeviceRegisterModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegisterModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRegisterModelToJson(this);
}