import '../../../../core/models/api_list_response_model.dart';
import 'product_subcategory_model.dart';

class SubcategoryListResponseModel
    extends ApiListResponseModel<ProductSubcategoryModel> {
  const SubcategoryListResponseModel({
    super.success,
    super.message,
    super.data,
  });

  factory SubcategoryListResponseModel.fromJson(Map<String, dynamic> json) {
    final parsed = ApiListResponseModel<ProductSubcategoryModel>.fromJson(
      json,
      ProductSubcategoryModel.fromJson,
    );

    return SubcategoryListResponseModel(
      success: parsed.success,
      message: parsed.message,
      data: parsed.data,
    );
  }

  Map<String, dynamic> toJson() =>
      super.toResponseJson((subcategory) => subcategory.toJson());
}
