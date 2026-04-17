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
    final previousIndex = selectedIndex.value;
    if (previousIndex == index) {
      return;
    }

    selectedIndex.value = index;
    _loadTabData(index);
  }

  void _loadTabData(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        if (Get.isRegistered<InvoiceController>()) {
          final invoiceController = Get.find<InvoiceController>();
          if (!invoiceController.hasLoadedOnce) {
            invoiceController.ensureLoaded();
          } else {
            invoiceController.onTabActivated();
          }
        }
        break;
      case 2:
        if (Get.isRegistered<CustomerSearchController>(
          tag: ControllerTags.homeCustomerSearch,
        )) {
          final customerController = Get.find<CustomerSearchController>(
            tag: ControllerTags.homeCustomerSearch,
          );
          if (!customerController.hasLoadedOnce) {
            customerController.ensureLoaded();
          } else {
            customerController.onTabActivated();
          }
        }
        break;
    }
  }

  Future<void> openNewOrder() async {
    await Get.toNamed(AppRoutes.newOrder);
  }

  Future<void> openOrdersTab({String status = 'draft'}) async {
    selectedIndex.value = 1;

    if (Get.isRegistered<InvoiceController>()) {
      final invoiceController = Get.find<InvoiceController>();
      if (invoiceController.activeStatusTab.value != status) {
        await invoiceController.changeStatusTab(status);
      } else {
        await invoiceController.retry();
      }
    }
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
