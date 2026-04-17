import 'package:json_annotation/json_annotation.dart';

import '../../../../core/models/pagination_links_model.dart';
import '../../../../core/models/pagination_meta_model.dart';
import 'notification_item_model.dart';

part 'notification_list_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationListResponseModel {
  const NotificationListResponseModel({
    this.data,
    this.links,
    this.meta,
  });

  final List<NotificationItemModel>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory NotificationListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListResponseModelToJson(this);
}
