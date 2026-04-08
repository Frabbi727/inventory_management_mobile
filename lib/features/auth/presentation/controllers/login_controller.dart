import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../data/models/login_request_model.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends GetxController {
  LoginController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required UserStorage userStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       _userStorage = userStorage;

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final UserStorage _userStorage;

  final formKey = GlobalKey<FormState>();
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  String? validateLogin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Login is required.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    return null;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> submitLogin() async {
    final currentState = formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _authRepository.login(
        LoginRequestModel(
          login: loginController.text.trim(),
          password: passwordController.text,
          deviceName: 'flutter-mobile',
        ),
      );

      final token = response.data?.token;
      final user = response.data?.user;

      if (token == null || token.isEmpty || user == null) {
        errorMessage.value = 'Login response was incomplete.';
        return;
      }

      await _tokenStorage.saveToken(token);
      await _userStorage.saveUser(user);
      Get.offAllNamed(AppRoutes.home);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to sign in right now.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
