import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'login_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LoginDataModel {
  const LoginDataModel({this.token, this.tokenType, this.user});

  final String? token;

  @JsonKey(name: 'token_type')
  final String? tokenType;

  final UserModel? user;

  factory LoginDataModel.fromJson(Map<String, dynamic> json) =>
      _$LoginDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDataModelToJson(this);
}
