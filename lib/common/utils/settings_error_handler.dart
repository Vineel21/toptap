import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsErrorHandler {
  static void showErrorSnackbar(String message, {Duration? duration}) {
    Get.snackbar(
      'Error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      icon: const Icon(Icons.error_outline, color: Colors.red),
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void showSuccessSnackbar(String message, {Duration? duration}) {
    Get.snackbar(
      'Success'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green,
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      duration: duration ?? const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void showWarningSnackbar(String message, {Duration? duration}) {
    Get.snackbar(
      'Warning'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: Colors.orange,
      icon: const Icon(Icons.warning_outlined, color: Colors.orange),
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static void showInfoSnackbar(String message, {Duration? duration}) {
    Get.snackbar(
      'Info'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.1),
      colorText: Colors.blue,
      icon: const Icon(Icons.info_outline, color: Colors.blue),
      duration: duration ?? const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  static String getNetworkErrorMessage() {
    return 'Network error occurred. Please check your connection and try again.'.tr;
  }

  static String getGenericErrorMessage() {
    return 'An unexpected error occurred. Please try again.'.tr;
  }

  static String getAuthenticationErrorMessage() {
    return 'Authentication failed. Please login again.'.tr;
  }

  static String getPermissionErrorMessage() {
    return 'Permission denied. Please check your account permissions.'.tr;
  }

  static String getValidationErrorMessage(String field) {
    return 'Please enter a valid \$field.'.tr;
  }

  static String getServerErrorMessage() {
    return 'Server error occurred. Please try again later.'.tr;
  }

  /// Handle different types of errors and show appropriate messages
  static void handleError(dynamic error, {String? customMessage}) {
    String message = customMessage ?? _parseErrorMessage(error);
    showErrorSnackbar(message);
  }

  static String _parseErrorMessage(dynamic error) {
    if (error == null) return getGenericErrorMessage();

    String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return getNetworkErrorMessage();
    }

    if (errorString.contains('authentication') || 
        errorString.contains('unauthorized') ||
        errorString.contains('auth')) {
      return getAuthenticationErrorMessage();
    }

    if (errorString.contains('permission') || 
        errorString.contains('forbidden')) {
      return getPermissionErrorMessage();
    }

    if (errorString.contains('server') || 
        errorString.contains('500') ||
        errorString.contains('internal')) {
      return getServerErrorMessage();
    }

    // Return the original error message if it's user-friendly
    if (error is String && error.length < 100) {
      return error;
    }

    return getGenericErrorMessage();
  }

  /// Show a loading dialog with error handling
  static Future<T?> withErrorHandling<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showSuccess = true,
  }) async {
    bool isLoading = false;
    
    try {
      if (loadingMessage != null) {
        isLoading = true;
        Get.dialog(
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(loadingMessage),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }

      T result = await operation();

      if (isLoading) {
        Get.back(); // Close loading dialog
        isLoading = false;
      }

      if (showSuccess && successMessage != null) {
        showSuccessSnackbar(successMessage);
      }

      return result;
    } catch (error) {
      if (isLoading) {
        Get.back(); // Close loading dialog
      }
      handleError(error);
      return null;
    }
  }

  /// Validate form fields with common validation rules
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required'.tr;
    }
    if (!GetUtils.isEmail(email)) {
      return 'Please enter a valid email address'.tr;
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required'.tr;
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters'.tr;
    }
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required'.tr;
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters'.tr;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores'.tr;
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '\$fieldName is required'.tr;
    }
    return null;
  }
}
