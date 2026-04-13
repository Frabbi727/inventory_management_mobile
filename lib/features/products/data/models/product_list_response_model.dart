import '../../../../core/models/api_paginated_response_model.dart';
import 'product_model.dart';

class ProductListResponseModel extends ApiPaginatedResponseModel<ProductModel> {
  const ProductListResponseModel({
    super.success,
    super.message,
    super.data,
    super.links,
    super.meta,
  });

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) {
    final parsed = ApiPaginatedResponseModel<ProductModel>.fromJson(
      json,
      ProductModel.fromJson,
    );

    return ProductListResponseModel(
      success: parsed.success,
      message: parsed.message,
      data: parsed.data,
      links: parsed.links,
      meta: parsed.meta,
    );
  }

  Map<String, dynamic> toJson() =>
      super.toResponseJson((product) => product.toJson());
}
