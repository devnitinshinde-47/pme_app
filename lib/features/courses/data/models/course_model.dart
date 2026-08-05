/// Course Data Model representing published course items for student discovery.
class CourseModel {
  final String id;
  final String name;
  final String? description;
  final String type; // ENGINEERING, POLYTECHNIC
  final String mode; // LIVE, RECORDED, BOTH, REGULAR
  final double price;
  final double? originalPrice;
  final bool isCombo;
  final List<String> includedCourseIds;
  final List<CourseModel> includedCourses;
  final int? accessDurationMonths;
  final List<String> branches;
  final List<String>? branchIds;
  final String? year;
  final String? university; // MSBTE, SPPU, DBATU, etc.
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  final String? thumbnailUrl;
  final String status;
  final int studentsCount;
  final String? completionStatus;
  final String? createdAt;
  final String? updatedAt;

  const CourseModel({
    required this.id,
    required this.name,
    this.description,
    this.type = 'ENGINEERING',
    this.mode = 'LIVE',
    required this.price,
    this.originalPrice,
    this.isCombo = false,
    this.includedCourseIds = const [],
    this.includedCourses = const [],
    this.accessDurationMonths,
    this.branches = const [],
    this.branchIds,
    this.year,
    this.university,
    this.startDate,
    this.endDate,
    this.thumbnailUrl,
    this.status = 'ACTIVE',
    this.studentsCount = 0,
    this.completionStatus,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if this course is for all branches (e.g. 4+ branches or explicitly marked as ALL/COMMON)
  bool get isCommonToAllBranches {
    if (branches.isEmpty) return false;

    for (final b in branches) {
      final normalized = b.trim().toLowerCase();
      if (normalized == 'all' ||
          normalized == 'all branches' ||
          normalized == 'all_branches' ||
          normalized == 'common' ||
          normalized == 'common to all' ||
          normalized == 'common to all branches' ||
          normalized == 'common_to_all_branches') {
        return true;
      }
    }

    // If 4 or more branches are assigned to this course (common first/second year or core subject across master DB)
    if (branches.length >= 4) {
      return true;
    }

    return false;
  }

  /// List of branch labels to display on UI cards
  List<String> get displayBranches {
    if (isCommonToAllBranches) {
      return const ['Common to All Branches'];
    }
    return branches;
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    final rawBundled = json['includedCourses'];
    List<CourseModel> parsedBundled = [];
    if (rawBundled is List) {
      parsedBundled = rawBundled
          .whereType<Map<String, dynamic>>()
          .map((e) => CourseModel.fromJson(e))
          .toList();
    }

    return CourseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Course',
      description: json['description']?.toString(),
      type: json['type']?.toString().toUpperCase() ?? 'ENGINEERING',
      mode: json['mode']?.toString().toUpperCase() ?? 'LIVE',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      originalPrice: (json['originalPrice'] is num) ? (json['originalPrice'] as num).toDouble() : null,
      isCombo: json['isCombo'] == true || json['combo'] == true,
      includedCourseIds: json['includedCourseIds'] != null ? parseStringList(json['includedCourseIds']) : const [],
      includedCourses: parsedBundled,
      accessDurationMonths: json['accessDurationMonths'] is num
          ? (json['accessDurationMonths'] as num).toInt()
          : null,
      branches: parseStringList(json['branches']),
      branchIds: json['branchIds'] != null ? parseStringList(json['branchIds']) : null,
      year: json['year']?.toString(),
      university: json['university']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      studentsCount: json['studentsCount'] is num
          ? (json['studentsCount'] as num).toInt()
          : 0,
      completionStatus: json['completionStatus']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'mode': mode,
      'price': price,
      'accessDurationMonths': accessDurationMonths,
      'branches': branches,
      'branchIds': branchIds,
      'year': year,
      'university': university,
      'startDate': startDate,
      'endDate': endDate,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'studentsCount': studentsCount,
      'completionStatus': completionStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CourseModel.empty() {
    return const CourseModel(
      id: '',
      name: 'No Course Available',
      price: 0,
    );
  }
}

/// Lecture Model representing video sessions or live interactive classes
class LectureModel {
  final String id;
  final String? lessonId;
  final String title;
  final String? duration; // e.g. "45 mins"
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool isLive;
  final bool isCompleted;
  final NoteModel? note;
  final DateTime? createdAt; // Used for oldest-first sort order

  const LectureModel({
    required this.id,
    this.lessonId,
    required this.title,
    this.duration,
    this.videoUrl,
    this.thumbnailUrl,
    this.isLive = false,
    this.isCompleted = false,
    this.note,
    this.createdAt,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    final rawCreatedAt = json['createdAt']?.toString() ?? json['created_at']?.toString();
    return LectureModel(
      id: json['id']?.toString() ?? '',
      lessonId: _readLessonId(json),
      title: json['title']?.toString() ?? 'Lecture Session',
      duration: json['duration']?.toString() ?? '45 mins',
      videoUrl: json['videoUrl']?.toString() ?? json['url']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      isLive: statusStr == 'LIVE' || json['isLive'] == true,
      isCompleted: json['isCompleted'] == true,
      note: json['note'] != null && json['note'] is Map<String, dynamic>
          ? NoteModel.fromJson(json['note'] as Map<String, dynamic>)
          : null,
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }
}

/// Note Model representing downloadable PDF notes, formula sheets, or PYQs
class NoteModel {
  final String id;
  final String? lessonId;
  final String? lessonTitle;
  final String? videoId;
  final String title;
  final String? scope; // COURSE, GLOBAL, LESSON
  final String? pdfUrl;
  final String? fileSize;
  final String? fileType;
  final bool isGlobal;

  const NoteModel({
    required this.id,
    this.lessonId,
    this.lessonTitle,
    this.videoId,
    required this.title,
    this.scope,
    this.pdfUrl,
    this.fileSize,
    this.fileType,
    this.isGlobal = false,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final scopeStr = json['scope']?.toString().toUpperCase() ?? '';
    final isGlobalOrCourse = scopeStr == 'GLOBAL' || scopeStr == 'COURSE' || json['isGlobal'] == true;

    return NoteModel(
      id: json['id']?.toString() ?? '',
      lessonId: _readLessonId(json),
      lessonTitle: json['lessonTitle']?.toString() ?? json['lesson_title']?.toString() ?? (json['lesson'] is Map ? json['lesson']['title']?.toString() : null),
      videoId: _readVideoId(json),
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Study Material PDF',
      scope: json['scope']?.toString() ?? json['noteScope']?.toString(),
      pdfUrl: json['docUrl']?.toString() ??
          json['pdfUrl']?.toString() ??
          json['fileUrl']?.toString() ??
          json['documentUrl']?.toString() ??
          json['url']?.toString(),
      fileSize: json['fileSize']?.toString() ?? '2.4 MB',
      fileType: json['fileType']?.toString() ?? 'PDF',
      isGlobal: isGlobalOrCourse,
    );
  }
}

/// Supports both flat (`lessonId`) and nested (`lesson: {id: ...}`) API DTOs.
String? _readLessonId(Map<String, dynamic> json) {
  for (final key in const [
    'lessonId',
    'lesson_id',
    'moduleId',
    'module_id',
    'chapterId',
    'chapter_id',
  ]) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }

  for (final key in const ['lesson', 'module']) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is Map) {
      final id = value['id'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    }
  }
  return null;
}

String? _readVideoId(Map<String, dynamic> json) {
  for (final key in const ['videoId', 'video_id', 'lectureId', 'lecture_id']) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  for (final key in const ['video', 'lecture']) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is Map) {
      final id = value['id'];
      if (id != null && id.toString().isNotEmpty) return id.toString();
    }
  }
  return null;
}

/// Lesson Model representing syllabus modules belonging to a course.
class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int lessonIndex;
  final String status;
  final String? createdAt;
  final List<LectureModel> lectures;
  final List<NoteModel> notes;

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.lessonIndex,
    this.status = 'ACTIVE',
    this.createdAt,
    this.lectures = const [],
    this.notes = const [],
  });

  LessonModel copyWith({
    List<LectureModel>? lectures,
    List<NoteModel>? notes,
  }) {
    return LessonModel(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      lessonIndex: lessonIndex,
      status: status,
      createdAt: createdAt,
      lectures: lectures ?? this.lectures,
      notes: notes ?? this.notes,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final rawLectures = _readList(json, const ['lectures', 'videos', 'videoLectures']);
    final rawNotes = _readList(json, const ['notes', 'studyNotes', 'lessonNotes', 'studyMaterials']);

    return LessonModel(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Lesson Module',
      description: json['description']?.toString(),
      lessonIndex: json['lessonIndex'] is num ? (json['lessonIndex'] as num).toInt() : 1,
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt']?.toString(),
      lectures: rawLectures
          .whereType<Map>()
          .map((e) => LectureModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      notes: rawNotes
          .whereType<Map>()
          .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

List<dynamic> _readList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
  }
  return const [];
}

/// Master Setting Item for UI filters (BRANCH, YEAR, UNIVERSITY)
class MasterSettingItem {
  final String id;
  final String type;
  final String name;
  final String? code;
  final String status;

  const MasterSettingItem({
    required this.id,
    required this.type,
    required this.name,
    this.code,
    this.status = 'ACTIVE',
  });

  factory MasterSettingItem.fromJson(Map<String, dynamic> json) {
    return MasterSettingItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

/// Paginated Page Response for GET /api/courses
class CoursePageResponse {
  final List<CourseModel> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  const CoursePageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory CoursePageResponse.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List? ?? [];
    final items = list.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
    final pageable = json['pageable'] as Map<String, dynamic>?;

    return CoursePageResponse(
      content: items,
      pageNumber: pageable?['pageNumber'] ?? json['number'] ?? 0,
      pageSize: pageable?['pageSize'] ?? json['size'] ?? 12,
      totalElements: json['totalElements'] ?? items.length,
      totalPages: json['totalPages'] ?? 1,
      last: json['last'] == true,
    );
  }
}

/// Response DTO from POST /api/courses/{courseId}/purchase-request
class CourseEnrollmentResponse {
  final String id;
  final String? studentName;
  final String? mobileNumber;
  final String? courseName;
  final String? requestDate;
  final String? paymentStatus;
  final String? accessStatus;
  final double? finalPrice;
  final String? transactionRefId;

  const CourseEnrollmentResponse({
    required this.id,
    this.studentName,
    this.mobileNumber,
    this.courseName,
    this.requestDate,
    this.paymentStatus,
    this.accessStatus,
    this.finalPrice,
    this.transactionRefId,
  });

  factory CourseEnrollmentResponse.fromJson(Map<String, dynamic> json) {
    return CourseEnrollmentResponse(
      id: json['id']?.toString() ?? '',
      studentName: json['studentName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      courseName: json['courseName']?.toString(),
      requestDate: json['requestDate']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      accessStatus: json['accessStatus']?.toString() ?? 'Pending',
      finalPrice: json['finalPrice'] is num ? (json['finalPrice'] as num).toDouble() : null,
      transactionRefId: json['transactionRefId']?.toString(),
    );
  }
}
