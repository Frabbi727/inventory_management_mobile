import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/pagination_links_model.dart';
import '../../../../core/models/pagination_meta_model.dart';
import 'product_model.dart';

part 'product_list_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductListResponseModel {
  const ProductListResponseModel({this.data, this.links, this.meta});

  final List<ProductModel>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListResponseModelToJson(this);
}
