class ApiListResponseModel<T> {
  const ApiListResponseModel({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final List<T>? data;

  factory ApiListResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final rawData = json['data'];

    return ApiListResponseModel<T>(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: rawData is List
          ? rawData.whereType<Map<String, dynamic>>().map(fromJsonT).toList()
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
    };
  }
}
