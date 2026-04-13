import '../../../products/data/models/product_model.dart';

class BarcodeScanArgs {
  const BarcodeScanArgs({required this.context});

  final BarcodeScanContext context;
}

enum BarcodeScanContext { productLookup, purchaseLookup, salesOrderLookup }

class BarcodeScanResult {
  const BarcodeScanResult({required this.barcode, this.product});

  final String barcode;
  final ProductModel? product;
}
