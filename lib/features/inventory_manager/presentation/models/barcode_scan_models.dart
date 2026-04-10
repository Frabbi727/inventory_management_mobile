class BarcodeScanArgs {
  const BarcodeScanArgs({required this.context});

  final BarcodeScanContext context;
}

enum BarcodeScanContext { productLookup, purchaseLookup }

class BarcodeScanResult {
  const BarcodeScanResult({required this.barcode});

  final String barcode;
}
