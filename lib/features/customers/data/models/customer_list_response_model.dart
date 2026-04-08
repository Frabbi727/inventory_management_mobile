import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/pagination_links_model.dart';
import '../../../../core/models/pagination_meta_model.dart';
import 'customer_model.dart';

part 'customer_list_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomerListResponseModel {
  const CustomerListResponseModel({this.data, this.links, this.meta});

  final List<CustomerModel>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory CustomerListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerListResponseModelToJson(this);
}
