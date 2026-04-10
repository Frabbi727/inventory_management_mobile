import 'inventory_purchase_item_model.dart';

class InventoryPurchaseModel {
  const InventoryPurchaseModel({
    this.id,
    this.purchaseDate,
    this.note,
    this.totalAmount,
    this.itemsCount,
    this.createdAt,
    this.items,
  });

  final int? id;
  final String? purchaseDate;
  final String? note;
  final num? totalAmount;
  final int? itemsCount;
  final String? createdAt;
  final List<InventoryPurchaseItemModel>? items;

  factory InventoryPurchaseModel.fromJson(Map<String, dynamic> json) {
    return InventoryPurchaseModel(
      id: json['id'] as int?,
      purchaseDate: json['purchase_date'] as String?,
      note: json['note'] as String?,
      totalAmount: json['total_amount'] as num?,
      itemsCount: json['items_count'] as int?,
      createdAt: json['created_at'] as String?,
      items: json['items'] is List
          ? (json['items'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(InventoryPurchaseItemModel.fromJson)
                .toList()
          : null,
    );
  }
}
