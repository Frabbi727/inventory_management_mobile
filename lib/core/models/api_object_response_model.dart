class ApiObjectResponseModel<T> {
  const ApiObjectResponseModel({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final T? data;

  factory ApiObjectResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final rawData = json['data'];

    return ApiObjectResponseModel<T>(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: rawData is Map<String, dynamic> ? fromJsonT(rawData) : null,
    );
  }

  Map<String, dynamic> toResponseJson(
    Map<String, dynamic> Function(T value) toJsonT,
  ) {
    return <String, dynamic>{
      'success': success,
      'message': message,
      'data': data == null ? null : toJsonT(data as T),
    };
  }
}
