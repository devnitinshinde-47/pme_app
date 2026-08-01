/// Student User Model representing the authenticated student entity.
class UserModel {
  final String id;
  final String mobileNumber;
  final String? name;
  final String? email;
  final String? profilePicture;
  final String? role;
  final bool isNewUser;

  const UserModel({
    required this.id,
    required this.mobileNumber,
    this.name,
    this.email,
    this.profilePicture,
    this.role,
    this.isNewUser = false,
  });

  UserModel copyWith({
    String? id,
    String? mobileNumber,
    String? name,
    String? email,
    String? profilePicture,
    String? role,
    bool? isNewUser,
  }) {
    return UserModel(
      id: id ?? this.id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      mobileNumber: json['mobileNo']?.toString() ??
          json['mobileNumber']?.toString() ??
          json['phone']?.toString() ??
          '',
      name: json['name']?.toString() ?? 'Student',
      email: json['email']?.toString(),
      profilePicture: json['profilePicture']?.toString() ?? json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'STUDENT',
      isNewUser: json['isNewUser'] == true || json['newUser'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNo': mobileNumber,
      'mobileNumber': mobileNumber,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'role': role,
      'isNewUser': isNewUser,
    };
  }
}

/// Response DTO from Spring Boot `/api/auth/send-otp`
class SendOtpResponse {
  final bool success;
  final String message;

  const SendOtpResponse({
    required this.success,
    required this.message,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] == true || json['status'] == 'SUCCESS',
      message: json['message']?.toString() ?? 'OTP sent successfully',
    );
  }
}

/// Response DTO from Spring Boot `/api/auth/verify-otp`
class VerifyOtpResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  const VerifyOtpResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['id'] != null || json['mobileNo'] != null) {
      parsedUser = UserModel.fromJson(json);
    }

    return VerifyOtpResponse(
      success: json['success'] == true || json['status'] == 'SUCCESS',
      message: json['message']?.toString() ?? 'Verification successful',
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      user: parsedUser,
    );
  }
}

/// Response DTO from Spring Boot `/api/auth/refresh-token`
class RefreshTokenResponse {
  final bool success;
  final String message;
  final String? accessToken;

  const RefreshTokenResponse({
    required this.success,
    required this.message,
    this.accessToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      success: json['success'] == true || json['status'] == 'SUCCESS',
      message: json['message']?.toString() ?? 'Token refreshed',
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString(),
    );
  }
}
