import 'package:get/get.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/screen/auth_screen/login_screen.dart';
import 'package:shortzz/screen/auth_screen/registration_screen.dart';

class SwitchAccountController extends BaseController {
  void addAccount() {
    Get.to(() => const LoginScreen());
  }

  void createNewAccount() {
    Get.to(() => const RegistrationScreen());
  }

  void switchToAccount(String accountId) {
    // Implementation for switching between accounts
    Get.snackbar(
      'Switching Account',
      'Switching to selected account...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
