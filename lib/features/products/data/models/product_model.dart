import 'package:json_annotation/json_annotation.dart';

import '../../../../core/network/media_url_resolver.dart';
import 'product_category_model.dart';
import 'product_photo_model.dart';
import 'product_unit_model.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  const ProductModel({
    this.id,
    this.name,
    this.sku,
    this.barcode,
    this.barcodeImageUrl,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
    this.currentStock,
    this.primaryPhoto,
    this.photos,
    this.photoCount,
    this.category,
    this.unit,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? barcode;

  @JsonKey(name: 'barcode_image_url', fromJson: MediaUrlResolver.resolve)
  final String? barcodeImageUrl;

  @JsonKey(name: 'purchase_price')
  final num? purchasePrice;

  @JsonKey(name: 'selling_price')
  final num? sellingPrice;

  @JsonKey(name: 'minimum_stock_alert')
  final int? minimumStockAlert;

  final String? status;

  @JsonKey(name: 'current_stock')
  final int? currentStock;

  @JsonKey(name: 'primary_photo')
  final ProductPhotoModel? primaryPhoto;

  final List<ProductPhotoModel>? photos;

  @JsonKey(name: 'photo_count')
  final int? photoCount;

  final ProductCategoryModel? category;
  final ProductUnitModel? unit;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  String? get primaryPhotoUrl => primaryPhoto?.fileUrl;

  List<ProductPhotoModel> get galleryPhotos {
    final resolvedPhotos = photos ?? const <ProductPhotoModel>[];
    if (resolvedPhotos.isNotEmpty) {
      return resolvedPhotos;
    }

    final resolvedPrimaryPhoto = primaryPhoto;
    if (resolvedPrimaryPhoto == null) {
      return const <ProductPhotoModel>[];
    }

    return [resolvedPrimaryPhoto];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
