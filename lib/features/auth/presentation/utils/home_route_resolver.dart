import '../../../../core/routes/app_routes.dart';
import '../../data/models/user_model.dart';

String resolveHomeRouteForUser(UserModel user) {
  final roleSlug = (user.role?.slug ?? '').trim().toLowerCase();
  final roleName = (user.role?.name ?? '').trim().toLowerCase();

  if (roleSlug == 'inventory_manager' ||
      roleName == 'inventory_manager' ||
      roleName == 'inventory manager') {
    return AppRoutes.inventoryHome;
  }

  return AppRoutes.home;
}
