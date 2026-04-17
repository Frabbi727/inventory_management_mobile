import 'package:get/get.dart';

import 'notification_dependencies.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    NotificationDependencies.ensureRegistered();
  }
}
