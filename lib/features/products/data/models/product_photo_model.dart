import 'package:json_annotation/json_annotation.dart';

import '../../../../core/network/media_url_resolver.dart';

part 'product_photo_model.g.dart';

@JsonSerializable()
class ProductPhotoModel {
  const ProductPhotoModel({
    this.id,
    this.fileName,
    this.fileUrl,
    this.mimeType,
    this.fileSize,
    this.sortOrder,
    this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;

  @JsonKey(name: 'file_name')
  final String? fileName;

  @JsonKey(name: 'file_url', fromJson: MediaUrlResolver.resolve)
  final String? fileUrl;

  @JsonKey(name: 'mime_type')
  final String? mimeType;

  @JsonKey(name: 'file_size')
  final int? fileSize;

  @JsonKey(name: 'sort_order')
  final int? sortOrder;

  @JsonKey(name: 'is_primary')
  final bool? isPrimary;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  factory ProductPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$ProductPhotoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductPhotoModelToJson(this);
}
