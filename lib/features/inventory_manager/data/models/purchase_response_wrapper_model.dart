import 'purchase_response_model.dart';

class PurchaseResponseWrapperModel {
  const PurchaseResponseWrapperModel({this.message, this.data});

  final String? message;
  final PurchaseResponseModel? data;

  factory PurchaseResponseWrapperModel.fromJson(Map<String, dynamic> json) {
    return PurchaseResponseWrapperModel(
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? PurchaseResponseModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
