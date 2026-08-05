import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../datasources/course_remote_data_source.dart';
import '../models/course_model.dart';
import '../models/course_progress_model.dart';

/// Repository managing course discovery, filtering by MSBTE/SPPU/DBATU, lessons, and enrollment.
class CourseRepository {
  final CourseRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  bool useMockFallback;

  CourseRepository({
    CourseRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
    this.useMockFallback = false,
  })  : _remoteDataSource = remoteDataSource ?? CourseRemoteDataSource(),
        _localDataSource = localDataSource ?? AuthLocalDataSource();

  /// Fetch master branch settings from backend (GET /api/courses/settings?type=BRANCH)
  Future<List<String>> getMasterBranches() async {
    try {
      final token = await _localDataSource.getAccessToken();
      final items = await _remoteDataSource.fetchMasterSettings(type: 'BRANCH', token: token);
      if (items.isNotEmpty) {
        return items.map((i) => i.name).where((name) => name.isNotEmpty).toList();
      }
    } catch (_) {}
    return const [
      'Mechanical',
      'Computer',
      'Civil',
      'E&TC',
      'IT',
      'Electrical',
    ];
  }

  bool _isUuid(String? str) {
    if (str == null) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

  /// Fetch all active Combo Offer courses
  Future<List<CourseModel>> getComboCourses({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await _localDataSource.getAccessToken();
      final combos = await _remoteDataSource.fetchComboCourses(
        page: page,
        size: size,
        token: token,
      );
      if (combos.isNotEmpty) {
        return combos;
      }
    } catch (_) {}

    // Fallback: check general courses list for isCombo items
    try {
      final token = await _localDataSource.getAccessToken();
      final pageResp = await _remoteDataSource.fetchCourses(
        page: 0,
        size: 50,
        token: token,
      );
      final list = pageResp.content.where((c) => c.isCombo).toList();
      if (list.isNotEmpty) {
        return list;
      }
    } catch (_) {}

    return const [];
  }

  /// Discover courses with university, branch, type, and year filtering
  Future<CoursePageResponse> getCourses({
    String? branch,
    String? university,
    String? type,
    String? year,
    String? searchQuery,
    int page = 0,
    int size = 12,
    String? sort,
  }) async {
    try {
      final token = await _localDataSource.getAccessToken();
      final response = await _remoteDataSource.fetchCourses(
        branch: _isUuid(branch) ? branch : null,
        university: university,
        type: type,
        year: year,
        page: page,
        size: size,
        sort: sort,
        token: token,
      );

      if (response.content.isNotEmpty) {
        final filteredContent = _applySearchAndLocalFilters(
          response.content,
          searchQuery: searchQuery,
          branch: branch,
          university: university,
          type: type,
        );
        return CoursePageResponse(
          content: filteredContent,
          pageNumber: response.pageNumber,
          pageSize: response.pageSize,
          totalElements: filteredContent.length,
          totalPages: response.totalPages,
          last: response.last,
        );
      } else if (useMockFallback) {
        return _getMockCoursePage(
          branch: branch,
          university: university,
          type: type,
          year: year,
          searchQuery: searchQuery,
        );
      }
      return response;
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        return _getMockCoursePage(
          branch: branch,
          university: university,
          type: type,
          year: year,
          searchQuery: searchQuery,
        );
      }
      rethrow;
    }
  }

