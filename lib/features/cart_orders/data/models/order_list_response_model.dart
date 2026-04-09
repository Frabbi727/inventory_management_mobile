import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/pagination_links_model.dart';
import '../../../../core/models/pagination_meta_model.dart';
import 'order_model.dart';

part 'order_list_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderListResponseModel {
  const OrderListResponseModel({this.data, this.links, this.meta});

  final List<OrderModel>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory OrderListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderListResponseModelToJson(this);
}
