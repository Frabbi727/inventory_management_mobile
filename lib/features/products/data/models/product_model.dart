import '../../../../core/network/media_url_resolver.dart';
import 'product_category_model.dart';
import 'product_photo_model.dart';
import 'product_stock_status.dart';
import 'product_subcategory_model.dart';
import 'product_unit_model.dart';
import 'product_variant_attribute_model.dart';
import 'product_variant_model.dart';
import 'product_variant_summary_model.dart';

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
    this.stockStatus,
    this.status,
    this.currentStock,
    this.primaryPhoto,
    this.photos,
    this.photoCount,
    this.category,
    this.subcategory,
    this.unit,
    this.hasVariants,
    this.variantSummary,
    this.variantAttributes,
    this.variants,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? barcode;

  final String? barcodeImageUrl;

  final num? purchasePrice;

  final num? sellingPrice;

  final int? minimumStockAlert;

  final ProductStockStatus? stockStatus;

  final String? status;

  final int? currentStock;

  final ProductPhotoModel? primaryPhoto;

  final List<ProductPhotoModel>? photos;

  final int? photoCount;

  final ProductCategoryModel? category;
  final ProductSubcategoryModel? subcategory;
  final ProductUnitModel? unit;
  final bool? hasVariants;
  final ProductVariantSummaryModel? variantSummary;
  final List<ProductVariantAttributeModel>? variantAttributes;
  final List<ProductVariantModel>? variants;

  final String? createdAt;

  final String? updatedAt;

  String? get primaryPhotoUrl => primaryPhoto?.fileUrl;

  ProductStockStatus get effectiveStockStatus =>
      stockStatus ??
      ProductStockStatus.resolve(
        apiStatus: stockStatus,
        currentStock: currentStock,
        minimumStockAlert: minimumStockAlert,
      );

  ProductStockStatus get resolvedStockStatus => effectiveStockStatus;

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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      barcodeImageUrl: MediaUrlResolver.resolve(
        json['barcode_image_url'] as String?,
      ),
      purchasePrice: _asNum(json['purchase_price']),
      sellingPrice: _asNum(json['selling_price']),
      minimumStockAlert: _asInt(json['minimum_stock_alert']),
      stockStatus: ProductStockStatus.fromApiValue(
        json['stock_status'] as String?,
      ),
      status: json['status'] as String?,
      currentStock: _asInt(json['current_stock']),
      primaryPhoto: json['primary_photo'] is Map<String, dynamic>
          ? ProductPhotoModel.fromJson(
              json['primary_photo'] as Map<String, dynamic>,
            )
          : null,
      photos: (json['photos'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProductPhotoModel.fromJson)
          .toList(),
      photoCount: _asInt(json['photo_count']),
      category: json['category'] is Map<String, dynamic>
          ? ProductCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      subcategory: json['subcategory'] is Map<String, dynamic>
          ? ProductSubcategoryModel.fromJson(
              json['subcategory'] as Map<String, dynamic>,
            )
          : null,
      unit: json['unit'] is Map<String, dynamic>
          ? ProductUnitModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      hasVariants: _asBool(json['has_variants']),
      variantSummary: json['variant_summary'] is Map<String, dynamic>
          ? ProductVariantSummaryModel.fromJson(
              json['variant_summary'] as Map<String, dynamic>,
            )
          : null,
      variantAttributes: (json['variant_attributes'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProductVariantAttributeModel.fromJson)
          .toList(),
      variants: (json['variants'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(ProductVariantModel.fromJson)
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'barcode_image_url': barcodeImageUrl,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'minimum_stock_alert': minimumStockAlert,
      'stock_status': ProductStockStatus.toApiValue(stockStatus),
      'status': status,
      'current_stock': currentStock,
      'primary_photo': primaryPhoto?.toJson(),
      'photos': photos?.map((photo) => photo.toJson()).toList(),
      'photo_count': photoCount,
      'category': category?.toJson(),
      'subcategory': subcategory?.toJson(),
      'unit': unit?.toJson(),
      'has_variants': hasVariants,
      'variant_summary': variantSummary?.toJson(),
      'variant_attributes': variantAttributes
          ?.map((attribute) => attribute.toJson())
          .toList(),
      'variants': variants?.map((variant) => variant.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static num? _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }
}
