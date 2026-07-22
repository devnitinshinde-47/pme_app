/// Student User Model representing the authenticated student entity.
class UserModel {
  final String id;
  final String mobileNumber;
  final String? name;
  final String? email;
  final String? profilePicture;
  final String? token;
  final bool isNewUser;

  const UserModel({
    required this.id,
    required this.mobileNumber,
    this.name,
    this.email,
    this.profilePicture,
    this.token,
    this.isNewUser = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      email: json['email']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
      token: json['token']?.toString(),
      isNewUser: json['isNewUser'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'token': token,
      'isNewUser': isNewUser,
    };
  }
}

/// Response DTO from Spring Boot `/auth/send-otp`
class SendOtpResponse {
  final bool success;
  final String message;
  final String? txnId;

  const SendOtpResponse({
    required this.success,
    required this.message,
    this.txnId,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] == true || json['status'] == 'SUCCESS',
      message: json['message']?.toString() ?? 'OTP sent successfully',
      txnId: json['txnId']?.toString(),
    );
  }
}

/// Response DTO from Spring Boot `/auth/verify-otp`
class AuthResponse {
  final bool success;
  final String message;
  final UserModel user;

  const AuthResponse({
    required this.success,
    required this.message,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true || json['status'] == 'SUCCESS',
      message: json['message']?.toString() ?? 'Verification successful',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? json),
    );
  }
}
