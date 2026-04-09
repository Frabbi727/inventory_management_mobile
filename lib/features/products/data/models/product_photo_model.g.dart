// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductPhotoModel _$ProductPhotoModelFromJson(Map<String, dynamic> json) =>
    ProductPhotoModel(
      id: (json['id'] as num?)?.toInt(),
      fileName: json['file_name'] as String?,
      fileUrl: MediaUrlResolver.resolve(json['file_url'] as String?),
      mimeType: json['mime_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt(),
      isPrimary: json['is_primary'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$ProductPhotoModelToJson(ProductPhotoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_name': instance.fileName,
      'file_url': instance.fileUrl,
      'mime_type': instance.mimeType,
      'file_size': instance.fileSize,
      'sort_order': instance.sortOrder,
      'is_primary': instance.isPrimary,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
