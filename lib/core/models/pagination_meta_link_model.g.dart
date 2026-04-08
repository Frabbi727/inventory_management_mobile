// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_meta_link_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationMetaLinkModel _$PaginationMetaLinkModelFromJson(
  Map<String, dynamic> json,
) => PaginationMetaLinkModel(
  url: json['url'] as String?,
  label: json['label'] as String?,
  page: (json['page'] as num?)?.toInt(),
  active: json['active'] as bool?,
);

Map<String, dynamic> _$PaginationMetaLinkModelToJson(
  PaginationMetaLinkModel instance,
) => <String, dynamic>{
  'url': instance.url,
  'label': instance.label,
  'page': instance.page,
  'active': instance.active,
};
