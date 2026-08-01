import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

/// Repository providing student notifications with mock fallback.
class NotificationRepository {
  static const String _keyLastReadNotificationTime = 'last_read_notification_time';
  final NotificationRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  NotificationRepository({
    NotificationRemoteDataSource? remote,
    AuthLocalDataSource? local,
  })  : _remote = remote ?? NotificationRemoteDataSource(),
        _local = local ?? AuthLocalDataSource();

  Future<List<NotificationModel>> getMyNotifications() async {
    final token = await _local.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        return await _remote.fetchMyNotifications(token);
      } catch (_) {}
    }
    return [];
  }

  /// Returns count of notifications created after the user's last read timestamp
  Future<int> getUnreadNotificationsCount() async {
    final notifs = await getMyNotifications();
    if (notifs.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lastReadIso = prefs.getString(_keyLastReadNotificationTime);

    if (lastReadIso == null || lastReadIso.isEmpty) {
      return notifs.length;
    }

    final lastReadTime = DateTime.tryParse(lastReadIso);
    if (lastReadTime == null) return notifs.length;

    final unread = notifs.where((n) => n.createdAt.isAfter(lastReadTime)).toList();
    return unread.length;
  }

  /// Updates last read timestamp to current time when user opens NotificationsScreen
  Future<void> markNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastReadNotificationTime, DateTime.now().toIso8601String());
  }

  Future<bool> registerFcmToken(String fcmToken) async {
    final token = await _local.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _remote.registerFcmToken(token, fcmToken);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<void> deleteNotification(String id) async {
    final token = await _local.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _remote.deleteNotification(token, id);
      } catch (_) {}
    }
  }
}
