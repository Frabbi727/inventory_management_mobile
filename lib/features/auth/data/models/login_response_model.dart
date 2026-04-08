import 'package:json_annotation/json_annotation.dart';

import 'login_data_model.dart';

part 'login_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class LoginResponseModel {
  const LoginResponseModel({this.message, this.data});

  final String? message;
  final LoginDataModel? data;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}
