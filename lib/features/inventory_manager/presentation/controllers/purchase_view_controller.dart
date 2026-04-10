import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/purchase_response_model.dart';
import '../../data/repositories/inventory_manager_repository.dart';

class PurchaseViewController extends GetxController {
  PurchaseViewController({
    required InventoryManagerRepository inventoryManagerRepository,
  }) : _inventoryManagerRepository = inventoryManagerRepository;

  final InventoryManagerRepository _inventoryManagerRepository;

  final purchase = Rxn<PurchaseResponseModel>();
  final isLoading = true.obs;
  final errorMessage = RxnString();

  late final int purchaseId;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is! int) {
      throw ArgumentError('PurchaseViewController requires a purchase id.');
    }

    purchaseId = argument;
    loadPurchase();
  }

  Future<void> loadPurchase() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      purchase.value = await _inventoryManagerRepository.fetchPurchaseDetails(
        purchaseId,
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load purchase details right now.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openEditPurchase() async {
    final result = await Get.toNamed(
      AppRoutes.inventoryPurchaseEdit,
      arguments: purchaseId,
    );

    if (result == true) {
      await loadPurchase();
    }
  }

  String formatDate(String? value) {
    final parsed = value == null || value.isEmpty ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return value ?? '-';
    }

    final month = _monthLabel(parsed.month);
    return '${parsed.day.toString().padLeft(2, '0')} $month ${parsed.year}';
  }

  String formatDateTime(String? value) {
    final parsed = value == null || value.isEmpty ? null : DateTime.tryParse(value);
    if (parsed == null) {
      return value ?? '-';
    }

    final month = _monthLabel(parsed.month);
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day.toString().padLeft(2, '0')} $month ${parsed.year}, $hour:$minute';
  }

  String formatCurrency(num? value) {
    final amount = (value ?? 0).toDouble().toStringAsFixed(2);
    return '৳$amount';
  }

  String _monthLabel(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
