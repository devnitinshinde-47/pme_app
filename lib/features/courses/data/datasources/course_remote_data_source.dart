import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/course_model.dart';
import '../models/course_progress_model.dart';

/// Remote data source calling Spring Boot Course REST APIs.
class CourseRemoteDataSource {
  final ApiClient _apiClient;

  CourseRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  List<dynamic> _extractItems(dynamic response, List<String> keys) {
    if (response is List) return response;
    if (response is! Map) return const [];

    for (final key in keys) {
      final value = response[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = _extractItems(value, keys);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  /// Discover courses (Paginated)
  /// Endpoint: GET /api/courses
  Future<CoursePageResponse> fetchCourses({
    String? branch,
    String? university,
    String? type,
    String? year,
    int page = 0,
    int size = 12,
    String? sort,
    String? token,
  }) async {
    final queryParams = <String, String>{
      if (branch != null && branch.isNotEmpty) 'branch': branch,
      if (university != null && university.isNotEmpty) 'university': university,
      if (type != null && type.isNotEmpty) 'type': type,
      if (year != null && year.isNotEmpty) 'year': year,
      'page': page.toString(),
      'size': size.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: ApiConstants.courses,
      queryParameters: queryParams,
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return CoursePageResponse.fromJson(response);
    } else if (response is List) {
      final items = response.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
      return CoursePageResponse(
        content: items,
        pageNumber: 0,
        pageSize: items.length,
        totalElements: items.length,
        totalPages: 1,
        last: true,
      );
    }
    throw const ApiException('Unexpected response format for course discovery');
  }

  /// Get single course details
  /// Endpoint: GET /api/courses/{id}
  Future<CourseModel> fetchCourseById(String id, {String? token}) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/$id',
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return CourseModel.fromJson(response);
    }
    throw const ApiException('Failed to load course details');
  }

  /// Fetch Master Items for UI Filters (BRANCH, YEAR, UNIVERSITY)
  /// Endpoint: GET /api/courses/settings
  Future<List<MasterSettingItem>> fetchMasterSettings({
    String? type,
    String status = 'ACTIVE',
    String? token,
  }) async {
    final queryParams = <String, String>{
      if (type != null && type.isNotEmpty) 'type': type,
      'status': status,
    };

    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: ApiConstants.courseSettings,
      queryParameters: queryParams,
      token: token,
    );

    if (response is List) {
      return response.map((e) => MasterSettingItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get Course Lessons (Syllabus)
  /// Endpoint: GET /api/courses/{courseId}/lessons
  Future<List<LessonModel>> fetchCourseLessons(String courseId, {String? token}) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/$courseId/lessons',
      token: token,
    );

    final items = _extractItems(response, const ['lessons', 'content', 'data', 'items']);
    return items
        .whereType<Map>()
        .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Submit Purchase Request
  /// Endpoint: POST /api/courses/{courseId}/purchase-request
  Future<CourseEnrollmentResponse> submitPurchaseRequest(
    String courseId, {
    required String token,
  }) async {
    final response = await _apiClient.post(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/$courseId/purchase-request',
      token: token,
    );
    return CourseEnrollmentResponse.fromJson(response);
  }

  /// Cancel Purchase Request
  /// Endpoint: POST /api/courses/{courseId}/cancel-request
  Future<void> cancelPurchaseRequest(
    String courseId, {
    required String token,
  }) async {
    await _apiClient.post(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/$courseId/cancel-request',
      token: token,
    );
  }

  /// Get Pending Requested Course IDs for Logged-In Student
  /// Endpoint: GET /api/courses/my-requested-courses
  Future<Set<String>> fetchMyRequestedCourseIds({required String token}) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/my-requested-courses',
      token: token,
    );
    if (response is List) {
      return response.map((e) => e.toString()).toSet();
    }
    return {};
  }

  /// Get Enrolled Courses for Logged-In Student ("My Courses")
  /// Endpoint: GET /api/courses/my-courses
  Future<List<CourseModel>> fetchMyEnrolledCourses({String? token}) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/my-courses',
      token: token,
    );

    if (response is List) {
      return response.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get Video Lectures for a Course
  /// Endpoint: GET /api/courses/{courseId}/videos
  Future<List<LectureModel>> fetchCourseVideos(String courseId, {String? token}) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: '/$courseId/videos',
      token: token,
    );

    final items = _extractItems(response, const ['videos', 'lectures', 'content', 'data', 'items']);
    return items
        .whereType<Map>()
        .map((e) => LectureModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get Study Notes for a Course (optionally filtered by videoId)
  /// Endpoint: GET /api/courses/{courseId}/notes?videoId={videoId}
  Future<List<NoteModel>> fetchCourseNotes(String courseId, {String? videoId, String? token}) async {
    final endpoint = videoId != null && videoId.isNotEmpty
        ? '/$courseId/notes?videoId=$videoId'
        : '/$courseId/notes';

    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.coursesBaseUrl,
      endpoint: endpoint,
      token: token,
    );

    final items = _extractItems(response, const ['notes', 'content', 'data', 'items']);
    return items
        .whereType<Map>()
        .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Toggle video lecture completion status
  /// Endpoint: POST /api/progress/courses/{courseId}/videos/{videoId}/toggle
  Future<CourseProgressModel> toggleVideoProgress({
    required String courseId,
    required String videoId,
    required bool completed,
    required String token,
  }) async {
    final response = await _apiClient.post(
      customBaseUrl: ApiConstants.progressBaseUrl,
      endpoint: '/courses/$courseId/videos/$videoId/toggle',
      body: {'completed': completed},
      token: token,
    );
    return CourseProgressModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// Fetch course progress summary for a single course
  /// Endpoint: GET /api/progress/courses/{courseId}
  Future<CourseProgressModel> fetchCourseProgress({
    required String courseId,
    required String token,
  }) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.progressBaseUrl,
      endpoint: '/courses/$courseId',
      token: token,
    );
    return CourseProgressModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// Fetch progress summary for all enrolled courses
  /// Endpoint: GET /api/progress/my-progress
  Future<Map<String, CourseProgressModel>> fetchAllCoursesProgress({
    required String token,
  }) async {
    final response = await _apiClient.get(
      customBaseUrl: ApiConstants.progressBaseUrl,
      endpoint: '/my-progress',
      token: token,
    );
    final Map<String, CourseProgressModel> result = {};
    if (response is Map) {
      response.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key.toString()] = CourseProgressModel.fromJson(value);
        }
      });
    }
    return result;
  }
}
