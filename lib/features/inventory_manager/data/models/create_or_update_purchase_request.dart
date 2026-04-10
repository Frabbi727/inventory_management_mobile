import 'inventory_purchase_item_request.dart';

class CreateOrUpdatePurchaseRequest {
  const CreateOrUpdatePurchaseRequest({
    required this.purchaseDate,
    this.note,
    required this.items,
  });

  final String purchaseDate;
  final String? note;
  final List<InventoryPurchaseItemRequest> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'purchase_date': purchaseDate,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
