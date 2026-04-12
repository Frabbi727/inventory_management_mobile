import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_message_state.dart';
import '../../../../shared/widgets/app_remote_media.dart';
import '../../../../shared/widgets/product_stock_status_badge.dart';
import '../../data/models/product_model.dart';
import '../../../inventory_manager/presentation/models/product_form_args.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsPage extends GetView<ProductDetailsController> {
  const ProductDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Obx(() {
            final product = controller.product.value;
            if (!controller.isInventoryManager.value || product == null) {
              return const SizedBox.shrink();
            }

            return IconButton(
              onPressed: () {
                Get.toNamed(
                  AppRoutes.inventoryProductForm,
                  arguments: ProductFormArgs.edit(
                    productId: product.id,
                    name: product.name,
                    sku: product.sku,
                    barcode: product.barcode,
                    categoryId: product.category?.id,
                    subcategoryId: product.subcategory?.id,
                    unitId: product.unit?.id,
                    purchasePrice: product.purchasePrice,
                    sellingPrice: product.sellingPrice,
                    minimumStockAlert: product.minimumStockAlert,
                    status: product.status,
                    hasVariants: product.hasVariants,
                    variantAttributes: product.variantAttributes,
                    variants: product.variants,
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit product',
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.product.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null &&
              controller.product.value == null) {
            return AppMessageState(
              icon: Icons.cloud_off_outlined,
              message: controller.errorMessage.value!,
              actionLabel: 'Retry',
              onAction: () => controller.fetchProductDetails(),
            );
          }

          final product = controller.product.value;
          if (product == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchProductDetails(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _ProductGalleryCard(product: product),
                const SizedBox(height: 16),
                _OverviewCard(product: product, controller: controller),
                const SizedBox(height: 16),
                _SectionShell(
                  title: 'Inventory',
                  child: _InfoList(
                    items: [
                      _InfoItem(
                        label: 'Current stock',
                        value: controller.stockLabel(product),
                        icon: Icons.inventory_2_outlined,
                      ),
                      _InfoItem(
                        label: 'Minimum alert',
                        value: '${product.minimumStockAlert ?? 0}',
                        icon: Icons.notification_important_outlined,
                      ),
                      _InfoItem(
                        label: 'Category',
                        value: product.category?.name ?? '-',
                        icon: Icons.category_outlined,
                      ),
                      _InfoItem(
                        label: 'Subcategory',
                        value: product.subcategory?.name ?? '-',
                        icon: Icons.account_tree_outlined,
                      ),
                      _InfoItem(
                        label: 'Unit',
                        value: product.unit?.name ?? '-',
                        icon: Icons.straighten_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (product.hasVariants == true) ...[
                  _SectionShell(
                    title: 'Variants',
                    child: _VariantSection(
                      product: product,
                      controller: controller,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _SectionShell(
                  title: 'Barcode',
                  child: _BarcodeCard(product: product),
                ),
                const SizedBox(height: 16),
                _SectionShell(
                  title: 'Timeline',
                  child: _InfoList(
                    items: [
                      _InfoItem(
                        label: 'Created',
                        value: controller.formatDate(product.createdAt),
                        icon: Icons.event_available_outlined,
                      ),
                      _InfoItem(
                        label: 'Updated',
                        value: controller.formatDate(product.updatedAt),
                        icon: Icons.update_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ProductGalleryCard extends StatefulWidget {
  const _ProductGalleryCard({required this.product});

  final ProductModel product;

  @override
  State<_ProductGalleryCard> createState() => _ProductGalleryCardState();
}

class _ProductGalleryCardState extends State<_ProductGalleryCard> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.product.galleryPhotos;
    if (photos.isEmpty) {
      return _EmptyGalleryCard(productName: widget.product.name ?? 'Product');
    }

    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photo = photos[index];
                return AppCachedNetworkImage(
                  imageUrl: photo.fileUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: theme.colorScheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: _GalleryFallback(
                    productName: widget.product.name ?? 'Product',
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentIndex + 1} of ${photos.length} photo${photos.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (photos.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(photos.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isActive ? 20 : 8,
                        height: 8,
                        margin: EdgeInsets.only(
                          right: index == photos.length - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.product, required this.controller});

  final ProductModel product;
  final ProductDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = (product.status ?? '').toLowerCase() == 'active';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unnamed product',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SKU: ${product.sku ?? '-'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (product.hasVariants == true) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (product.variantSummary?.totalVariants != null)
                              _VariantSummaryPill(
                                label: 'Total',
                                value:
                                    '${product.variantSummary?.totalVariants ?? 0}',
                              ),
                            if (product.variantSummary?.inStockCount != null)
                              _VariantSummaryPill(
                                label: 'In stock',
                                value:
                                    '${product.variantSummary?.inStockCount ?? 0}',
                              ),
                            if (product.variantSummary?.lowStockCount != null)
                              _VariantSummaryPill(
                                label: 'Low',
                                value:
                                    '${product.variantSummary?.lowStockCount ?? 0}',
                              ),
                            if (product.variantSummary?.outOfStockCount != null)
                              _VariantSummaryPill(
                                label: 'Out',
                                value:
                                    '${product.variantSummary?.outOfStockCount ?? 0}',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDDF4E6)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.status ?? '-',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isActive
                              ? const Color(0xFF166534)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProductStockStatusBadge(
                      status: product.effectiveStockStatus,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PriceMetric(
                    label: 'Selling price',
                    value: controller.formatPrice(product.sellingPrice),
                    toneColor: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceMetric(
                    label: 'Purchase price',
                    value: controller.formatPrice(product.purchasePrice),
                    toneColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.product,
    required this.controller,
  });

  final ProductModel product;
  final ProductDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attributes = product.variantAttributes ?? const [];
    final variants = product.variants ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attributes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attributes
                .map(
                  (attribute) => _VariantSummaryPill(
                    label: attribute.name ?? 'Attribute',
                    value: (attribute.values ?? const []).join(', '),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
        ],
        ...variants.map(
          (variant) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.combinationLabel ?? variant.combinationKey ?? '-',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ((variant.combinationKey ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            variant.combinationKey!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ProductStockStatusBadge(
                        status: variant.stockStatus ?? product.effectiveStockStatus,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${variant.currentStock ?? 0} ${product.unit?.shortName ?? product.unit?.name ?? ''}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantSummaryPill extends StatelessWidget {
  const _VariantSummaryPill({
    required this.label,
    required this.value,
  });

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

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final barcodeImageUrl = product.barcodeImageUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.barcode ?? '-',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode value',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (barcodeImageUrl != null && barcodeImageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: AspectRatio(
                  aspectRatio: 3.2,
                  child: AppNetworkSvg(
                    url: barcodeImageUrl,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: Center(
                      child: Text(
                        'Unable to load barcode image.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  'No barcode image available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _InfoList extends StatelessWidget {
  const _InfoList({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _InfoTile(item: items[index]),
          if (index != items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceMetric extends StatelessWidget {
  const _PriceMetric({
    required this.label,
    required this.value,
    required this.toneColor,
  });

  final String label;
  final String value;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: toneColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _EmptyGalleryCard extends StatelessWidget {
  const _EmptyGalleryCard({required this.productName});

  final String productName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No photos available for $productName.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback({required this.productName});

  final String productName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            productName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
