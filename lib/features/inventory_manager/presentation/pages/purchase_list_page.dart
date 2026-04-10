import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_page_header.dart';

class PurchaseListPage extends StatelessWidget {
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
                  'Prepare receiving items from product search, category filters, and barcode scan. Final purchase save is still web-only.',
              trailing: FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.inventoryPurchaseCreate),
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
                      'Use the live product APIs to search by name, filter by category, review stock, and scan barcodes. Build a local purchase draft on mobile, then complete final save in web until the backend exposes purchase write APIs.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.inventoryPurchaseCreate),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Start Receiving'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Backend limitation: /api/inventory-manager/purchases does not exist yet. This tab only supports purchase preparation using product list and barcode lookup APIs.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
