import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../cart_orders/data/models/order_item_request_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/allocation_model.dart';
import '../../data/repositories/allocation_cache_repository.dart';
import '../../data/repositories/allocation_repository.dart';

class AllocationController extends GetxController {
  AllocationController({
    required AllocationRepository allocationRepository,
    required AllocationCacheRepository allocationCacheRepository,
  }) : _repository = allocationRepository,
       _cacheRepository = allocationCacheRepository;

  final AllocationRepository _repository;
  final AllocationCacheRepository _cacheRepository;

  final allocations = <AllocationModel>[].obs;
  final activeAllocationId = Rxn<int>();
  final activeAllocationNo = RxnString();
  final activeAllocationItems = <AllocationItemModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAllocations();
  }

  bool get hasActiveAllocation => activeAllocationId.value != null;

  List<ProductModel> get activeProducts => activeAllocationItems
      .where((item) => !item.isFullyAccounted)
      .map((item) => item.toProductModel())
      .toList();

  AllocationItemModel? getItemForProduct(int productId, {int? variantId}) {
    return activeAllocationItems.firstWhereOrNull(
      (item) =>
          item.productId == productId && item.productVariantId == variantId,
    );
  }

  double getRemainingQty(int productId, {int? variantId}) {
    return getItemForProduct(productId, variantId: variantId)
            ?.remainingQuantity ??
        0;
  }

  Future<void> loadAllocations() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchMyAllocations(status: 'active');
      allocations.assignAll(result);

      if (activeAllocationId.value == null && result.isNotEmpty) {
        final active = result.firstWhereOrNull((a) => a.isActive);
        if (active != null) {
          await selectAllocation(active.id);
        }
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      await _tryLoadFromCache();
    } catch (_) {
      errorMessage.value = 'Failed to load allocations.';
      await _tryLoadFromCache();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _tryLoadFromCache() async {
    final id = activeAllocationId.value;
    if (id == null) return;
    final cached = await _cacheRepository.getItems(id);
    if (cached.isNotEmpty) {
      activeAllocationItems.assignAll(cached);
      errorMessage.value = null;
    }
  }

  Future<void> selectAllocation(int id) async {
    isRefreshing.value = true;
    errorMessage.value = null;
    try {
      final detail = await _repository.fetchAllocationDetails(id);
      activeAllocationId.value = detail.id;
      activeAllocationNo.value = detail.allocationNo;
      final items = detail.items ?? [];
      activeAllocationItems.assignAll(items);
      await _cacheRepository.saveItems(detail.id, items);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Failed to load allocation details.';
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> refreshActiveAllocation() async {
    final id = activeAllocationId.value;
    if (id == null) return;
    try {
      final detail = await _repository.fetchAllocationDetails(id);
      final items = detail.items ?? [];
      activeAllocationItems.assignAll(items);
      await _cacheRepository.saveItems(id, items);
    } catch (_) {
      // silent refresh — don't surface error to user
    }
  }

  /// Optimistically decrements quantity_sold in both memory and SQLite cache
  /// after an offline order is queued, preventing overselling.
  Future<void> decrementLocalSold(List<OrderItemRequestModel> orderItems) async {
    final isOnline = Get.isRegistered<SyncManager>()
        ? Get.find<SyncManager>().isOnline.value
        : true;
    if (isOnline) return; // only needed for offline orders

    for (final orderItem in orderItems) {
      final productId = orderItem.productId;
      if (productId == null) continue;
      final qty = (orderItem.quantity ?? 0).toDouble();
      if (qty <= 0) continue;

      final allocationItem = getItemForProduct(
        productId,
        variantId: orderItem.productVariantId,
      );
      if (allocationItem == null) continue;

      await _cacheRepository.decrementSold(allocationItem.id, qty);

      final index = activeAllocationItems.indexWhere(
        (i) => i.id == allocationItem.id,
      );
      if (index != -1) {
        final item = activeAllocationItems[index];
        activeAllocationItems[index] = AllocationItemModel(
          id: item.id,
          productId: item.productId,
          productVariantId: item.productVariantId,
          productNameSnapshot: item.productNameSnapshot,
          unitPriceSnapshot: item.unitPriceSnapshot,
          quantityAllocated: item.quantityAllocated,
          quantitySold: item.quantitySold + qty,
          quantityReturned: item.quantityReturned,
          product: item.product,
          productVariant: item.productVariant,
        );
      }
    }
    activeAllocationItems.refresh();
  }

  void clearActiveAllocation() {
    activeAllocationId.value = null;
    activeAllocationNo.value = null;
    activeAllocationItems.clear();
  }

  Future<void> submitReturns({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final id = activeAllocationId.value;
    if (id == null) throw ApiException(message: 'No active allocation.');
    await _repository.submitReturns(
      allocationId: id,
      items: items,
      note: note,
    );
    await refreshActiveAllocation();
  }
}
