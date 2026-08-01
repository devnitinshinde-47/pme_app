import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import 'api_constants.dart';

/// Singleton manager for thread-safe token refreshing across concurrent HTTP requests.
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  static TokenManager get instance => _instance;

  final AuthLocalDataSource _localDataSource;
  final http.Client _client;

  Future<String?>? _refreshFuture;

  TokenManager({
    AuthLocalDataSource? localDataSource,
    http.Client? client,
  })  : _localDataSource = localDataSource ?? AuthLocalDataSource(),
        _client = client ?? http.Client();

  TokenManager._internal()
      : _localDataSource = AuthLocalDataSource(),
        _client = http.Client();

  /// Gets current stored JWT access token
  Future<String?> getAccessToken() async {
    return await _localDataSource.getAccessToken();
  }

  /// Gets current stored refresh token
  Future<String?> getRefreshToken() async {
    return await _localDataSource.getRefreshToken();
  }

  /// Thread-safe method to refresh access token.
  /// If a token refresh operation is already in progress, subsequent callers
  /// wait on the exact same [Future] to prevent multiple backend refresh requests.
  Future<String?> refreshAccessToken() async {
    if (_refreshFuture != null) {
      return await _refreshFuture;
    }

    _refreshFuture = _executeRefreshCall();
    try {
      final newToken = await _refreshFuture;
      return newToken;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _executeRefreshCall() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _localDataSource.clearSession();
      return null;
    }

    try {
      final uri = Uri.parse('${ApiConstants.authBaseUrl}${ApiConstants.refreshToken}');
      final response = await _client
          .post(
            uri,
            headers: ApiConstants.headers(),
            body: jsonEncode({'token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final String? newAccessToken = (body['accessToken'] ?? body['token']) as String?;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await _localDataSource.updateAccessToken(newAccessToken);
            return newAccessToken;
          }
        }
      }

      // If refresh token is expired or revoked by server (401 or 403), clear local session
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _localDataSource.clearSession();
      }
      return null;
    } catch (_) {
      // Network timeout / offline exception — DO NOT clear session!
      return null;
    }
  }
}
