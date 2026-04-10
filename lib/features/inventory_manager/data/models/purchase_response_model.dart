import 'purchase_creator_model.dart';
import 'purchase_response_item_model.dart';

class PurchaseResponseModel {
  const PurchaseResponseModel({
    this.id,
    this.purchaseNo,
    this.purchaseDate,
    this.totalAmount,
    this.note,
    this.creator,
    this.itemsCount,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? purchaseNo;
  final String? purchaseDate;
  final num? totalAmount;
  final String? note;
  final PurchaseCreatorModel? creator;
  final int? itemsCount;
  final List<PurchaseResponseItemModel>? items;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseResponseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseResponseModel(
      id: json['id'] as int?,
      purchaseNo: json['purchase_no'] as String?,
      purchaseDate: json['purchase_date'] as String?,
      totalAmount: json['total_amount'] as num?,
      note: json['note'] as String?,
      creator: json['creator'] is Map<String, dynamic>
          ? PurchaseCreatorModel.fromJson(
              json['creator'] as Map<String, dynamic>,
            )
          : null,
      itemsCount: json['items_count'] as int?,
      items: json['items'] is List
          ? (json['items'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(PurchaseResponseItemModel.fromJson)
                .toList()
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
