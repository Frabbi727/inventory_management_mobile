// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_or_update_barcode_product_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateOrUpdateBarcodeProductRequest
_$CreateOrUpdateBarcodeProductRequestFromJson(Map<String, dynamic> json) =>
    CreateOrUpdateBarcodeProductRequest(
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      unitId: (json['unit_id'] as num).toInt(),
      purchasePrice: json['purchase_price'] as num,
      sellingPrice: json['selling_price'] as num,
      minimumStockAlert: (json['minimum_stock_alert'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$CreateOrUpdateBarcodeProductRequestToJson(
  CreateOrUpdateBarcodeProductRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'sku': ?instance.sku,
  'barcode': instance.barcode,
  'category_id': instance.categoryId,
  'unit_id': instance.unitId,
  'purchase_price': instance.purchasePrice,
  'selling_price': instance.sellingPrice,
  'minimum_stock_alert': instance.minimumStockAlert,
  'status': instance.status,
};
