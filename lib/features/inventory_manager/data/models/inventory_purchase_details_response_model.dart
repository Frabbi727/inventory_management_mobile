import 'inventory_purchase_model.dart';

class InventoryPurchaseDetailsResponseModel {
  const InventoryPurchaseDetailsResponseModel({this.data});

  final InventoryPurchaseModel? data;

  factory InventoryPurchaseDetailsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InventoryPurchaseDetailsResponseModel(
      data: json['data'] is Map<String, dynamic>
          ? InventoryPurchaseModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
