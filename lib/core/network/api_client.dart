import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';

/// Clean production HTTP client wrapper for Java Spring Boot REST APIs
/// with automatic JWT refresh token retry mechanism.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Perform GET request to Java Spring Boot REST endpoint
  Future<dynamic> get({
    required String endpoint,
    String? customBaseUrl,
    Map<String, String>? queryParameters,
    String? token,
    String? deviceId,
  }) async {
    final base = customBaseUrl ?? ApiConstants.apiBaseUrl;
    final Uri rawUri = Uri.parse('$base$endpoint');
    final uri = queryParameters != null && queryParameters.isNotEmpty
        ? rawUri.replace(queryParameters: {
            ...rawUri.queryParameters,
            ...queryParameters,
          })
        : rawUri;

    try {
      final activeToken = token ?? await TokenManager.instance.getAccessToken();
      final response = await _client
          .get(
            uri,
            headers: ApiConstants.headers(token: activeToken, deviceId: deviceId),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && _shouldAttemptRefresh(endpoint)) {
        final newToken = await TokenManager.instance.refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retriedResponse = await _client
              .get(
                uri,
                headers: ApiConstants.headers(token: newToken),
              )
              .timeout(const Duration(seconds: 10));
          return _handleRawResponse(retriedResponse);
        }
      }

      return _handleRawResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No internet connection. Please check your connection and try again.');
    } on http.ClientException {
      throw const ApiException('Unable to complete your request. Please try again.');
    } catch (_) {
      throw const ApiException('Unable to complete your request. Please try again.');
    }
  }

  /// Perform POST request to Java Spring Boot REST endpoint
  Future<Map<String, dynamic>> post({
    required String endpoint,
    String? customBaseUrl,
    Map<String, dynamic>? body,
    String? token,
    String? deviceId,
  }) async {
    final base = customBaseUrl ?? ApiConstants.authBaseUrl;
    final uri = Uri.parse('$base$endpoint');

    try {
      final activeToken = token ?? await TokenManager.instance.getAccessToken();
      final response = await _client
          .post(
            uri,
            headers: ApiConstants.headers(token: activeToken, deviceId: deviceId),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && _shouldAttemptRefresh(endpoint)) {
        final newToken = await TokenManager.instance.refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retriedResponse = await _client
              .post(
                uri,
                headers: ApiConstants.headers(token: newToken),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 10));
          final result = _handleRawResponse(retriedResponse);
          if (result is Map<String, dynamic>) {
            return result;
          }
          return {'data': result};
        }
      }

      final result = _handleRawResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'data': result};
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No internet connection. Please check your connection and try again.');
    } on http.ClientException {
      throw const ApiException('Unable to complete your request. Please try again.');
    } catch (_) {
      throw const ApiException('Unable to complete your request. Please try again.');
    }
  }

  /// Perform PUT request to Java Spring Boot REST endpoint
  Future<Map<String, dynamic>> put({
    required String endpoint,
    String? customBaseUrl,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final base = customBaseUrl ?? ApiConstants.apiBaseUrl;
    final uri = Uri.parse('$base$endpoint');

    try {
      final activeToken = token ?? await TokenManager.instance.getAccessToken();
      final response = await _client
          .put(
            uri,
            headers: ApiConstants.headers(token: activeToken),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && _shouldAttemptRefresh(endpoint)) {
        final newToken = await TokenManager.instance.refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retriedResponse = await _client
              .put(
                uri,
                headers: ApiConstants.headers(token: newToken),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 10));
          final result = _handleRawResponse(retriedResponse);
          if (result is Map<String, dynamic>) {
            return result;
          }
          return {'data': result};
        }
      }

      final result = _handleRawResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'data': result};
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No internet connection. Please check your connection and try again.');
    } on http.ClientException {
      throw const ApiException('Unable to complete your request. Please try again.');
    } catch (_) {
      throw const ApiException('Unable to complete your request. Please try again.');
    }
  }

  /// Perform DELETE request to Java Spring Boot REST endpoint
  Future<dynamic> delete({
    required String endpoint,
    String? customBaseUrl,
    String? token,
  }) async {
    final base = customBaseUrl ?? ApiConstants.apiBaseUrl;
    final uri = Uri.parse('$base$endpoint');

    try {
      final activeToken = token ?? await TokenManager.instance.getAccessToken();
      final response = await _client
          .delete(
            uri,
            headers: ApiConstants.headers(token: activeToken),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 && _shouldAttemptRefresh(endpoint)) {
        final newToken = await TokenManager.instance.refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retriedResponse = await _client
              .delete(
                uri,
                headers: ApiConstants.headers(token: newToken),
              )
              .timeout(const Duration(seconds: 10));
          return _handleRawResponse(retriedResponse);
        }
      }

      return _handleRawResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No internet connection. Please check your connection and try again.');
    } on http.ClientException {
      throw const ApiException('Unable to complete your request. Please try again.');
    } catch (_) {
      throw const ApiException('Unable to complete your request. Please try again.');
    }
  }

  bool _shouldAttemptRefresh(String endpoint) {
    return endpoint != ApiConstants.refreshToken &&
        endpoint != ApiConstants.verifyOtp &&
        endpoint != ApiConstants.sendOtp;
  }

  dynamic _handleRawResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final serverMessage = body is Map<String, dynamic>
        ? body['message']?.toString()
        : null;
    throw ApiException(
      serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'Unable to complete your request. Please try again.',
      statusCode: response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
