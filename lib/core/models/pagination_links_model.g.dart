// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_links_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationLinksModel _$PaginationLinksModelFromJson(
  Map<String, dynamic> json,
) => PaginationLinksModel(
  first: json['first'] as String?,
  last: json['last'] as String?,
  prev: json['prev'] as String?,
  next: json['next'] as String?,
);

Map<String, dynamic> _$PaginationLinksModelToJson(
  PaginationLinksModel instance,
) => <String, dynamic>{
  'first': instance.first,
  'last': instance.last,
  'prev': instance.prev,
  'next': instance.next,
};
