import '../../../../core/models/api_object_response_model.dart';
import 'product_model.dart';

class ProductDetailsResponseModel extends ApiObjectResponseModel<ProductModel> {
  const ProductDetailsResponseModel({super.success, super.message, super.data});

  factory ProductDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    final parsed = ApiObjectResponseModel<ProductModel>.fromJson(
      json,
      ProductModel.fromJson,
    );

    return ProductDetailsResponseModel(
      success: parsed.success,
      message: parsed.message,
      data: parsed.data,
    );
  }

  Map<String, dynamic> toJson() =>
      super.toResponseJson((product) => product.toJson());
}
