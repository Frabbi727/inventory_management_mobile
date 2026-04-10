import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_form_controller.dart';
import '../models/selected_product_photo.dart';

class ProductFormPage extends GetView<ProductFormController> {
  const ProductFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEdit ? 'Edit Product' : 'Create Product'),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.errorMessage.value!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _FormField(
                  controller: controller.nameController,
                  label: 'Product Name',
                  validator: controller.requiredField,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: controller.skuController,
                  label: 'SKU',
                  validator: controller.requiredField,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: controller.barcodeController,
                  label: 'Barcode',
                  validator: controller.requiredField,
                  enabled: !controller.isEdit,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: controller.selectedCategoryId.value,
                  isExpanded: true,
                  items: controller.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(
                            category.name ?? 'Category ${category.id}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.isReferenceDataLoading.value
                      ? null
                      : controller.onCategoryChanged,
                  decoration: InputDecoration(
                    labelText: controller.isReferenceDataLoading.value
                        ? 'Category (loading...)'
                        : 'Category',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ? 'Category is required.' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: controller.selectedUnitId.value,
                  isExpanded: true,
                  items: controller.units
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
                  onChanged: controller.isReferenceDataLoading.value
                      ? null
                      : controller.onUnitChanged,
                  decoration: InputDecoration(
                    labelText: controller.isReferenceDataLoading.value
                        ? 'Unit (loading...)'
                        : 'Unit',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ? 'Unit is required.' : null,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: controller.purchasePriceController,
                  label: 'Purchase Price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: controller.requiredNumberField,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: controller.sellingPriceController,
                  label: 'Selling Price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: controller.requiredNumberField,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: controller.minimumStockController,
                  label: 'Minimum Stock Alert',
                  keyboardType: TextInputType.number,
                  validator: controller.requiredNumberField,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedStatus.value,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: controller.onStatusChanged,
                ),
                const SizedBox(height: 16),
                _PhotoSection(controller: controller),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed:
                      controller.isSubmitting.value ||
                          controller.hasPendingCompression
                      ? null
                      : controller.submit,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          controller.isEdit
                              ? 'Update Product'
                              : 'Create Product',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.controller});

  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(
      () => Card(
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
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.pickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              if (controller.hasPendingCompression) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (controller.photoErrorMessage.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.photoErrorMessage.value!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (controller.selectedPhotos.isEmpty) ...[
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
                  children: controller.selectedPhotos
                      .map(
                        (photo) =>
                            _PhotoCard(photo: photo, controller: controller),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo, required this.controller});

  final SelectedProductPhoto photo;
  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                    onPressed: () => controller.removePhoto(photo.id),
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
                      controller.photoStatusLabel(photo.status),
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
                    'Original: ${controller.formatBytes(photo.originalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (photo.compressedBytes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Compressed: ${controller.formatBytes(photo.compressedBytes!)}',
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
