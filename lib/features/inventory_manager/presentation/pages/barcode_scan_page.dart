import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/barcode_scan_controller.dart';

class BarcodeScanPage extends GetView<BarcodeScanController> {
  const BarcodeScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.title)),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller.scannerController,
            builder: (context, state, _) {
              return IconButton(
                onPressed: controller.scannerController.toggleTorch,
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
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(controller.subtitle, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: controller.scannerController,
                        onDetect: controller.handleDetection,
                        errorBuilder: (context, error) {
                          return const _ScannerFallback(
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
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    controller.errorMessage.value!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (controller.hasDetectedBarcode.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: controller.resumeScanning,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Scan Again'),
                  ),
                ),
              TextField(
                controller: controller.barcodeController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Manual barcode entry',
                  hintText: 'Enter or paste barcode',
                  prefixIcon: Icon(Icons.qr_code_2),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: controller.resolveBarcode,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: controller.isResolving.value
                    ? null
                    : () => controller.resolveBarcode(
                        controller.barcodeController.text,
                      ),
                icon: controller.isResolving.value
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
      ),
    );
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
