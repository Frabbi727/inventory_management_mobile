import 'package:json_annotation/json_annotation.dart';

part 'login_request_model.g.dart';

@JsonSerializable(includeIfNull: false)
class LoginRequestModel {
  const LoginRequestModel({this.login, this.password, this.deviceName});

  final String? login;
  final String? password;

  @JsonKey(name: 'device_name')
  final String? deviceName;

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);
}
