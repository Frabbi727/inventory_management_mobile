import 'dart:typed_data';

class ProductPhotoUploadFile {
  const ProductPhotoUploadFile({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
