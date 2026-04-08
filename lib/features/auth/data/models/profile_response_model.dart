import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'profile_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProfileResponseModel {
  const ProfileResponseModel({this.data});

  final UserModel? data;

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseModelToJson(this);
}
