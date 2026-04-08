import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/home_binding.dart';
import '../../features/auth/presentation/bindings/login_binding.dart';
import '../../features/auth/presentation/bindings/splash_binding.dart';
import '../../features/auth/presentation/pages/home_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage<SplashScreen>(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: SplashBinding(),
    ),
    GetPage<LoginScreen>(
      name: AppRoutes.login,
      page: LoginScreen.new,
      binding: LoginBinding(),
    ),
    GetPage<HomeScreen>(
      name: AppRoutes.home,
      page: HomeScreen.new,
      binding: HomeBinding(),
    ),
  ];
}
