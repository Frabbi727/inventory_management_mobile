import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../utils/home_route_resolver.dart';

class SplashController extends GetxController {
  SplashController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required UserStorage userStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       _userStorage = userStorage;

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final UserStorage _userStorage;

  final statusMessage = 'Checking session...'.obs;

  @override
  void onReady() {
    super.onReady();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      await _finishWithRoute(AppRoutes.login);
      return;
    }

    try {
      statusMessage.value = 'Restoring account...';
      final profile = await _authRepository.getCurrentProfile(token);
      final user = profile.data;

      if (user?.id == null) {
        await _clearSessionAndGoToLogin();
        return;
      }

      await _userStorage.saveUser(user!);
      await _authRepository.registerCurrentDeviceForSession(token);
      await _finishWithRoute(resolveHomeRouteForUser(user));
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearSessionAndGoToLogin();
        return;
      }

      await _clearSessionAndGoToLogin();
    } catch (_) {
      await _clearSessionAndGoToLogin();
    }
  }

  Future<void> _clearSessionAndGoToLogin() async {
    await _tokenStorage.clearToken();
    await _userStorage.clearUser();
    await _finishWithRoute(AppRoutes.login);
  }

  Future<void> _finishWithRoute(String route) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    Get.offAllNamed(route);
  }
}
