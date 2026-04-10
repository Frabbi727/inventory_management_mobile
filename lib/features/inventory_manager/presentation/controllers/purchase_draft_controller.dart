import 'package:get/get.dart';

import '../../../products/data/models/product_model.dart';
import '../../data/models/purchase_response_item_model.dart';
import '../../data/models/purchase_response_model.dart';
import '../models/purchase_draft_item.dart';

class PurchaseDraftController extends GetxController {
  final items = <PurchaseDraftItem>[].obs;
  final purchaseId = RxnInt();
  final purchaseNo = RxnString();
  final purchaseDate = DateTime.now().obs;
  final note = ''.obs;
  final isSubmitting = false.obs;

  bool get isEditingPurchase => purchaseId.value != null;

  PurchaseDraftItem? findDraftItem(int productId) {
    return items.firstWhereOrNull((item) => item.productId == productId);
  }

  bool hasItem(int productId) => findDraftItem(productId) != null;

  void addOrUpdateItem({
    required ProductModel product,
    required int quantity,
    required double unitCost,
  }) {
    final productId = product.id;
    if (productId == null) {
      return;
    }

    final nextItem = PurchaseDraftItem(
      productId: productId,
      name: product.name ?? 'Unnamed product',
      barcode: product.barcode ?? '-',
      quantity: quantity,
      unitCost: unitCost,
      currentStock: product.currentStock ?? 0,
      categoryName: product.category?.name ?? '-',
    );

    final existingIndex = items.indexWhere(
      (item) => item.productId == productId,
    );
    if (existingIndex == -1) {
      items.add(nextItem);
      return;
    }

    items[existingIndex] = nextItem;
    items.refresh();
  }

  void removeItem(int productId) {
    items.removeWhere((item) => item.productId == productId);
  }

  void setPurchaseHeader({
    required DateTime purchaseDateValue,
    required String noteValue,
  }) {
    purchaseDate.value = purchaseDateValue;
    note.value = noteValue;
  }

  void beginSubmit() {
    isSubmitting.value = true;
  }

  void endSubmit() {
    isSubmitting.value = false;
  }

  void loadFromPurchaseResponse(PurchaseResponseModel purchase) {
    purchaseId.value = purchase.id;
    purchaseNo.value = purchase.purchaseNo;
    purchaseDate.value =
        DateTime.tryParse(purchase.purchaseDate ?? '') ?? DateTime.now();
    note.value = purchase.note ?? '';
    items.assignAll(
      (purchase.items ?? const <PurchaseResponseItemModel>[])
          .where((item) => item.productId != null)
          .map(
            (item) => PurchaseDraftItem(
              productId: item.productId!,
              name: item.product?.name ?? item.productName ?? 'Unnamed product',
              barcode: item.product?.barcode ?? item.productBarcode ?? '-',
              quantity: (item.quantity ?? 0).round(),
              unitCost: (item.unitCost ?? 0).toDouble(),
              currentStock: item.product?.currentStock ?? 0,
              categoryName: item.product?.category?.name ?? '-',
            ),
          )
          .toList(),
    );
  }

  void resetDraft() {
    items.clear();
    purchaseId.value = null;
    purchaseNo.value = null;
    purchaseDate.value = DateTime.now();
    note.value = '';
    isSubmitting.value = false;
  }

  double get draftTotal =>
      items.fold<double>(0, (sum, item) => sum + item.totalAmount);
}