  /// Get single course details
  Future<CourseModel> getCourseById(String id) async {
    try {
      final token = await _localDataSource.getAccessToken();
      return await _remoteDataSource.fetchCourseById(id, token: token);
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        final mockList = _sampleCourses();
        return mockList.firstWhere(
          (c) => c.id == id,
          orElse: () => mockList.first,
        );
      }
      rethrow;
    }
  }

  /// Fetch syllabus lessons for a course with attached lectures and notes
  Future<List<LessonModel>> getCourseLessons(String courseId) async {
    try {
      final token = await _localDataSource.getAccessToken();
      final lessons = await _remoteDataSource.fetchCourseLessons(courseId, token: token);
      
      if (lessons.isEmpty) {
        return useMockFallback ? _mockLessons(courseId) : [];
      }

      // Fetch videos & notes concurrently for the course
      List<LectureModel> videos = [];
      List<NoteModel> notes = [];

      final videosFuture = _remoteDataSource.fetchCourseVideos(courseId, token: token);
      final notesFuture = _remoteDataSource.fetchCourseNotes(courseId, token: token);
      try {
        videos = await videosFuture;
      } catch (_) {
        // Lessons and notes can still load when the videos endpoint is unavailable.
      }
      try {
        notes = await notesFuture;
      } catch (_) {
        // Keep any notes returned inside the lesson payload.
      }

      // Attach videos and notes to each lesson module
      return lessons.map((lesson) {
        // Sort videos oldest-first (earliest added at top, most recently added at bottom)
        final lessonVideos = videos.where((v) => v.lessonId == lesson.id).toList()
          ..sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });
        // Include all notes belonging to this lesson module (lesson-level or video-level)
        final lessonNotes = notes.where((n) => n.lessonId == lesson.id).toList();
        final mergedNotes = <String, NoteModel>{
          for (final note in lesson.notes) note.id: note,
          for (final note in lessonNotes) note.id: note,
        }.values.toList();

        return lesson.copyWith(
          lectures: lessonVideos.isNotEmpty ? lessonVideos : lesson.lectures,
          notes: mergedNotes,
        );
      }).toList();
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        return _mockLessons(courseId);
      }
      return [];
    }
  }

  /// Fetch all notes for a course (for Tab 2 Study Notes)
  Future<List<NoteModel>> getCourseNotes(String courseId) async {
    try {
      final token = await _localDataSource.getAccessToken();
      final notes = await _remoteDataSource.fetchCourseNotes(courseId, token: token);
      if (notes.isNotEmpty) return notes;
      return useMockFallback ? _mockCourseNotes() : [];
    } catch (_) {
      return useMockFallback ? _mockCourseNotes() : [];
    }
  }

  List<NoteModel> _mockCourseNotes() {
    return const [
      NoteModel(
        id: 'cn-course-1',
        title: 'Complete Course Syllabus & Formula Booklet PDF',
        scope: 'COURSE',
        fileSize: '4.8 MB',
        isGlobal: true,
      ),
      NoteModel(
        id: 'cn-course-2',
        title: 'Previous 5 Years University Exam Question Papers & Solutions',
        scope: 'COURSE',
        fileSize: '8.2 MB',
        isGlobal: true,
      ),
      NoteModel(
        id: 'note1-1',
        title: 'Module 1 PDF Handwritten Notes & Formula Cheat Sheet',
        scope: 'LESSON',
        fileSize: '3.2 MB',
      ),
      NoteModel(
        id: 'note1-2',
        title: 'Fluid Statics Solved Numerical Examples PDF',
        scope: 'LESSON',
        fileSize: '1.9 MB',
      ),
      NoteModel(
        id: 'note2-1',
        title: 'Module 2 Dimensional Analysis Practice Question Bank',
        scope: 'LESSON',
        fileSize: '2.5 MB',
      ),
      NoteModel(
        id: 'note3-1',
        title: 'Module 3 Pipe Flow & Boundary Layer Summary PDF',
        scope: 'LESSON',
        fileSize: '2.1 MB',
      ),
    ];
  }

  /// Fetch note attached to a specific video ID
  Future<NoteModel?> getNoteForVideo(String courseId, String videoId) async {
    try {
      final token = await _localDataSource.getAccessToken();
      final notes = await _remoteDataSource.fetchCourseNotes(courseId, videoId: videoId, token: token);
      if (notes.isNotEmpty) return notes.first;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch set of all requested course IDs (synced with server)
  Future<Set<String>> getRequestedCourseIds() async {
    final token = await _localDataSource.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final serverRequestedIds = await _remoteDataSource.fetchMyRequestedCourseIds(token: token);
        await _localDataSource.setRequestedCourseIds(serverRequestedIds.toList());
        return serverRequestedIds;
      } catch (_) {
        // Fallback to local storage if offline or server error
      }
    }
    return await _localDataSource.getRequestedCourseIds();
  }

  /// Check if a course has already been requested by the student
  Future<bool> isCourseRequested(String courseId) async {
    final requestedIds = await getRequestedCourseIds();
    return requestedIds.contains(courseId);
  }

  /// Submit purchase / enrollment request to Spring Boot backend (requires admin approval)
  Future<CourseEnrollmentResponse> submitPurchaseRequest(String courseId) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in as a student to request course enrollment.');
    }

    try {
      final response = await _remoteDataSource.submitPurchaseRequest(courseId, token: token);
      await _localDataSource.addRequestedCourseId(courseId);
      return response;
    } catch (_) {
      await _localDataSource.addRequestedCourseId(courseId);
      return CourseEnrollmentResponse(
        id: 'enr_$courseId',
        accessStatus: 'PENDING',
        paymentStatus: 'PENDING',
      );
    }
  }

  /// Cancel a pending purchase / enrollment request
  Future<void> cancelPurchaseRequest(String courseId) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in as a student to cancel a purchase request.');
    }

    await _remoteDataSource.cancelPurchaseRequest(courseId, token: token);
    await _localDataSource.removeRequestedCourseId(courseId);
  }

  /// Get enrolled/approved courses for the logged-in student (granted by admin)
  Future<List<CourseModel>> getMyEnrolledCourses() async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final courses = await _remoteDataSource.fetchMyEnrolledCourses(token: token);
      final enrolledIds = courses.map((c) => c.id).toList();
      await _localDataSource.setEnrolledCourseIds(enrolledIds);
      return courses;
    } catch (_) {
      final enrolledIds = await _localDataSource.getEnrolledCourseIds();
      if (enrolledIds.isEmpty) return [];
      final allCoursesResponse = await getCourses();
      return allCoursesResponse.content.where((c) => enrolledIds.contains(c.id)).toList();
    }
  }

  /// Get set of approved/enrolled course IDs
  Future<Set<String>> getEnrolledCourseIds() async {
    final token = await _localDataSource.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final enrolled = await getMyEnrolledCourses();
        return enrolled.map((c) => c.id).toSet();
      } catch (_) {}
    }
    return await _localDataSource.getEnrolledCourseIds();
  }

  List<CourseModel> _applySearchAndLocalFilters(
    List<CourseModel> courses, {
    String? searchQuery,
    String? branch,
    String? university,
    String? type,
  }) {
    return courses.where((course) {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchName = course.name.toLowerCase().contains(query);
        final matchDesc = course.description?.toLowerCase().contains(query) ?? false;
        final matchUniv = course.university?.toLowerCase().contains(query) ?? false;
        if (!matchName && !matchDesc && !matchUniv) return false;
      }
      if (university != null && university.isNotEmpty && university != 'All') {
        if (course.university?.toLowerCase() != university.toLowerCase()) {
          return false;
        }
      }
      if (type != null && type.isNotEmpty && type != 'All') {
        if (course.type.toLowerCase() != type.toLowerCase()) {
          return false;
        }
      }
      if (branch != null && branch.isNotEmpty && branch != 'All') {
        final matchBranch = course.branches.any(
          (b) => b.toLowerCase().contains(branch.toLowerCase()),
        );
        if (!matchBranch) return false;
      }
      return true;
    }).toList();
  }

  CoursePageResponse _getMockCoursePage({
    String? branch,
    String? university,
    String? type,
    String? year,
    String? searchQuery,
  }) {
    final allMock = _sampleCourses();
    final filtered = _applySearchAndLocalFilters(
      allMock,
      searchQuery: searchQuery,
      branch: branch,
      university: university,
      type: type,
    );

    return CoursePageResponse(
      content: filtered,
      pageNumber: 0,
      pageSize: 12,
      totalElements: filtered.length,
      totalPages: 1,
      last: true,
    );
  }

  List<CourseModel> _sampleCourses() {
    return const [
      CourseModel(
        id: 'c1-sppu-fluid',
        name: 'SPPU Advanced Fluid Mechanics',
        description: 'Master fluid dynamics, Bernoulli theorem, and turbo-machinery tailored for Savitribai Phule Pune University curriculum.',
        type: 'ENGINEERING',
        mode: 'BOTH',
        price: 3499.0,
        accessDurationMonths: 12,
        branches: ['Mechanical Engineering', 'Civil Engineering'],
        year: '3rd Year',
        university: 'SPPU',
        startDate: '2026-08-01',
        endDate: '2027-07-31',
        thumbnailUrl: 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 340,
      ),
      CourseModel(
        id: 'c2-msbte-maths',
        name: 'MSBTE Applied Mathematics (M3)',
        description: 'Complete M3 diploma syllabus for MSBTE polytechnic students with solved question papers and shortcut tricks.',
        type: 'POLYTECHNIC',
        mode: 'RECORDED',
        price: 1499.0,
        accessDurationMonths: 6,
        branches: ['Computer Engineering', 'Information Technology', 'Mechanical Engineering', 'Civil Engineering', 'E&TC Engineering'],
        year: '2nd Year',
        university: 'MSBTE',
        startDate: '2026-08-10',
        endDate: '2027-02-10',
        thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 512,
      ),
      CourseModel(
        id: 'c3-dbatu-thermo',
        name: 'DBATU Engineering Thermodynamics',
        description: 'Comprehensive thermodynamics principles, heat engines, and entropy modules for DBATU B.Tech students.',
        type: 'ENGINEERING',
        mode: 'LIVE',
        price: 2999.0,
        accessDurationMonths: 12,
        branches: ['Mechanical Engineering', 'Electrical Engineering'],
        year: '2nd Year',
        university: 'DBATU',
        startDate: '2026-08-05',
        endDate: '2027-08-04',
        thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 215,
      ),
      CourseModel(
        id: 'c4-sppu-dsa',
        name: 'SPPU Data Structures & Algorithms',
        description: 'In-depth DSA in C++ & Java with practical lab assignments, tree traversals, and dynamic programming for SPPU CS/IT.',
        type: 'ENGINEERING',
        mode: 'BOTH',
        price: 3999.0,
        accessDurationMonths: 12,
        branches: ['Computer Engineering', 'Information Technology'],
        year: '2nd Year',
        university: 'SPPU',
        startDate: '2026-08-15',
        endDate: '2027-08-14',
        thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 680,
      ),
      CourseModel(
        id: 'c5-msbte-microprocessor',
        name: 'MSBTE Microprocessors & Microcontrollers',
        description: '8086 Assembly Programming and 8051 hardware interfacing modules for MSBTE Computer & Electronics diploma.',
        type: 'POLYTECHNIC',
        mode: 'RECORDED',
        price: 1999.0,
        accessDurationMonths: 6,
        branches: ['Computer Engineering', 'E&TC Engineering'],
        year: '3rd Year',
        university: 'MSBTE',
        startDate: '2026-09-01',
        endDate: '2027-03-01',
        thumbnailUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 290,
      ),
      CourseModel(
        id: 'c6-dbatu-java',
        name: 'DBATU Object Oriented Programming with Java',
        description: 'Learn OOPs concepts, multithreading, collections, and JavaFX lab projects specified by DBATU university.',
        type: 'ENGINEERING',
        mode: 'LIVE',
        price: 3299.0,
        accessDurationMonths: 12,
        branches: ['Computer Engineering', 'Information Technology'],
        year: '2nd Year',
        university: 'DBATU',
        startDate: '2026-08-20',
        endDate: '2027-08-20',
        thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=600&q=80',
        status: 'ACTIVE',
        studentsCount: 410,
      ),
    ];
  }

  List<LessonModel> _mockLessons(String courseId) {
    return [
      LessonModel(
        id: 'l1',
        courseId: courseId,
        title: 'Module 1: Fundamental Concepts & Governing Equations',
        description: 'Basic definitions, fluid properties, viscosity, pressure variation, and Navier-Stokes introduction.',
        lessonIndex: 1,
        lectures: const [
          LectureModel(
            id: 'lec1-1',
            title: '1.1 Introduction to Fluid Mechanics & Properties',
            duration: '42 mins',
            isCompleted: true,
          ),
          LectureModel(
            id: 'lec1-2',
            title: '1.2 Fluid Statics & Pressure Measurement Devices',
            duration: '55 mins',
            isCompleted: true,
          ),
          LectureModel(
            id: 'lec1-3',
            title: '1.3 Live Doubt Solution: Viscosity & Kinematics',
            duration: '60 mins',
            isLive: true,
            isCompleted: false,
          ),
        ],
        notes: const [
          NoteModel(
            id: 'note1-1',
            title: 'Module 1 PDF Handwritten Notes & Formula Cheat Sheet',
            fileSize: '3.2 MB',
          ),
          NoteModel(
            id: 'note1-2',
            title: 'Fluid Statics Solved Numerical Examples PDF',
            fileSize: '1.9 MB',
          ),
        ],
      ),
      LessonModel(
        id: 'l2',
        courseId: courseId,
        title: 'Module 2: Dimensional Analysis & Model Testing',
        description: 'Buckingham Pi theorem, Rayleigh method, similitude parameters (Reynolds, Froude number).',
        lessonIndex: 2,
        lectures: const [
          LectureModel(
            id: 'lec2-1',
            title: '2.1 Buckingham Pi Theorem & Dimensionless Groups',
            duration: '48 mins',
          ),
          LectureModel(
            id: 'lec2-2',
            title: '2.2 Model Laws: Reynolds, Froude, & Euler Similitude',
            duration: '50 mins',
          ),
        ],
        notes: const [
          NoteModel(
            id: 'note2-1',
            title: 'Module 2 Dimensional Analysis Practice Question Bank',
            fileSize: '2.5 MB',
          ),
        ],
      ),
      LessonModel(
        id: 'l3',
        courseId: courseId,
        title: 'Module 3: Internal Flow & Boundary Layer Theory',
        description: 'Laminar and turbulent flows in pipes, friction factor, Darcy-Weisbach equation, and boundary layer separation.',
        lessonIndex: 3,
        lectures: const [
          LectureModel(
            id: 'lec3-1',
            title: '3.1 Pipe Flow & Friction Factor Calculation',
            duration: '52 mins',
          ),
          LectureModel(
            id: 'lec3-2',
            title: '3.2 Boundary Layer Growth & Drag Force Analysis',
            duration: '45 mins',
          ),
        ],
        notes: const [
          NoteModel(
            id: 'note3-1',
            title: 'Module 3 Pipe Flow & Boundary Layer Summary PDF',
            fileSize: '2.1 MB',
          ),
        ],
      ),
      LessonModel(
        id: 'l4',
        courseId: courseId,
        title: 'Module 4: Solved Numerical & PYQ Series',
        description: 'Step-by-step solutions for previous year university exam questions.',
        lessonIndex: 4,
        lectures: const [
          LectureModel(
            id: 'lec4-1',
            title: '4.1 University Exam PYQ Solution Series Part 1',
            duration: '65 mins',
          ),
          LectureModel(
            id: 'lec4-2',
            title: '4.2 Model Answer Key & Exam Strategy Session',
            duration: '40 mins',
          ),
        ],
        notes: const [
          NoteModel(
            id: 'note4-1',
            title: 'Complete University Solved Question Papers PDF',
            fileSize: '5.4 MB',
            isGlobal: true,
          ),
        ],
      ),
    ];
  }

  /// Toggle video completion progress for logged-in student
  Future<CourseProgressModel?> toggleVideoProgress(String courseId, String videoId, bool completed) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _remoteDataSource.toggleVideoProgress(
        courseId: courseId,
        videoId: videoId,
        completed: completed,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch course progress summary for a specific course
  Future<CourseProgressModel?> getCourseProgress(String courseId) async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _remoteDataSource.fetchCourseProgress(courseId: courseId, token: token);
    } catch (_) {
      return null;
    }
  }

  /// Fetch progress summaries for all enrolled courses
  Future<Map<String, CourseProgressModel>> getAllCoursesProgress() async {
    final token = await _localDataSource.getAccessToken();
    if (token == null || token.isEmpty) return {};
    try {
      return await _remoteDataSource.fetchAllCoursesProgress(token: token);
    } catch (_) {
      return {};
    }
  }
}
