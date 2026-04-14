import '../../../products/data/models/product_model.dart';
import '../../../products/data/models/product_variant_model.dart';

class BarcodeResolveResponse {
  const BarcodeResolveResponse({
    required this.message,
    required this.exists,
    required this.action,
    required this.barcode,
    required this.matchType,
    required this.data,
    required this.variant,
  });

  final String message;
  final bool exists;
  final String action;
  final String barcode;
  final String? matchType;
  final ProductModel? data;
  final ProductVariantModel? variant;

  factory BarcodeResolveResponse.fromJson(Map<String, dynamic> json) {
    return BarcodeResolveResponse(
      message: json['message'] as String? ?? '',
      exists: json['exists'] as bool? ?? false,
      action: json['action'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      matchType: json['match_type'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      variant: json['variant'] is Map<String, dynamic>
          ? ProductVariantModel.fromJson(
              json['variant'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
