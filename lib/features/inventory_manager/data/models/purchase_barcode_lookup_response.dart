import '../../../products/data/models/product_model.dart';

class PurchaseBarcodeLookupResponse {
  const PurchaseBarcodeLookupResponse({required this.data});

  final ProductModel? data;

  factory PurchaseBarcodeLookupResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseBarcodeLookupResponse(
      data: json['data'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
