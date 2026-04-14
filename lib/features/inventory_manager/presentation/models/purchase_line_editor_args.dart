import '../../../products/data/models/product_model.dart';
import 'purchase_draft_item.dart';

class PurchaseLineEditorArgs {
  const PurchaseLineEditorArgs({required this.product, this.initialItem});

  final ProductModel product;
  final PurchaseDraftItem? initialItem;
}
