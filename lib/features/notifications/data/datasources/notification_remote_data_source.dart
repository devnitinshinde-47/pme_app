import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/notification_model.dart';

/// Fetches notifications from Spring Boot backend.
class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/notifications — notifications for the logged-in student
  Future<List<NotificationModel>> fetchMyNotifications(String token) async {
    final responseJson = await _apiClient.get(
      customBaseUrl: ApiConstants.notificationsBaseUrl,
      endpoint: '',
      token: token,
    );

    if (responseJson is List) {
      return responseJson
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    }

    if (responseJson is Map<String, dynamic> && responseJson['content'] is List) {
      return (responseJson['content'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    }

    return [];
  }

  /// POST /api/notifications/fcm-token — sync FCM device token
  Future<void> registerFcmToken(String token, String fcmToken) async {
    await _apiClient.post(
      customBaseUrl: ApiConstants.notificationsBaseUrl,
      endpoint: '/fcm-token',
      token: token,
      body: {'fcmToken': fcmToken},
    );
  }

  /// DELETE /api/notifications/{id} — delete notification
  Future<void> deleteNotification(String token, String id) async {
    await _apiClient.delete(
      customBaseUrl: ApiConstants.notificationsBaseUrl,
      endpoint: '/$id',
      token: token,
    );
  }
}
