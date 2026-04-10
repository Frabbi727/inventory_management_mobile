import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../../products/data/models/product_unit_model.dart';
import '../../data/models/create_or_update_barcode_product_request.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/selected_product_photo.dart';
import '../services/product_photo_compression_service.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late final ProductFormArgs _args;
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _minimumStockController;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final ProductPhotoCompressionService _compressionService =
      const ProductPhotoCompressionService();

  final List<CategoryModel> _categories = <CategoryModel>[];
  final List<ProductUnitModel> _units = <ProductUnitModel>[];
  final List<SelectedProductPhoto> _selectedPhotos = <SelectedProductPhoto>[];
  int _nextPhotoId = 0;
  bool _isSubmitting = false;
  bool _isReferenceDataLoading = false;
  String? _errorMessage;
  String? _photoErrorMessage;
  int? _selectedCategoryId;
  int? _selectedUnitId;
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    _args = argument is ProductFormArgs
        ? argument
        : const ProductFormArgs.create();
    _nameController = TextEditingController(text: _args.name ?? '');
    _skuController = TextEditingController(text: _args.sku ?? '');
    _barcodeController = TextEditingController(text: _args.barcode ?? '');
    _purchasePriceController = TextEditingController(
      text: _args.purchasePrice?.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: _args.sellingPrice?.toString() ?? '',
    );
    _minimumStockController = TextEditingController(
      text: _args.minimumStockAlert?.toString() ?? '',
    );
    _selectedCategoryId = _args.categoryId;
    _selectedUnitId = _args.unitId;
    _selectedStatus = _args.status ?? 'active';
    _loadReferenceData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _args.mode == ProductFormMode.edit;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Create Product')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _FormField(
                controller: _nameController,
                label: 'Product Name',
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _skuController,
                label: 'SKU',
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _barcodeController,
                label: 'Barcode',
                validator: _requiredField,
                enabled: !isEdit,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                isExpanded: true,
                items: _categories
                    .map(
                      (category) => DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name ?? 'Category ${category.id}'),
                      ),
                    )
                    .toList(),
                onChanged: _isReferenceDataLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                decoration: InputDecoration(
                  labelText: _isReferenceDataLoading
                      ? 'Category (loading...)'
                      : 'Category',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Category is required.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedUnitId,
                isExpanded: true,
                items: _units
                    .map(
                      (unit) => DropdownMenuItem<int>(
                        value: unit.id,
                        child: Text(
                          unit.shortName == null || unit.shortName!.isEmpty
                              ? (unit.name ?? 'Unit ${unit.id}')
                              : '${unit.name ?? 'Unit'} (${unit.shortName})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isReferenceDataLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                      },
                decoration: InputDecoration(
                  labelText: _isReferenceDataLoading
                      ? 'Unit (loading...)'
                      : 'Unit',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Unit is required.' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _purchasePriceController,
                label: 'Purchase Price',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _requiredNumberField,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _sellingPriceController,
                label: 'Selling Price',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _requiredNumberField,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _minimumStockController,
                label: 'Minimum Stock Alert',
                keyboardType: TextInputType.number,
                validator: _requiredNumberField,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPhotoSection(context),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting || _hasPendingCompression
                    ? null
                    : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update Product' : 'Create Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadReferenceData() async {
    setState(() {
      _isReferenceDataLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = Get.find<InventoryManagerRepository>();
      final results = await Future.wait<dynamic>([
        repository.fetchCategories(),
        repository.fetchUnits(),
      ]);
      final categories = results[0] as List<CategoryModel>;
      final units = results[1] as List<ProductUnitModel>;
      if (!mounted) {
        return;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _units
          ..clear()
          ..addAll(units);
        _selectedCategoryId ??= _categories.isNotEmpty
            ? _categories.first.id
            : null;
        _selectedUnitId ??= _units.isNotEmpty ? _units.first.id : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load categories right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isReferenceDataLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    final categoryId = _selectedCategoryId;
    final unitId = _selectedUnitId;
    if (categoryId == null) {
      setState(() {
        _errorMessage = 'Category is required.';
      });
      return;
    }
    if (unitId == null) {
      setState(() {
        _errorMessage = 'Unit is required.';
      });
      return;
    }

    final request = CreateOrUpdateBarcodeProductRequest(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      categoryId: categoryId,
      unitId: unitId,
      purchasePrice: num.parse(_purchasePriceController.text.trim()),
      sellingPrice: num.parse(_sellingPriceController.text.trim()),
      minimumStockAlert: int.parse(_minimumStockController.text.trim()),
      status: _selectedStatus,
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _photoErrorMessage = null;
    });

    try {
      final repository = Get.find<InventoryManagerRepository>();
      final readyPhotos = _selectedPhotos
          .where((photo) => photo.isReady && photo.uploadFile != null)
          .map((photo) => photo.uploadFile!)
          .toList();
      final product = _args.mode == ProductFormMode.edit
          ? await repository.updateProductByBarcode(
              _args.barcode ?? '',
              request,
              photos: readyPhotos,
            )
          : await repository.createProductFromBarcode(
              request,
              photos: readyPhotos,
            );

      if (!mounted) {
        return;
      }

      Get.offNamed(AppRoutes.productDetails, arguments: product);
      Get.snackbar(
        'Product saved',
        _args.mode == ProductFormMode.edit
            ? 'Product updated successfully.'
            : 'Product created successfully.',
      );
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
        _photoErrorMessage = _extractPhotoError(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to save the product right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _requiredNumberField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    if (num.tryParse(value.trim()) == null) {
      return 'Enter a valid number.';
    }
    return null;
  }

  Widget _buildPhotoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photos (max 200 KB each)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'JPEG and PNG inputs are accepted. Larger files are compressed to JPEG before upload.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFromCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            if (_hasPendingCompression) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_photoErrorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _photoErrorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_selectedPhotos.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No photos selected yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _selectedPhotos
                    .map((photo) => _buildPhotoCard(context, photo))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, SelectedProductPhoto photo) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = _photoStatusLabel(photo.status);
    final statusColor = switch (photo.status) {
      SelectedProductPhotoStatus.ready => Colors.green,
      SelectedProductPhotoStatus.compressing => colorScheme.primary,
      SelectedProductPhotoStatus.tooLarge => colorScheme.error,
      SelectedProductPhotoStatus.failed => colorScheme.error,
    };

    return SizedBox(
      width: 168,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE0E0E0),
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _removePhoto(photo.id),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${photo.source == ProductPhotoSource.camera ? 'Camera' : 'Gallery'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original: ${_formatBytes(photo.originalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (photo.compressedBytes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Compressed: ${_formatBytes(photo.compressedBytes!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (photo.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      photo.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasPendingCompression =>
      _selectedPhotos.any((photo) => photo.isCompressing);

  Future<void> _pickFromGallery() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );
      if (files.isEmpty) {
        return;
      }
      await _addPhotos(files, ProductPhotoSource.gallery);
    } on PlatformException catch (error) {
      _showPhotoPickerError(_mapPickerError(error));
    } catch (_) {
      _showPhotoPickerError('Unable to open the gallery right now.');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      await _addPhotos(<XFile>[file], ProductPhotoSource.camera);
    } on PlatformException catch (error) {
      _showPhotoPickerError(_mapPickerError(error));
    } catch (_) {
      _showPhotoPickerError('Unable to open the camera right now.');
    }
  }

  Future<void> _addPhotos(List<XFile> files, ProductPhotoSource source) async {
    final pendingPhotos = files
        .map((file) => (file: file, id: _createPhotoId()))
        .toList();

    setState(() {
      _photoErrorMessage = null;
      for (final pendingPhoto in pendingPhotos) {
        final file = pendingPhoto.file;
        _selectedPhotos.add(
          SelectedProductPhoto(
            id: pendingPhoto.id,
            path: file.path,
            fileName: file.name,
            source: source,
            originalBytes: 0,
            status: SelectedProductPhotoStatus.compressing,
          ),
        );
      }
    });

    for (final pendingPhoto in pendingPhotos) {
      final file = pendingPhoto.file;
      final id = pendingPhoto.id;
      try {
        final originalBytes = await File(file.path).length();
        _updatePhoto(
          id,
          (photo) => photo.copyWith(originalBytes: originalBytes),
        );
        final result = await _compressionService.compress(file);
        _updatePhoto(
          id,
          (photo) => photo.copyWith(
            compressedBytes: result.compressedBytes,
            status: result.status,
            uploadFile: result.file,
            clearUploadFile: result.file == null,
            errorMessage: result.errorMessage,
            clearErrorMessage: result.errorMessage == null,
          ),
        );
      } catch (_) {
        _updatePhoto(
          id,
          (photo) => photo.copyWith(
            status: SelectedProductPhotoStatus.failed,
            clearUploadFile: true,
            errorMessage: 'Compression failed for this image.',
          ),
        );
      }
    }
  }

  String _createPhotoId() => 'photo-${_nextPhotoId++}';

  void _updatePhoto(
    String id,
    SelectedProductPhoto Function(SelectedProductPhoto photo) update,
  ) {
    if (!mounted) {
      return;
    }

    final index = _selectedPhotos.indexWhere((photo) => photo.id == id);
    if (index == -1) {
      return;
    }

    setState(() {
      _selectedPhotos[index] = update(_selectedPhotos[index]);
    });
  }

  void _removePhoto(String id) {
    setState(() {
      _selectedPhotos.removeWhere((photo) => photo.id == id);
    });
  }

  void _showPhotoPickerError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _photoErrorMessage = message;
    });
  }

  String _mapPickerError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('camera_access_denied') ||
        code.contains('camera_access_restricted')) {
      return 'Camera access is required to take product photos. Allow permission and try again.';
    }
    if (code.contains('photo_access_denied') ||
        code.contains('photo_access_restricted')) {
      return 'Gallery access is required to choose product photos. Allow permission and try again.';
    }
    if (code.contains('no_available_camera')) {
      return 'No camera is available on this device.';
    }
    if (code.contains('already_active') || code.contains('multiple_request')) {
      return 'Another photo picker request is already in progress. Close it and try again.';
    }
    if (code.contains('invalid_image')) {
      return 'The selected image could not be read. Try another photo.';
    }
    if (code.contains('permission') || message.contains('permission')) {
      return 'Photo permission is blocked for this app. Enable camera or photo access in system settings and try again.';
    }

    final fallback = 'Unable to open photo access right now. Please try again.';
    if (!kDebugMode) {
      return fallback;
    }

    final details = <String>[
      'code=${error.code}',
      if (error.message != null && error.message!.trim().isNotEmpty)
        'message=${error.message!.trim()}',
    ].join(', ');
    return '$fallback ($details)';
  }

  String? _extractPhotoError(ApiException error) {
    final errors = error.errors;
    if (errors == null || errors.isEmpty) {
      return null;
    }

    for (final entry in errors.entries) {
      if (!entry.key.startsWith('photos')) {
        continue;
      }

      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String _photoStatusLabel(SelectedProductPhotoStatus status) {
    return switch (status) {
      SelectedProductPhotoStatus.ready => 'Ready',
      SelectedProductPhotoStatus.compressing => 'Compressing',
      SelectedProductPhotoStatus.tooLarge => 'Too large',
      SelectedProductPhotoStatus.failed => 'Failed',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kiloBytes = bytes / 1024;
    return '${kiloBytes.toStringAsFixed(kiloBytes >= 100 ? 0 : 1)} KB';
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

enum ProductFormMode { create, edit }

class ProductFormArgs {
  const ProductFormArgs({
    required this.mode,
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  });

  const ProductFormArgs.create({
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  }) : mode = ProductFormMode.create;

  const ProductFormArgs.edit({
    this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.minimumStockAlert,
    this.status,
  }) : mode = ProductFormMode.edit;

  final ProductFormMode mode;
  final String? name;
  final String? sku;
  final String? barcode;
  final int? categoryId;
  final int? unitId;
  final num? purchasePrice;
  final num? sellingPrice;
  final int? minimumStockAlert;
  final String? status;
}
