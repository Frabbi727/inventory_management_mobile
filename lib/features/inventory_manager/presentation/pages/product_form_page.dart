import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_form_controller.dart';
import '../models/selected_product_photo.dart';

class ProductFormPage extends GetView<ProductFormController> {
  const ProductFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEdit ? 'Edit Product' : 'Create Product'),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InlineErrorMessage(
                      message: controller.errorMessage.value!,
                    ),
                  ),
                _FormSection(
                  title: 'Product Details',
                  subtitle:
                      'Add the basic information used to identify this product.',
                  child: Column(
                    children: [
                      _FormField(
                        controller: controller.nameController,
                        label: 'Product Name',
                        hintText: 'Enter product name',
                        prefixIcon: Icons.inventory_2_outlined,
                        validator: controller.requiredField,
                      ),
                      const SizedBox(height: 14),
                      _ReadOnlyInfoCard(
                        label: 'Barcode',
                        icon: Icons.qr_code_2_rounded,
                        value: controller.barcodeController.text.trim().isEmpty
                            ? 'Barcode will be assigned from the scanner flow.'
                            : controller.barcodeController.text.trim(),
                        helperText:
                            'This value is system-generated and cannot be edited here.',
                        preview:
                            controller.barcodeController.text.trim().isEmpty
                            ? null
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F7F7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Read only',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF0F766E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      _DropdownField<int>(
                        value: controller.selectedCategoryId.value,
                        label: controller.isReferenceDataLoading.value
                            ? 'Category (loading...)'
                            : 'Category',
                        prefixIcon: Icons.category_outlined,
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
                        validator: (value) =>
                            value == null ? 'Category is required.' : null,
                      ),
                      const SizedBox(height: 14),
                      _DropdownField<int>(
                        value: controller.selectedUnitId.value,
                        label: controller.isReferenceDataLoading.value
                            ? 'Unit (loading...)'
                            : 'Unit',
                        prefixIcon: Icons.straighten_rounded,
                        items: controller.units
                            .map(
                              (unit) => DropdownMenuItem<int>(
                                value: unit.id,
                                child: Text(
                                  unit.shortName == null ||
                                          unit.shortName!.isEmpty
                                      ? (unit.name ?? 'Unit ${unit.id}')
                                      : '${unit.name ?? 'Unit'} (${unit.shortName})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: controller.isReferenceDataLoading.value
                            ? null
                            : controller.onUnitChanged,
                        validator: (value) =>
                            value == null ? 'Unit is required.' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Pricing & Stock',
                  subtitle: 'Set pricing, thresholds, and availability status.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: controller.purchasePriceController,
                              label: 'Purchase Price',
                              hintText: '0.00',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: controller.requiredNumberField,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              controller: controller.sellingPriceController,
                              label: 'Selling Price',
                              hintText: '0.00',
                              prefixIcon: Icons.sell_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: controller.requiredNumberField,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        controller: controller.minimumStockController,
                        label: 'Minimum Stock',
                        hintText: 'Enter alert threshold',
                        prefixIcon: Icons.warning_amber_rounded,
                        keyboardType: TextInputType.number,
                        validator: controller.requiredNumberField,
                      ),
                      const SizedBox(height: 14),
                      _DropdownField<String>(
                        value: controller.selectedStatus.value,
                        label: 'Status',
                        prefixIcon: Icons.toggle_on_outlined,
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: controller.onStatusChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PhotoSection(controller: controller),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      controller.isSubmitting.value ||
                          controller.hasPendingCompression
                      ? null
                      : controller.submit,
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    controller.isEdit ? 'Update Product' : 'Create Product',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyInfoCard extends StatelessWidget {
  const _ReadOnlyInfoCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.helperText,
    this.preview,
  });

  final String label;
  final IconData icon;
  final String value;
  final String helperText;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E8E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              preview ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.controller});

  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(
      () => _FormSection(
        title: 'Photos',
        subtitle:
            'Upload product photos. Max 200 KB per image after compression.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _UploadActionCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'Take Photo',
                    subtitle: 'Use camera',
                    onTap: controller.isSubmitting.value
                        ? null
                        : controller.pickFromCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadActionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Upload Photos',
                    subtitle: 'Choose from gallery',
                    onTap: controller.isSubmitting.value
                        ? null
                        : controller.pickFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'JPEG and PNG files are accepted. Larger images are compressed automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (controller.hasPendingCompression) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (controller.photoErrorMessage.value != null) ...[
              const SizedBox(height: 14),
              _InlineErrorMessage(message: controller.photoErrorMessage.value!),
            ],
            const SizedBox(height: 16),
            if (controller.selectedPhotos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No photos added yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add product images to make the listing easier to identify.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: controller.selectedPhotos.length,
                itemBuilder: (context, index) {
                  final photo = controller.selectedPhotos[index];
                  return _PhotoTile(photo: photo, controller: controller);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadActionCard extends StatelessWidget {
  const _UploadActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8E8E7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.controller});

  final SelectedProductPhoto photo;
  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = switch (photo.status) {
      SelectedProductPhotoStatus.ready => const Color(0xFF16A34A),
      SelectedProductPhotoStatus.compressing => colorScheme.primary,
      SelectedProductPhotoStatus.tooLarge => colorScheme.error,
      SelectedProductPhotoStatus.failed => colorScheme.error,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFE2E8F0),
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: () => controller.removePhoto(photo.id),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.58),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    controller.photoStatusLabel(photo.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.formatBytes(photo.originalBytes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (photo.compressedBytes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Compressed to ${controller.formatBytes(photo.compressedBytes!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (photo.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    photo.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  const _InlineErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2B8B5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB42318),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
  });

  final T? value;
  final String label;
  final IconData prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: _inputDecoration(
        context,
        label: label,
        prefixIcon: prefixIcon,
      ),
      borderRadius: BorderRadius.circular(18),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.hintText,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(
        context,
        label: label,
        prefixIcon: prefixIcon,
        hintText: hintText,
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData prefixIcon,
  String? hintText,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFFBFCFD),
    prefixIcon: Icon(prefixIcon),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFD8E0E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFFD8E0E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colorScheme.error, width: 1.4),
    ),
  );
}
