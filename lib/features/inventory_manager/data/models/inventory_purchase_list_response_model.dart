import '../../../../core/models/pagination_links_model.dart';
import '../../../../core/models/pagination_meta_model.dart';
import 'inventory_purchase_model.dart';

class InventoryPurchaseListResponseModel {
  const InventoryPurchaseListResponseModel({this.data, this.links, this.meta});

  final List<InventoryPurchaseModel>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory InventoryPurchaseListResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InventoryPurchaseListResponseModel(
      data: json['data'] is List
          ? (json['data'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(InventoryPurchaseModel.fromJson)
                .toList()
          : null,
      links: json['links'] is Map<String, dynamic>
          ? PaginationLinksModel.fromJson(json['links'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] is Map<String, dynamic>
          ? PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}
