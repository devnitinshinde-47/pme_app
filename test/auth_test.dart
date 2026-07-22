import 'package:flutter_test/flutter_test.dart';
import 'package:pawanmateeducation/core/utils/validators.dart';
import 'package:pawanmateeducation/features/auth/data/models/user_model.dart';
import 'package:pawanmateeducation/features/auth/data/repositories/auth_repository.dart';

void main() {
  group('Validators Test', () {
    test('Mobile validator accepts valid 10-digit Indian numbers', () {
      expect(Validators.validateMobile('9876543210'), isNull);
      expect(Validators.validateMobile('8123456789'), isNull);
      expect(Validators.validateMobile('7000000000'), isNull);
    });

    test('Mobile validator rejects invalid numbers', () {
      expect(Validators.validateMobile('123'), isNotNull);
      expect(Validators.validateMobile('5999999999'), isNotNull);
      expect(Validators.validateMobile(''), isNotNull);
    });

    test('OTP validator checks 6-digit code', () {
      expect(Validators.validateOtp('123456'), isNull);
      expect(Validators.validateOtp('12345'), isNotNull);
      expect(Validators.validateOtp('abc123'), isNotNull);
    });
  });

  group('AuthRepository Test', () {
    final repository = AuthRepository(useMockFallback: true);

    test('sendOtp returns success response', () async {
      final response = await repository.sendOtp('9876543210');
      expect(response.success, isTrue);
      expect(response.txnId, isNotNull);
    });

    test('verifyOtp returns UserModel and handles authentication', () async {
      final response = await repository.verifyOtp('9876543210', '123456');
      expect(response.success, isTrue);
      expect(response.user, isA<UserModel>());
      expect(response.user.mobileNumber, equals('9876543210'));
      expect(response.user.token, isNotNull);
    });
  });
}
