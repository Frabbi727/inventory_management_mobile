// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_products_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryProductsPageModel _$InventoryProductsPageModelFromJson(
  Map<String, dynamic> json,
) => InventoryProductsPageModel(
  data: InventoryProductsPageModel._productsFromJson(json['data'] as List?),
  currentPage: (json['current_page'] as num?)?.toInt(),
  perPage: (json['per_page'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toInt(),
  lastPage: (json['last_page'] as num?)?.toInt(),
);

Map<String, dynamic> _$InventoryProductsPageModelToJson(
  InventoryProductsPageModel instance,
) => <String, dynamic>{
  'data': InventoryProductsPageModel._productsToJson(instance.data),
  'current_page': instance.currentPage,
  'per_page': instance.perPage,
  'total': instance.total,
  'last_page': instance.lastPage,
};
