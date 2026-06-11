import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/models/allocation_model.dart';
import '../../data/repositories/allocation_repository.dart';

class AllocationController extends GetxController {
  AllocationController({required AllocationRepository allocationRepository})
      : _repository = allocationRepository;

  final AllocationRepository _repository;

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
      final result =
          await _repository.fetchMyAllocations(status: 'active');
      allocations.assignAll(result);

      if (activeAllocationId.value == null && result.isNotEmpty) {
        final active = result.firstWhereOrNull((a) => a.isActive);
        if (active != null) {
          await selectAllocation(active.id);
        }
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Failed to load allocations.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAllocation(int id) async {
    isRefreshing.value = true;
    errorMessage.value = null;
    try {
      final detail = await _repository.fetchAllocationDetails(id);
      activeAllocationId.value = detail.id;
      activeAllocationNo.value = detail.allocationNo;
      activeAllocationItems.assignAll(detail.items ?? []);
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
      activeAllocationItems.assignAll(detail.items ?? []);
    } catch (_) {
      // silent refresh — don't surface error to user
    }
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
