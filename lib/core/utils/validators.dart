/// Centralized validation utilities for mobile numbers and OTP verification.
abstract class Validators {
  /// Validates a 10-digit Indian mobile number.
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    final firstDigit = cleaned[0];
    if (!['6', '7', '8', '9'].contains(firstDigit)) {
      return 'Mobile number should start with 6, 7, 8, or 9';
    }
    return null;
  }

  /// Validates a 6-digit numeric OTP code.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the 6-digit OTP';
    }
    final cleaned = value.trim();
    if (cleaned.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleaned)) {
      return 'Enter complete 6-digit verification code';
    }
    return null;
  }
}
