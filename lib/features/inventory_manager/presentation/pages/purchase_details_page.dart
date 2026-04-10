import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../products/data/models/product_model.dart';
import '../controllers/purchase_flow_controller.dart';

class PurchaseDetailsPage extends StatefulWidget {
  const PurchaseDetailsPage({super.key});

  @override
  State<PurchaseDetailsPage> createState() => _PurchaseDetailsPageState();
}

class _PurchaseDetailsPageState extends State<PurchaseDetailsPage> {
  late final ProductModel _product;
  late final PurchaseFlowController _purchaseFlowController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitCostController;
  late final TextEditingController _noteController;

  late DateTime _purchaseDate;
  String? _quantityError;
  String? _unitCostError;
  String? _submitError;

  int? get _quantity => int.tryParse(_quantityController.text.trim());
  double? get _unitCost => double.tryParse(_unitCostController.text.trim());

  double get _totalAmount {
    final quantity = _quantity;
    final unitCost = _unitCost;
    if (quantity == null || unitCost == null) {
      return 0;
    }
    return quantity * unitCost;
  }

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is! ProductModel) {
      throw ArgumentError(
        'PurchaseDetailsPage requires a ProductModel argument.',
      );
    }

    _product = argument;
    _purchaseFlowController = Get.find<PurchaseFlowController>();
    _purchaseDate = DateTime.now();
    _quantityController = TextEditingController(text: '1');
    _unitCostController = TextEditingController(
      text: ((_product.purchasePrice ?? 0).toDouble()).toStringAsFixed(2),
    );
    _noteController = TextEditingController();
    _quantityController.addListener(_handleInputChange);
    _unitCostController.addListener(_handleInputChange);
    _noteController.addListener(_handleInputChange);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_handleInputChange)
      ..dispose();
    _unitCostController
      ..removeListener(_handleInputChange)
      ..dispose();
    _noteController
      ..removeListener(_handleInputChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _submitError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.name ?? 'Unnamed product',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: 'SKU', value: _product.sku ?? '-'),
                        _InfoChip(
                          label: 'Barcode',
                          value: _product.barcode ?? '-',
                        ),
                        _InfoChip(
                          label: 'Stock',
                          value: '${_product.currentStock ?? 0}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receiving Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Purchase Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _purchaseFlowController.formatDate(_purchaseDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: _decreaseQuantity,
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: const OutlineInputBorder(),
                              errorText: _quantityError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.outlined(
                          onPressed: _increaseQuantity,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _unitCostController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Unit Cost',
                        prefixText: '৳',
                        border: const OutlineInputBorder(),
                        errorText: _unitCostError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '৳${_totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Obx(
            () => FilledButton(
              onPressed: _purchaseFlowController.isSubmitting.value
                  ? null
                  : _submitPurchase,
              child: _purchaseFlowController.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Purchase'),
            ),
          ),
        ),
      ),
    );
  }

  void _handleInputChange() {
    if (!mounted) {
      return;
    }

    setState(() {
      _quantityError = null;
      _unitCostError = null;
      _submitError = null;
    });
  }

  void _decreaseQuantity() {
    final quantity = _quantity ?? 1;
    if (quantity <= 1) {
      return;
    }
    _quantityController.text = '${quantity - 1}';
  }

  void _increaseQuantity() {
    final quantity = _quantity ?? 0;
    _quantityController.text = '${quantity + 1}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _purchaseDate = picked;
    });
  }

  Future<void> _submitPurchase() async {
    final result = await _purchaseFlowController.submitPurchase(
      product: _product,
      purchaseDate: _purchaseDate,
      note: _noteController.text,
      quantityText: _quantityController.text,
      unitCostText: _unitCostController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.validation != null) {
      setState(() {
        _quantityError = result.validation!.quantityError;
        _unitCostError = result.validation!.unitCostError;
      });
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _submitError = result.errorMessage;
      });
      return;
    }

    Get.back();
    Get.snackbar(
      'Purchase created',
      _purchaseFlowController.buildPurchaseSavedMessage(result.response!),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
