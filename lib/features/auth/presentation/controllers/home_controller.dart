import 'package:get/get.dart';

import '../../../../core/constants/controller_tags.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../customers/presentation/controllers/customer_search_controller.dart';
import '../../../invoice/presentation/controllers/invoice_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class HomeController extends GetxController {
  HomeController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required UserStorage userStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       _userStorage = userStorage;

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final UserStorage _userStorage;

  final user = Rxn<UserModel>();
  final isLoggingOut = false.obs;
  final selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  @override
  void onReady() {
    super.onReady();
    _loadTabData(selectedIndex.value);
  }

  Future<void> _loadUser() async {
    user.value = await _userStorage.getUser();
  }

  void changeTab(int index) {
    selectedIndex.value = index;
    _loadTabData(index);
  }

  void _loadTabData(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        if (Get.isRegistered<InvoiceController>()) {
          Get.find<InvoiceController>().ensureLoaded();
        }
        break;
      case 2:
        if (Get.isRegistered<CustomerSearchController>(
          tag: ControllerTags.homeCustomerSearch,
        )) {
          Get.find<CustomerSearchController>(
            tag: ControllerTags.homeCustomerSearch,
          ).retry();
        }
        break;
    }
  }

  Future<void> openNewOrder() async {
    await Get.toNamed(AppRoutes.newOrder);
  }

  Future<void> logout() async {
    isLoggingOut.value = true;

    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await _authRepository.logout(token);
      }
    } catch (_) {
      // Local session cleanup is still required even if the remote logout fails.
    } finally {
      await _tokenStorage.clearToken();
      await _userStorage.clearUser();
      isLoggingOut.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
