import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class InventoryHomeController extends GetxController {
  InventoryHomeController({
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

  Future<void> _loadUser() async {
    user.value = await _userStorage.getUser();
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  Future<void> logout() async {
    isLoggingOut.value = true;

    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await _authRepository.logout(token);
      }
    } catch (_) {
      // Local session cleanup is still required even if remote logout fails.
    } finally {
      await _tokenStorage.clearToken();
      await _userStorage.clearUser();
      isLoggingOut.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
