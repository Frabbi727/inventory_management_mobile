import 'purchase_creator_model.dart';
import 'inventory_purchase_item_model.dart';

class InventoryPurchaseModel {
  const InventoryPurchaseModel({
    this.id,
    this.purchaseNo,
    this.purchaseDate,
    this.note,
    this.totalAmount,
    this.itemsCount,
    this.creator,
    this.createdAt,
    this.items,
  });

  final int? id;
  final String? purchaseNo;
  final String? purchaseDate;
  final String? note;
  final num? totalAmount;
  final int? itemsCount;
  final PurchaseCreatorModel? creator;
  final String? createdAt;
  final List<InventoryPurchaseItemModel>? items;

  factory InventoryPurchaseModel.fromJson(Map<String, dynamic> json) {
    return InventoryPurchaseModel(
      id: json['id'] as int?,
      purchaseNo: json['purchase_no'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      note: json['note'] as String?,
      totalAmount: json['total_amount'] as num?,
      itemsCount: json['items_count'] as int?,
      creator: json['creator'] is Map<String, dynamic>
          ? PurchaseCreatorModel.fromJson(
              json['creator'] as Map<String, dynamic>,
            )
          : null,
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
