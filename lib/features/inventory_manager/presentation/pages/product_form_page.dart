import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../products/data/models/category_response_model.dart';
import '../models/editable_variant_attribute.dart';
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
                _ProductFormHero(controller: controller),
                const SizedBox(height: 16),
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
                      'Keep master data consistent. Category controls the available subcategories, and barcode stays tied to the scan flow.',
                  child: Column(
                    children: [
                      _FormField(
                        controller: controller.nameController,
                        label: 'Product Name',
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
                      _SearchableCategoryField(
                        value: controller.selectedCategoryId.value,
                        label: controller.isReferenceDataLoading.value
                            ? 'Category (loading...)'
                            : 'Category',
                        prefixIcon: Icons.category_outlined,
                        categories: controller.categories.toList(
                          growable: false,
                        ),
                        onChanged: controller.isReferenceDataLoading.value
                            ? null
                            : (value) {
                                controller.onCategoryChanged(value);
                              },
                        validator: (value) =>
                            value == null ? 'Category is required.' : null,
                      ),
                      const SizedBox(height: 14),
                      _DropdownField<int>(
                        value: controller.selectedSubcategoryId.value,
                        label: controller.isSubcategoryLoading.value
                            ? 'Subcategory (loading...)'
                            : 'Subcategory',
                        prefixIcon: Icons.account_tree_outlined,
                        items: controller.subcategories
                            .map(
                              (subcategory) => DropdownMenuItem<int>(
                                value: subcategory.id,
                                child: Text(
                                  subcategory.name ??
                                      'Subcategory ${subcategory.id}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: !controller.isSubcategoryEnabled
                            ? null
                            : controller.onSubcategoryChanged,
                        helperText: controller.selectedCategoryId.value == null
                            ? 'Select a category first'
                            : controller.subcategories.isEmpty &&
                                  !controller.isSubcategoryLoading.value
                            ? 'No subcategories available for this category'
                            : 'Optional',
                      ),
                      if (controller.subcategoryErrorMessage.value != null) ...[
                        const SizedBox(height: 10),
                        _InlineErrorMessage(
                          message: controller.subcategoryErrorMessage.value!,
                        ),
                      ],
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
                  subtitle:
                      'Simple products keep prices at the base level. Variant products move pricing into each generated combination.',
                  child: Column(
                    children: [
                      if (controller.showBasePriceFields) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _FormField(
                                controller: controller.purchasePriceController,
                                label: 'Purchase Price',
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
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Variant products use per-variant purchase and selling prices. Base product price fields are disabled.',
                          ),
                        ),
                      const SizedBox(height: 14),
                      _FormField(
                        controller: controller.minimumStockController,
                        label: 'Minimum Stock',
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
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: controller.isVariantsEnabled.value,
                        onChanged: controller.isSubmitting.value
                            ? null
                            : controller.onVariantsToggled,
                        title: const Text('This product has variants'),
                        subtitle: const Text(
                          'Enable if the product is sold or purchased by combinations like model, storage, size, or color.',
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.showVariantSection) ...[
                  const SizedBox(height: 16),
                  _VariantSection(controller: controller),
                ],
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
  const _FormSection({required this.title, required this.child, this.subtitle});

  final String title;
  final Widget child;
  final String? subtitle;

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
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProductFormHero extends StatelessWidget {
  const _ProductFormHero({required this.controller});

  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, const Color(0xFF115E59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.22),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.isEdit
                  ? 'Update product business data'
                  : 'Create product from scan flow',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.isEdit
                  ? 'Adjust pricing, master data, variants, and photos without breaking the barcode contract.'
                  : 'Capture the scanned barcode, classify the product properly, and prepare variant combinations before saving.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroTag(
                  label: 'Mode',
                  value: controller.isEdit ? 'Edit' : 'Create',
                ),
                _HeroTag(
                  label: 'Product Type',
                  value: controller.showVariantSection ? 'Variant' : 'Simple',
                ),
                _HeroTag(
                  label: 'Photos',
                  value: '${controller.selectedPhotos.length}',
                ),
                _HeroTag(
                  label: 'Barcode',
                  value: controller.barcodeController.text.trim().isEmpty
                      ? 'Pending'
                      : 'Ready',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInfoCard extends StatelessWidget {
  const _ReadOnlyInfoCard({
    required this.label,
    required this.icon,
    required this.value,
    this.preview,
  });

  final String label;
  final IconData icon;
  final String value;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E8E7)),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (preview != null) ...[const SizedBox(width: 12), preview!],
        ],
      ),
    );
  }
}

class _SearchableCategoryField extends StatelessWidget {
  const _SearchableCategoryField({
    required this.value,
    required this.label,
    required this.prefixIcon,
    required this.categories,
    this.onChanged,
    this.validator,
  });

  final int? value;
  final String label;
  final IconData prefixIcon;
  final List<CategoryModel> categories;
  final ValueChanged<int?>? onChanged;
  final String? Function(int?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final effectiveValue = field.value ?? value;
        final effectiveCategory = categories.firstWhereOrNull(
          (category) => category.id == effectiveValue,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onChanged == null
                    ? null
                    : () async {
                        final selectedId = await showModalBottomSheet<int>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _CategoryPickerSheet(
                            categories: categories,
                            selectedId: effectiveValue,
                          ),
                        );
                        if (selectedId == null) {
                          return;
                        }
                        field.didChange(selectedId);
                        onChanged?.call(selectedId);
                      },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFCFD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: field.hasError
                          ? Theme.of(context).colorScheme.error
                          : const Color(0xFFD8E0E8),
                      width: field.hasError ? 1.2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        prefixIcon,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              effectiveCategory?.name ?? 'Select category',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: effectiveCategory == null
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.search_rounded, size: 20),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
  });

  final List<CategoryModel> categories;
  final int? selectedId;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late final TextEditingController searchController;
  String query = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCategories = widget.categories
        .where((category) {
          final name = (category.name ?? 'Category ${category.id}')
              .toLowerCase();
          return query.isEmpty || name.contains(query.toLowerCase());
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          top: 12,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E0E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      query = value.trim();
                    });
                  },
                  decoration: _inputDecoration(
                    context,
                    label: 'Search category',
                    prefixIcon: Icons.search_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: filteredCategories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No categories found.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredCategories.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            final isSelected = category.id == widget.selectedId;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              title: Text(
                                category.name ?? 'Category ${category.id}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded)
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pop(category.id),
                            );
                          },
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

class _VariantSection extends StatelessWidget {
  const _VariantSection({required this.controller});

  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _FormSection(
      title: 'Variants',
      subtitle:
          'Define attributes first, then review every generated combination before you save.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create attributes and values, then review the generated combinations and opening quantities.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _VariantMetaPill(
                label: 'Attributes',
                value: '${controller.variantAttributeCount}',
              ),
              _VariantMetaPill(
                label: 'Combinations',
                value: '${controller.variantCombinationCount}',
              ),
              _VariantMetaPill(
                label: 'State',
                value: controller.hasIncompleteVariantRows
                    ? 'Needs input'
                    : controller.hasDuplicateVariantNames
                    ? 'Duplicate names'
                    : 'Ready',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _VariantStepCard(
            step: 'Step 1',
            title: 'Attributes',
            description:
                'Use clear business names such as Size, Color, Storage, or Pack Type. Values should be comma separated.',
          ),
          const SizedBox(height: 12),
          ...controller.variantAttributes.map(
            (attribute) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VariantAttributeCard(
                attribute: attribute,
                controller: controller,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.addVariantAttribute,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Attribute'),
          ),
          if (controller.variantErrorMessage.value != null) ...[
            const SizedBox(height: 14),
            _InlineErrorMessage(message: controller.variantErrorMessage.value!),
          ],
          if (controller.variantCombinations.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _VariantStepCard(
              step: 'Step 2',
              title: 'Generated combinations',
              description:
                  'Review opening quantity and per-variant prices for every combination. These values become the backend payload.',
            ),
            const SizedBox(height: 12),
            Text(
              'Generated combinations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...controller.variantCombinations.map(
              (combination) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VariantCombinationCard(
                  combinationKey: combination.key,
                  label: combination.label,
                  quantity: combination.quantity,
                  quantityController: controller.combinationQuantityController(
                    combination.key,
                  ),
                  purchasePriceController: controller
                      .combinationPurchasePriceController(combination.key),
                  sellingPriceController: controller
                      .combinationSellingPriceController(combination.key),
                  onQuantityChanged: controller.updateCombinationQuantity,
                  onPurchasePriceChanged:
                      controller.updateCombinationPurchasePrice,
                  onSellingPriceChanged:
                      controller.updateCombinationSellingPrice,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantAttributeCard extends StatelessWidget {
  const _VariantAttributeCard({
    required this.attribute,
    required this.controller,
  });

  final EditableVariantAttribute attribute;
  final ProductFormController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.attributeNameController(attribute.id),
                  focusNode: controller.attributeNameFocusNode(attribute.id),
                  onChanged: (value) => controller.updateVariantAttributeName(
                    attribute.id,
                    value,
                  ),
                  decoration: _inputDecoration(
                    context,
                    label: 'Attribute Name',
                    prefixIcon: Icons.tune_rounded,
                  ).copyWith(helperText: 'Example: Color, Size, Storage'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () => controller.removeVariantAttribute(attribute.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (attribute.values.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attribute.values
                    .map(
                      (value) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (attribute.values.isNotEmpty) const SizedBox(height: 12),
          TextFormField(
            controller: controller.attributeValuesController(attribute.id),
            focusNode: controller.attributeValuesFocusNode(attribute.id),
            onChanged: (value) =>
                controller.updateVariantAttributeValues(attribute.id, value),
            decoration: _inputDecoration(
              context,
              label: 'Values',
              prefixIcon: Icons.list_alt_rounded,
            ).copyWith(helperText: 'Enter comma-separated values'),
          ),
        ],
      ),
    );
  }
}

class _VariantCombinationCard extends StatelessWidget {
  const _VariantCombinationCard({
    required this.combinationKey,
    required this.label,
    required this.quantity,
    required this.quantityController,
    required this.purchasePriceController,
    required this.sellingPriceController,
    required this.onQuantityChanged,
    required this.onPurchasePriceChanged,
    required this.onSellingPriceChanged,
  });

  final String combinationKey;
  final String label;
  final int quantity;
  final TextEditingController quantityController;
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;
  final void Function(String key, String value) onQuantityChanged;
  final void Function(String key, String value) onPurchasePriceChanged;
  final void Function(String key, String value) onSellingPriceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.isEmpty ? combinationKey : label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            combinationKey,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _VariantMetaPill(label: 'Opening Qty', value: '$quantity'),
              _VariantMetaPill(
                label: 'Key',
                value: label.isEmpty ? 'Generated' : 'Named',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: quantityController,
                  key: ValueKey('variant-$combinationKey-qty'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      onQuantityChanged(combinationKey, value),
                  decoration: _inputDecoration(
                    context,
                    label: 'Qty',
                    prefixIcon: Icons.inventory_2_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: purchasePriceController,
                  key: ValueKey('variant-$combinationKey-purchase-price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) =>
                      onPurchasePriceChanged(combinationKey, value),
                  decoration: _inputDecoration(
                    context,
                    label: 'Buy Price',
                    prefixIcon: Icons.payments_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: sellingPriceController,
                  key: ValueKey('variant-$combinationKey-selling-price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) =>
                      onSellingPriceChanged(combinationKey, value),
                  decoration: _inputDecoration(
                    context,
                    label: 'Sell Price',
                    prefixIcon: Icons.sell_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantMetaPill extends StatelessWidget {
  const _VariantMetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VariantStepCard extends StatelessWidget {
  const _VariantStepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
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
    this.helperText,
  });

  final T? value;
  final String label;
  final IconData prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String? helperText;

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
      ).copyWith(helperText: helperText),
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
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
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
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData prefixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
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
