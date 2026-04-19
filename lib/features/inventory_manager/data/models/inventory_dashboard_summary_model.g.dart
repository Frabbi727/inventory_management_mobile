// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dashboard_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryDashboardSummaryModel _$InventoryDashboardSummaryModelFromJson(
  Map<String, dynamic> json,
) => InventoryDashboardSummaryModel(
  totalActiveProducts: (json['total_active_products'] as num?)?.toInt(),
  allCount: (json['all_count'] as num?)?.toInt(),
  lowStockCount: (json['low_stock_count'] as num?)?.toInt(),
  outOfStockCount: (json['out_of_stock_count'] as num?)?.toInt(),
  inStockCount: (json['in_stock_count'] as num?)?.toInt(),
  productsAddedToday: (json['products_added_today'] as num?)?.toInt(),
  purchasesCreatedToday: (json['purchases_created_today'] as num?)?.toInt(),
  purchaseValueToday: json['purchase_value_today'] as num?,
);

Map<String, dynamic> _$InventoryDashboardSummaryModelToJson(
  InventoryDashboardSummaryModel instance,
) => <String, dynamic>{
  'total_active_products': instance.totalActiveProducts,
  'all_count': instance.allCount,
  'low_stock_count': instance.lowStockCount,
  'out_of_stock_count': instance.outOfStockCount,
  'in_stock_count': instance.inStockCount,
  'products_added_today': instance.productsAddedToday,
  'purchases_created_today': instance.purchasesCreatedToday,
  'purchase_value_today': instance.purchaseValueToday,
};
