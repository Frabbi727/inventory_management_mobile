// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  sku: json['sku'] as String?,
  purchasePrice: json['purchase_price'] as num?,
  sellingPrice: json['selling_price'] as num?,
  minimumStockAlert: (json['minimum_stock_alert'] as num?)?.toInt(),
  status: json['status'] as String?,
  currentStock: (json['current_stock'] as num?)?.toInt(),
  category: json['category'] == null
      ? null
      : ProductCategoryModel.fromJson(json['category'] as Map<String, dynamic>),
  unit: json['unit'] == null
      ? null
      : ProductUnitModel.fromJson(json['unit'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'purchase_price': instance.purchasePrice,
      'selling_price': instance.sellingPrice,
      'minimum_stock_alert': instance.minimumStockAlert,
      'status': instance.status,
      'current_stock': instance.currentStock,
      'category': instance.category?.toJson(),
      'unit': instance.unit?.toJson(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
