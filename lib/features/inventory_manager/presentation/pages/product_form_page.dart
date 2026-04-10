import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../products/data/models/category_response_model.dart';
import '../../data/models/create_or_update_barcode_product_request.dart';
import '../../data/repositories/inventory_manager_repository.dart';

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
  late final TextEditingController _unitIdController;
  final _formKey = GlobalKey<FormState>();

  final List<CategoryModel> _categories = <CategoryModel>[];
  bool _isSubmitting = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;
  int? _selectedCategoryId;
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
    _unitIdController = TextEditingController(
      text: _args.unitId?.toString() ?? '',
    );
    _selectedCategoryId = _args.categoryId;
    _selectedStatus = _args.status ?? 'active';
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _minimumStockController.dispose();
    _unitIdController.dispose();
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
                onChanged: _isCategoriesLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                decoration: InputDecoration(
                  labelText: _isCategoriesLoading
                      ? 'Category (loading...)'
                      : 'Category',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Category is required.' : null,
              ),
              const SizedBox(height: 12),
              _FormField(
                controller: _unitIdController,
                label: 'Unit ID',
                keyboardType: TextInputType.number,
                validator: _requiredNumberField,
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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Photo upload is deferred in this pass. The form submits the barcode product fields first.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
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

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
    });

    try {
      final categories = await Get.find<InventoryManagerRepository>()
          .fetchCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(categories);
        _selectedCategoryId ??= _categories.isNotEmpty
            ? _categories.first.id
            : null;
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
          _isCategoriesLoading = false;
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
    if (categoryId == null) {
      setState(() {
        _errorMessage = 'Category is required.';
      });
      return;
    }

    final request = CreateOrUpdateBarcodeProductRequest(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      categoryId: categoryId,
      unitId: int.parse(_unitIdController.text.trim()),
      purchasePrice: num.parse(_purchasePriceController.text.trim()),
      sellingPrice: num.parse(_sellingPriceController.text.trim()),
      minimumStockAlert: int.parse(_minimumStockController.text.trim()),
      status: _selectedStatus,
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = Get.find<InventoryManagerRepository>();
      final product = _args.mode == ProductFormMode.edit
          ? await repository.updateProductByBarcode(
              _args.barcode ?? '',
              request,
            )
          : await repository.createProductFromBarcode(request);

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
