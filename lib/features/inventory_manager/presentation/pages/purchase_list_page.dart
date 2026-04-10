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
                  'Prepare stock receiving and build purchase drafts from scanned products.',
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
                      'Purchase receiving flow',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan a product barcode, convert the result into a product selection, then capture quantity and unit cost in a receiving draft.',
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
                  'Saved purchase history is not yet exposed in this mobile build. This tab is focused on a clean receiving entry point for inventory staff.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
