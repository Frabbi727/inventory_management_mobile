import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductDetailsController extends GetxController {
  ProductDetailsController({
    required ProductRepository productRepository,
    required UserStorage userStorage,
  }) : _productRepository = productRepository,
       _userStorage = userStorage;

  final ProductRepository _productRepository;
  final UserStorage _userStorage;

  final product = Rxn<ProductModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final isInventoryManager = false.obs;

  int? _productId;

  @override
  void onInit() {
    super.onInit();
    _loadRole();
    final argument = Get.arguments;
    if (argument is int) {
      _productId = argument;
      fetchProductDetails();
    } else if (argument is ProductModel) {
      product.value = argument;
      _productId = argument.id;
      if (_productId != null) {
        fetchProductDetails();
      }
    } else {
      errorMessage.value = 'Product details were not provided.';
    }
  }

  Future<void> _loadRole() async {
    final user = await _userStorage.getUser();
    final roleSlug = (user?.role?.slug ?? '').trim().toLowerCase();
    isInventoryManager.value = roleSlug == 'inventory_manager';
  }

  Future<void> fetchProductDetails({bool forceRefresh = false}) async {
    final productId = _productId;
    if (productId == null) {
      errorMessage.value = 'Product details were not provided.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _productRepository.fetchProductDetails(
        productId,
        forceRefresh: forceRefresh,
      );
      product.value = response.data;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load product details right now.';
    } finally {
      isLoading.value = false;
    }
  }

  String formatPrice(num? value) {
    if (value == null) {
      return '-';
    }

    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final normalized = value.split('T').first;
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }

    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  String stockLabel(ProductModel value) {
    final currentStock = value.currentStock;
    if (currentStock == null) {
      return 'Unknown';
    }

    final unitName = value.unit?.shortName ?? value.unit?.name ?? 'pcs';
    return '$currentStock $unitName';
  }
}
