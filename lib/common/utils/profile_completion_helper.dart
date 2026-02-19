import 'package:get/get.dart';
import 'package:shortzz/model/user_model/user_model.dart';

class ProfileCompletionHelper {
  ProfileCompletionHelper._();

  static bool isProfileComplete(User? user) {
    return missingFields(user).isEmpty;
  }

  static List<String> missingFields(User? user) {
    if (user == null) {
      return const <String>[
        'full name',
        'username',
        'bio',
        'email',
        'phone number',
        'profile image'
      ];
    }

    final missing = <String>[];
    final fullName = user.fullname?.trim() ?? '';
    final username = user.username?.trim() ?? '';
    final bio = user.bio?.trim() ?? '';
    final email = user.userEmail?.trim() ?? '';
    final phone = user.userMobileNo?.trim() ?? '';
    final profilePhoto = user.profilePhoto?.trim() ?? '';

    if (fullName.isEmpty) {
      missing.add('full name');
    }
    if (username.isEmpty) {
      missing.add('username');
    }
    if (bio.isEmpty) {
      missing.add('bio');
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      missing.add('email');
    }
    if (phone.isEmpty) {
      missing.add('phone number');
    }
    if (profilePhoto.isEmpty) {
      missing.add('profile image');
    }

    return missing;
  }
}

