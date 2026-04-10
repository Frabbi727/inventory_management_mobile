import '../../data/models/product_photo_upload_file.dart';

enum ProductPhotoSource { camera, gallery }

enum SelectedProductPhotoStatus { compressing, ready, tooLarge, failed }

class SelectedProductPhoto {
  const SelectedProductPhoto({
    required this.id,
    required this.path,
    required this.fileName,
    required this.source,
    required this.originalBytes,
    required this.status,
    this.compressedBytes,
    this.uploadFile,
    this.errorMessage,
  });

  final String id;
  final String path;
  final String fileName;
  final ProductPhotoSource source;
  final int originalBytes;
  final int? compressedBytes;
  final SelectedProductPhotoStatus status;
  final ProductPhotoUploadFile? uploadFile;
  final String? errorMessage;

  bool get isCompressing => status == SelectedProductPhotoStatus.compressing;
  bool get isReady => status == SelectedProductPhotoStatus.ready;

  SelectedProductPhoto copyWith({
    String? id,
    String? path,
    String? fileName,
    ProductPhotoSource? source,
    int? originalBytes,
    int? compressedBytes,
    SelectedProductPhotoStatus? status,
    ProductPhotoUploadFile? uploadFile,
    bool clearUploadFile = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SelectedProductPhoto(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      source: source ?? this.source,
      originalBytes: originalBytes ?? this.originalBytes,
      compressedBytes: compressedBytes ?? this.compressedBytes,
      status: status ?? this.status,
      uploadFile: clearUploadFile ? null : (uploadFile ?? this.uploadFile),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductPhotoCompressionResult {
  const ProductPhotoCompressionResult({
    required this.status,
    this.file,
    this.compressedBytes,
    this.errorMessage,
  });

  final SelectedProductPhotoStatus status;
  final ProductPhotoUploadFile? file;
  final int? compressedBytes;
  final String? errorMessage;
}
