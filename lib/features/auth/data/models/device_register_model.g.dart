// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_register_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegisterModel _$DeviceRegisterModelFromJson(Map<String, dynamic> json) =>
    DeviceRegisterModel(
      deviceToken: json['device_token'] as String?,
      platform: json['platform'] as String?,
      deviceName: json['device_name'] as String?,
    );

Map<String, dynamic> _$DeviceRegisterModelToJson(
  DeviceRegisterModel instance,
) => <String, dynamic>{
  'device_token': ?instance.deviceToken,
  'platform': ?instance.platform,
  'device_name': ?instance.deviceName,
};
