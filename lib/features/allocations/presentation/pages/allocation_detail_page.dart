import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/allocation_model.dart';
import '../controllers/allocation_controller.dart';

class AllocationDetailPage extends GetView<AllocationController> {
  const AllocationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final viewOnly = args?['viewOnly'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Obx(() {
          final no = viewOnly
              ? controller.viewAllocationNo.value
              : controller.activeAllocationNo.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewOnly ? 'Trip History' : 'Trip Details',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
              if (no != null)
                Text(
                  no,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          );
        }),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: viewOnly
            ? []
            : [
                Obx(() => controller.isRefreshing.value
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: controller.refreshActiveAllocation,
                        tooltip: 'Refresh',
                      )),
              ],
      ),
      body: Obx(() {
        final items = viewOnly
            ? controller.viewAllocationItems
            : controller.activeAllocationItems;

        if (controller.isRefreshing.value && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasData = viewOnly
            ? controller.viewAllocationId.value != null
            : controller.hasActiveAllocation;

        if (!hasData) {
          return const _NoAllocationState();
        }

        final withStock = items.where((i) => !i.isFullyAccounted).toList();
        final soldOut = items.where((i) => i.isFullyAccounted).toList();

        return RefreshIndicator(
          onRefresh: controller.refreshActiveAllocation,
          child: CustomScrollView(
            slivers: [
              // View-only banner
              if (viewOnly)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFFF7ED),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Row(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Text(
                          'This trip has ended — view only',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Summary header
              SliverToBoxAdapter(
                child: _SummaryHeader(items: items),
              ),
              // Available stock section
              if (withStock.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _SectionLabel(
                    label: 'Available Stock',
                    color: Color(0xFF059669),
                    dotColor: Color(0xFF10B981),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: withStock.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ItemCard(item: withStock[index], isSoldOut: false),
                  ),
                ),
              ],
              // Sold out / accounted section
              if (soldOut.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    label: 'Fully Accounted (${soldOut.length})',
                    color: const Color(0xFF94A3B8),
                    dotColor: const Color(0xFFCBD5E1),
                    topPadding: withStock.isNotEmpty ? 20 : 0,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: soldOut.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ItemCard(item: soldOut[index], isSoldOut: true),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.color,
    required this.dotColor,
    this.topPadding = 0,
  });
  final String label;
  final Color color;
  final Color dotColor;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16 + topPadding, 16, 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.items});
  final List<AllocationItemModel> items;

  static String _fmtQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final totalAllocated =
        items.fold(0.0, (s, i) => s + i.quantityAllocated);
    final totalSold = items.fold(0.0, (s, i) => s + i.quantitySold);
    final totalReturned =
        items.fold(0.0, (s, i) => s + i.quantityReturned);
    final totalRemaining =
        items.fold(0.0, (s, i) => s + i.remainingQuantity);
    final withStock =
        items.where((i) => !i.isFullyAccounted).length;
    final soldRatio = totalAllocated > 0
        ? (totalSold / totalAllocated).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _SumStat(
                  label: 'Allocated',
                  value: _fmtQty(totalAllocated),
                  color: const Color(0xFF475569),
                ),
              ),
              Expanded(
                child: _SumStat(
                  label: 'Sold',
                  value: _fmtQty(totalSold),
                  color: const Color(0xFF059669),
                ),
              ),
              Expanded(
                child: _SumStat(
                  label: 'Remaining',
                  value: _fmtQty(totalRemaining),
                  color: totalRemaining > 0
                      ? const Color(0xFF1A237E)
                      : const Color(0xFF94A3B8),
                ),
              ),
              if (totalReturned > 0)
                Expanded(
                  child: _SumStat(
                    label: 'Returned',
                    value: _fmtQty(totalReturned),
                    color: const Color(0xFF0284C7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(soldRatio * 100).toStringAsFixed(0)}% sold out',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
              Text(
                '$withStock of ${items.length} products with stock',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: const Color(0xFFF1F5F9)),
                FractionallySizedBox(
                  widthFactor: soldRatio,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF059669),
                          Color(0xFF34D399),
                        ],
                      ),
                    ),
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

class _SumStat extends StatelessWidget {
  const _SumStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

// ─── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.isSoldOut});
  final AllocationItemModel item;
  final bool isSoldOut;

  static String _fmtQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final remaining = item.remainingQuantity;
    final soldRatio = item.quantityAllocated > 0
        ? (item.quantitySold / item.quantityAllocated).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSoldOut
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFD1FAE5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left stripe
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isSoldOut
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF059669),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name + done badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.productNameSnapshot,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'PlusJakartaSans',
                              color: isSoldOut
                                  ? const Color(0xFFADB8C9)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isSoldOut) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quantity pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatPill(
                          label: 'Alloc',
                          value: _fmtQty(item.quantityAllocated),
                          bg: const Color(0xFFF8FAFC),
                          fg: const Color(0xFF64748B),
                        ),
                        _StatPill(
                          label: 'Sold',
                          value: _fmtQty(item.quantitySold),
                          bg: item.quantitySold > 0
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF8FAFC),
                          fg: item.quantitySold > 0
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                        ),
                        _StatPill(
                          label: 'Left',
                          value: _fmtQty(remaining),
                          bg: isSoldOut
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFFEFF6FF),
                          fg: isSoldOut
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF1D4ED8),
                          bold: true,
                        ),
                        if (item.quantityReturned > 0)
                          _StatPill(
                            label: 'Ret',
                            value: _fmtQty(item.quantityReturned),
                            bg: const Color(0xFFE0F2FE),
                            fg: const Color(0xFF0284C7),
                          ),
                      ],
                    ),
                    // Mini progress bar (only when not sold out)
                    if (!isSoldOut && item.quantityAllocated > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: Stack(
                          children: [
                            Container(
                              height: 4,
                              color: const Color(0xFFF1F5F9),
                            ),
                            FractionallySizedBox(
                              widthFactor: soldRatio,
                              child: Container(
                                height: 4,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: fg,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: fg.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No allocation state ──────────────────────────────────────────────────────

class _NoAllocationState extends StatelessWidget {
  const _NoAllocationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active trip',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'PlusJakartaSans',
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your admin to dispatch an allocation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: Get.back, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
