import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/models/barcode_resolve_response.dart';
import '../../data/repositories/inventory_manager_repository.dart';
import '../models/barcode_scan_models.dart';
import 'product_form_page.dart';

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isResolving = false;
  bool _hasDetectedBarcode = false;
  String? _errorMessage;
  BarcodeScanContext _context = BarcodeScanContext.productLookup;

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is BarcodeScanArgs) {
      _context = argument.context;
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _context == BarcodeScanContext.purchaseLookup
        ? 'Scan a barcode to add a product to the purchase draft.'
        : 'Scan a barcode to open an existing product or create a new one.';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _context == BarcodeScanContext.purchaseLookup
              ? 'Scan Purchase Item'
              : 'Scan Barcode',
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, _) {
              return IconButton(
                onPressed: _scannerController.toggleTorch,
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                tooltip: 'Toggle torch',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(subtitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleDetection,
                      errorBuilder: (context, error) {
                        return _ScannerFallback(
                          message:
                              'Camera access is not available. Use manual barcode entry below.',
                        );
                      },
                    ),
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        margin: const EdgeInsets.all(32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_hasDetectedBarcode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resumeScanning,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Scan Again'),
                ),
              ),
            TextField(
              controller: _barcodeController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Manual barcode entry',
                hintText: 'Enter or paste barcode',
                prefixIcon: Icon(Icons.qr_code_2),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _resolveBarcode(_barcodeController.text),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isResolving
                  ? null
                  : () => _resolveBarcode(_barcodeController.text),
              icon: _isResolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Resolve Barcode'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasDetectedBarcode || _isResolving) {
      return;
    }

    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (value.isEmpty) {
      return;
    }

    _barcodeController.text = value;
    await _resolveBarcode(value, fromCamera: true);
  }

  Future<void> _resolveBarcode(
    String rawBarcode, {
    bool fromCamera = false,
  }) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a barcode before continuing.';
      });
      return;
    }

    setState(() {
      _isResolving = true;
      _errorMessage = null;
      if (fromCamera) {
        _hasDetectedBarcode = true;
      }
    });

    await _scannerController.stop();

    try {
      if (_context == BarcodeScanContext.purchaseLookup) {
        Get.back(result: BarcodeScanResult(barcode: barcode));
        return;
      }

      final response = await Get.find<InventoryManagerRepository>()
          .resolveProductBarcode(barcode);
      await _handleProductLookupResponse(response);
    } catch (_) {
      setState(() {
        _errorMessage =
            'Unable to resolve this barcode right now. Try again or enter it manually.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _handleProductLookupResponse(
    BarcodeResolveResponse response,
  ) async {
    if (!mounted) {
      return;
    }

    if (response.exists && response.data != null) {
      Get.offNamed(AppRoutes.productDetails, arguments: response.data);
      return;
    }

    Get.offNamed(
      AppRoutes.inventoryProductForm,
      arguments: ProductFormArgs.create(barcode: response.barcode),
    );
  }

  Future<void> _resumeScanning() async {
    setState(() {
      _hasDetectedBarcode = false;
      _errorMessage = null;
    });
    await _scannerController.start();
  }
}

class _ScannerFallback extends StatelessWidget {
  const _ScannerFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
