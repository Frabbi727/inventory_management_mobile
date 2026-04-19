import 'package:json_annotation/json_annotation.dart';

part 'inventory_dashboard_summary_model.g.dart';

@JsonSerializable()
class InventoryDashboardSummaryModel {
  const InventoryDashboardSummaryModel({
    this.totalActiveProducts,
    this.allCount,
    this.lowStockCount,
    this.outOfStockCount,
    this.inStockCount,
    this.productsAddedToday,
    this.purchasesCreatedToday,
    this.purchaseValueToday,
  });

  @JsonKey(name: 'total_active_products')
  final int? totalActiveProducts;

  @JsonKey(name: 'all_count')
  final int? allCount;

  @JsonKey(name: 'low_stock_count')
  final int? lowStockCount;

  @JsonKey(name: 'out_of_stock_count')
  final int? outOfStockCount;

  @JsonKey(name: 'in_stock_count')
  final int? inStockCount;

  @JsonKey(name: 'products_added_today')
  final int? productsAddedToday;

  @JsonKey(name: 'purchases_created_today')
  final int? purchasesCreatedToday;

  @JsonKey(name: 'purchase_value_today')
  final num? purchaseValueToday;

  factory InventoryDashboardSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryDashboardSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryDashboardSummaryModelToJson(this);
}
