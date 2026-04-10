import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../data/models/product_photo_upload_file.dart';
import '../models/selected_product_photo.dart';

class ProductPhotoCompressionService {
  const ProductPhotoCompressionService({this.maxBytes = 200 * 1024});

  final int maxBytes;

  Future<ProductPhotoCompressionResult> compress(XFile file) async {
    final originalBytes = await File(file.path).length();
    if (originalBytes <= maxBytes) {
      return ProductPhotoCompressionResult(
        status: SelectedProductPhotoStatus.ready,
        file: ProductPhotoUploadFile(
          bytes: await file.readAsBytes(),
          fileName: file.name,
        ),
        compressedBytes: originalBytes,
      );
    }

    const qualities = <int>[90, 80, 70, 60, 50, 40, 30, 20];
    const dimensions = <int>[1920, 1600, 1280, 1024, 800, 640];

    for (final dimension in dimensions) {
      for (final quality in qualities) {
        final bytes = await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: dimension,
          minHeight: dimension,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );

        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        if (bytes.length <= maxBytes) {
          return ProductPhotoCompressionResult(
            status: SelectedProductPhotoStatus.ready,
            file: ProductPhotoUploadFile(
              bytes: bytes,
              fileName: _toJpgFileName(file.name),
            ),
            compressedBytes: bytes.length,
          );
        }
      }
    }

    return ProductPhotoCompressionResult(
      status: SelectedProductPhotoStatus.tooLarge,
      errorMessage: 'Could not reduce this image below 200 KB.',
    );
  }

  String _toJpgFileName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    final baseName = lastDot == -1 ? fileName : fileName.substring(0, lastDot);
    return '$baseName.jpg';
  }
}
