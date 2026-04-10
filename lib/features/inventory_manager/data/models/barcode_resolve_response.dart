import '../../../products/data/models/product_model.dart';

class BarcodeResolveResponse {
  const BarcodeResolveResponse({
    required this.message,
    required this.exists,
    required this.action,
    required this.barcode,
    required this.data,
  });

  final String message;
  final bool exists;
  final String action;
  final String barcode;
  final ProductModel? data;

  factory BarcodeResolveResponse.fromJson(Map<String, dynamic> json) {
    return BarcodeResolveResponse(
      message: json['message'] as String? ?? '',
      exists: json['exists'] as bool? ?? false,
      action: json['action'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
