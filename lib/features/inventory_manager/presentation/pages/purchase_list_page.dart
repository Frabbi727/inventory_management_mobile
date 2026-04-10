import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/app_page_header.dart';
import '../controllers/purchase_list_controller.dart';

class PurchaseListPage extends GetView<PurchaseListController> {
  const PurchaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: ListView(
          children: [
            AppPageHeader(
              title: 'Purchases',
              subtitle:
                  'Prepare receiving items from search, category filters, and barcode scan using the same inventory flow.',
              trailing: FilledButton.icon(
                onPressed: controller.openNewPurchase,
                icon: const Icon(Icons.add),
                label: const Text('New Purchase'),
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
                      'Receiving preparation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the live product APIs to search by name, filter by category, review stock, and scan barcodes before submitting a purchase.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.openNewPurchase,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Start Receiving'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
