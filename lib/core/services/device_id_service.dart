import 'package:shared_preferences/shared_preferences.dart';

/// Service for retrieving a stable device identifier.
///
/// Uses a stored UUID that persists across app restarts.
/// This provides a consistent device fingerprint for single-device login enforcement.
class DeviceIdService {
  static const String _storedDeviceIdKey = 'stored_device_id';

  /// Get the device ID (stored UUID or generate new one)
  Future<String> getDeviceId() async {
    // Try to get stored device ID or create a new one
    return await _getOrCreateStoredDeviceId();
  }

  /// Store device ID in SharedPreferences
  Future<void> _storeDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storedDeviceIdKey, deviceId);
    } catch (e) {
    }
  }

  /// Get stored device ID or create a new UUID
  Future<String> _getOrCreateStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString(_storedDeviceIdKey);
      
      if (storedId != null && storedId.isNotEmpty) {
        return storedId;
      }

      // Generate new UUID
      final newId = _generateUuid();
      await prefs.setString(_storedDeviceIdKey, newId);
      return newId;
    } catch (e) {
      // Last resort: return a timestamp-based ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Generate a simple UUID v4-like string
  String _generateUuid() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final hex = random.toRadixString(16).padLeft(12, '0');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(8, 12)}-${hex.substring(8, 12)}-${hex}${hex}';
  }

  /// Clear stored device ID (for testing purposes)
  Future<void> clearStoredDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storedDeviceIdKey);
    } catch (e) {
    }
  }
}