import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/allocation_controller.dart';
import '../../data/models/allocation_model.dart';
import 'allocation_detail_page.dart';

class AllocationListPage extends GetView<AllocationController> {
  const AllocationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoading.value &&
          (controller.errorMessage.value != null ||
              controller.allocations.isEmpty)) {
        controller.loadAllocations();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('My Allocations'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null &&
            controller.allocations.isEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value!,
            onRetry: controller.loadAllocations,
          );
        }

        if (controller.allocations.isEmpty) {
          return _EmptyState(onRefresh: controller.loadAllocations);
        }

        return RefreshIndicator(
          onRefresh: controller.loadAllocations,
          child: CustomScrollView(
            slivers: [
              // Hero card for currently active allocation
              SliverToBoxAdapter(
                child: _ActiveHeroCard(
                  controller: controller,
                ),
              ),
              // Allocation cards with section labels
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: Builder(
                  builder: (context) {
                    final allocs = controller.allocations;
                    final List<dynamic> rows = [];
                    bool historyAdded = false;
                    for (int i = 0; i < allocs.length; i++) {
                      if (i == 0 && allocs[i].isUsableForSelling) {
                        rows.add('_active');
                      }
                      if (!historyAdded && !allocs[i].isUsableForSelling) {
                        rows.add('_history');
                        historyAdded = true;
                      }
                      rows.add(allocs[i]);
                    }
                    return SliverList.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final item = rows[index];
                        if (item is String) {
                          return _SectionLabel(
                            label: item == '_active'
                                ? 'Active Trips'
                                : 'Trip History',
                          );
                        }
                        final allocation = item as AllocationModel;
                        final isSelected =
                            controller.activeAllocationId.value == allocation.id;
                        final isLocked = !allocation.isUsableForSelling;
                        final isNextLabel = index < rows.length - 1 &&
                            rows[index + 1] is String;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isNextLabel ? 0 : 10,
                          ),
                          child: _AllocationCard(
                            allocation: allocation,
                            isSelected: isSelected,
                            isLoading:
                                controller.isRefreshing.value && isSelected,
                            onTap: isLocked
                                ? () async {
                                    await controller
                                        .loadForViewing(allocation.id);
                                    if (context.mounted) {
                                      Get.to(
                                        () => const AllocationDetailPage(),
                                        arguments: {'viewOnly': true},
                                      );
                                    }
                                  }
                                : () async {
                                    await controller
                                        .selectAllocation(allocation.id);
                                    if (context.mounted) Get.back();
                                  },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Active allocation hero ───────────────────────────────────────────────────

class _ActiveHeroCard extends StatelessWidget {
  const _ActiveHeroCard({required this.controller});
  final AllocationController controller;

  static String _fmtQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

  static String _fmtDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt).inDays;
      if (diff == 0) return 'Dispatched today';
      if (diff == 1) return 'Dispatched yesterday';
      if (diff < 7) return 'Dispatched $diff days ago';
      return 'Dispatched ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = controller.activeAllocationId.value;
    if (selectedId == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: _NoActiveBanner(),
      );
    }

    // Only show the hero for allocations that are actually usable for selling.
    // If the selected allocation is returned/partial_return, show the banner instead.
    final active = controller.allocations.firstWhereOrNull(
      (a) => a.id == selectedId && a.isUsableForSelling,
    );
    if (active == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: _NoActiveBanner(),
      );
    }

    final items = controller.activeAllocationItems;
    final totalRemaining = items.fold(0.0, (s, i) => s + i.remainingQuantity);
    final totalSold = items.fold(0.0, (s, i) => s + i.quantitySold);
    final totalAllocated = items.fold(0.0, (s, i) => s + i.quantityAllocated);
    final soldRatio =
        totalAllocated > 0 ? (totalSold / totalAllocated).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge row
            Row(
              children: [
                _GreenPulseBadge(label: 'IN USE'),
                const Spacer(),
                const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white30,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Allocation number
            Text(
              active.allocationNo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'PlusJakartaSans',
                letterSpacing: -0.5,
              ),
            ),
            if (active.dispatchedAt != null) ...[
              const SizedBox(height: 3),
              Text(
                _fmtDate(active.dispatchedAt),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 18),
            // Stats
            if (items.isNotEmpty) ...[
              Row(
                children: [
                  _HeroStat(
                    label: 'Available',
                    value: _fmtQty(totalRemaining),
                    accent: const Color(0xFF6EE7B7),
                  ),
                  const SizedBox(width: 20),
                  _HeroStat(
                    label: 'Sold',
                    value: _fmtQty(totalSold),
                    accent: const Color(0xFF93C5FD),
                  ),
                  const SizedBox(width: 20),
                  _HeroStat(
                    label: 'Products',
                    value: '${items.length}',
                    accent: Colors.white60,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(soldRatio * 100).toStringAsFixed(0)}% sold',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_fmtQty(totalRemaining)} remaining',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Stack(
                      children: [
                        Container(
                          height: 5,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: soldRatio,
                          child: Container(
                            height: 5,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Loading details…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GreenPulseBadge extends StatelessWidget {
  const _GreenPulseBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NoActiveBanner extends StatelessWidget {
  const _NoActiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No active allocation selected. Tap one below to activate.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Allocation card ──────────────────────────────────────────────────────────

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.allocation,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final AllocationModel allocation;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return 'Not dispatched';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff <= 3) return '$diff days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = allocation.displayStatus;
    final isLocked = !allocation.isUsableForSelling;
    final itemCount = allocation.items?.length ?? 0;

    // Status chip config based on display_status from server
    _StatusChip? chip;
    if (isSelected && !isLocked) {
      chip = const _StatusChip(
        label: 'IN USE',
        bg: Color(0xFFE8EAF6),
        fg: Color(0xFF1A237E),
        dot: Color(0xFF1A237E),
      );
    } else if (ds == 'partial_return') {
      chip = const _StatusChip(
        label: 'RETURN IN PROGRESS',
        bg: Color(0xFFFFF7ED),
        fg: Color(0xFFD97706),
        dot: Color(0xFFF59E0B),
      );
    } else if (ds == 'returned') {
      chip = const _StatusChip(
        label: 'RETURNED',
        bg: Color(0xFFFFF1F2),
        fg: Color(0xFFBE123C),
        dot: Color(0xFFE11D48),
      );
    } else if (ds == 'completed') {
      chip = const _StatusChip(
        label: 'CLOSED',
        bg: Color(0xFFF1F5F9),
        fg: Color(0xFF64748B),
        dot: Color(0xFF94A3B8),
      );
    } else if (ds == 'new') {
      chip = const _StatusChip(
        label: 'NEW',
        bg: Color(0xFFEFF6FF),
        fg: Color(0xFF1D4ED8),
        dot: Color(0xFF3B82F6),
      );
    }

    return Opacity(
      opacity: isLocked ? 0.65 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected && !isLocked
                ? const Color(0xFF1A237E)
                : const Color(0xFFE2E8F0),
            width: isSelected && !isLocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected && !isLocked
                  ? const Color(0xFF1A237E).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected && !isLocked ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isLoading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected && !isLocked
                          ? const Color(0xFFE8EAF6)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: isSelected && !isLocked
                          ? const Color(0xFF1A237E)
                          : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                allocation.allocationNo,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'PlusJakartaSans',
                                  color: isSelected && !isLocked
                                      ? const Color(0xFF1A237E)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            ?chip,
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (isLocked)
                          const Text(
                            'Tap to view trip details',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _fmtDate(allocation.dispatchedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            if (itemCount > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.grid_view_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$itemCount product${itemCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right action
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.dot,
  });
  final String label;
  final Color bg;
  final Color fg;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Empty / error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active allocations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'PlusJakartaSans',
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your admin to dispatch an allocation for you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
