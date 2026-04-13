import 'pagination_links_model.dart';
import 'pagination_meta_model.dart';

class ApiPaginatedResponseModel<T> {
  const ApiPaginatedResponseModel({
    this.success,
    this.message,
    this.data,
    this.links,
    this.meta,
  });

  final bool? success;
  final String? message;
  final List<T>? data;
  final PaginationLinksModel? links;
  final PaginationMetaModel? meta;

  factory ApiPaginatedResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final rawData = json['data'];

    return ApiPaginatedResponseModel<T>(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: rawData is List
          ? rawData.whereType<Map<String, dynamic>>().map(fromJsonT).toList()
          : null,
      links: json['links'] is Map<String, dynamic>
          ? PaginationLinksModel.fromJson(json['links'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] is Map<String, dynamic>
          ? PaginationMetaModel.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toResponseJson(
    Map<String, dynamic> Function(T value) toJsonT,
  ) {
    return <String, dynamic>{
      'success': success,
      'message': message,
      'data': data?.map(toJsonT).toList(),
      'links': links?.toJson(),
      'meta': meta?.toJson(),
    };
  }
}
