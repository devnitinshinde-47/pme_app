import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/student_live_lecture_model.dart';

/// Remote data source handling Spring Boot scheduled live lecture REST APIs.
class LiveLectureRemoteDataSource {
  final ApiClient _apiClient;

  LiveLectureRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Endpoint: GET /api/student/live-lectures/calendar
  /// Query params: start, end, courseId (optional)
  Future<List<StudentLiveLecture>> fetchLiveLectureCalendar({
    required String startDate,
    required String endDate,
    String? courseId,
    String? token,
  }) async {
    final queryParameters = <String, String>{
      'start': startDate,
      'end': endDate,
      if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
    };


    final response = await _apiClient.get(
      endpoint: '/student/live-lectures/calendar',
      customBaseUrl: ApiConstants.apiBaseUrl,
      queryParameters: queryParameters,
      token: token,
    );

    if (response is List) {
      return response
          .map((json) => StudentLiveLecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => StudentLiveLecture.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Endpoint: GET /api/student/courses/{courseId}/live-lectures
  Future<List<StudentLiveLecture>> fetchCourseLiveLectures({
    required String courseId,
    String? token,
  }) async {
    final response = await _apiClient.get(
      endpoint: '/student/courses/$courseId/live-lectures',
      customBaseUrl: ApiConstants.apiBaseUrl,
      token: token,
    );

    if (response is List) {
      return response
          .map((json) => StudentLiveLecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => StudentLiveLecture.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
