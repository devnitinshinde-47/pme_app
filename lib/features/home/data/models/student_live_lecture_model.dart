
/// Enum representing live lecture type: NORMAL or BATCH
enum LiveLectureType {
  normal,
  batch;

  static LiveLectureType fromString(String? type) {
    if (type?.toUpperCase() == 'BATCH') {
      return LiveLectureType.batch;
    }
    return LiveLectureType.normal;
  }

  String toServerString() {
    switch (this) {
      case LiveLectureType.batch:
        return 'BATCH';
      case LiveLectureType.normal:
        return 'NORMAL';
    }
  }
}

/// Model representing a scheduled live lecture returned from the Spring Boot API
/// `GET /api/student/live-lectures/calendar` or `GET /api/student/courses/{courseId}/live-lectures`.
class StudentLiveLecture {
  final String id;
  final String courseId;
  final String courseName;
  final String? subjectCode;
  final String title;
  final String date; // ISO Date YYYY-MM-DD
  final String time; // HH:mm:ss or HH:mm
  final LiveLectureType lectureType;
  final int batchDurationDays;
  final String meetingUrl;
  final List<String> cancelledDates;
  final bool isCancelledForDate;
  final String? enrollmentValidUntil;
  final String? zakToken;
  final String? zoomAccessToken;

  const StudentLiveLecture({
    required this.id,
    required this.courseId,
    required this.courseName,
    this.subjectCode,
    required this.title,
    required this.date,
    required this.time,
    this.lectureType = LiveLectureType.normal,
    this.batchDurationDays = 1,
    required this.meetingUrl,
    this.cancelledDates = const [],
    this.isCancelledForDate = false,
    this.enrollmentValidUntil,
    this.zakToken,
    this.zoomAccessToken,
  });

  factory StudentLiveLecture.fromJson(Map<String, dynamic> json) {
    List<String> parsedCancelled = [];
    if (json['cancelledDates'] != null && json['cancelledDates'] is List) {
      parsedCancelled = (json['cancelledDates'] as List).map((e) => e.toString()).toList();
    }

    return StudentLiveLecture(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? 'Live Course',
      subjectCode: json['subjectCode']?.toString(),
      title: json['title']?.toString() ?? 'Live Discussion',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '00:00:00',
      lectureType: LiveLectureType.fromString(json['lectureType']?.toString()),
      batchDurationDays: (json['batchDurationDays'] is num) ? (json['batchDurationDays'] as num).toInt() : 1,
      meetingUrl: json['meetingUrl']?.toString() ?? '',
      cancelledDates: parsedCancelled,
      isCancelledForDate: json['isCancelledForDate'] == true,
      enrollmentValidUntil: json['enrollmentValidUntil']?.toString(),
      zakToken: json['zakToken']?.toString() ?? json['zoomToken']?.toString(),
      zoomAccessToken: json['zoomAccessToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'subjectCode': subjectCode,
      'title': title,
      'date': date,
      'time': time,
      'lectureType': lectureType.toServerString(),
      'batchDurationDays': batchDurationDays,
      'meetingUrl': meetingUrl,
      'cancelledDates': cancelledDates,
      'isCancelledForDate': isCancelledForDate,
      'enrollmentValidUntil': enrollmentValidUntil,
      'zakToken': zakToken,
      'zoomAccessToken': zoomAccessToken,
    };
  }

  /// Parse start DateTime combining date and time
  DateTime? get startDateTime {
    try {
      if (date.isEmpty) return null;
      final timeParts = time.split(':');
      final hour = timeParts.isNotEmpty ? int.parse(timeParts[0]) : 0;
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      final startDate = DateTime.parse(date);
      return DateTime(startDate.year, startDate.month, startDate.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  /// Start Date without time (midnight)
  DateTime? get parsedStartDate {
    try {
      if (date.isEmpty) return null;
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  /// End Date calculated with batchDurationDays
  DateTime? get parsedEndDate {
    final start = parsedStartDate;
    if (start == null) return null;
    final duration = batchDurationDays > 0 ? batchDurationDays - 1 : 0;
    return DateTime(start.year, start.month, start.day).add(Duration(days: duration));
  }

  /// Check if the lecture recurs/occurs on [selectedDate]
  bool occursOnDate(DateTime selectedDate) {
    final start = parsedStartDate;
    final end = parsedEndDate;
    if (start == null || end == null) return false;

    final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final startDateOnly = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(end.year, end.month, end.day);

    if (target.isBefore(startDateOnly) || target.isAfter(endDateOnly)) {
      return false;
    }

    // Check cancelled dates
    final isoDateStr = "${target.year.toString().padLeft(4, '0')}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}";
    if (cancelledDates.contains(isoDateStr)) {
      return false;
    }

    // Check enrollment validity
    if (enrollmentValidUntil != null && enrollmentValidUntil!.isNotEmpty) {
      try {
        final validUntil = DateTime.parse(enrollmentValidUntil!);
        if (target.isAfter(validUntil)) {
          return false;
        }
      } catch (_) {}
    }

    return true;
  }

  /// Security Rule: Meeting URL Protection
  /// Returns true if meeting can be joined (within 15 minutes before scheduled start time or ongoing)
  bool isJoinableNow({DateTime? nowOverride}) {
    final start = startDateTime;
    if (start == null) return false;

    final now = nowOverride ?? DateTime.now();
    final joinWindowStart = start.subtract(const Duration(minutes: 15));
    // Class duration default 90 mins window for joining
    final joinWindowEnd = start.add(const Duration(minutes: 90));

    return now.isAfter(joinWindowStart) && now.isBefore(joinWindowEnd);
  }

  /// Extract Zoom Meeting ID from meetingUrl
  String get zoomMeetingId {
    if (meetingUrl.isEmpty) return '89124567890';
    final regExp = RegExp(r'/j/(\d+)');
    final match = regExp.firstMatch(meetingUrl);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    final nums = meetingUrl.replaceAll(RegExp(r'[^0-9]'), '');
    if (nums.length >= 9) {
      return nums.substring(0, 11.clamp(0, nums.length));
    }
    return '89124567890';
  }

  /// Extract Zoom Passcode if embedded in meetingUrl (?pwd=...)
  String get zoomPasscode {
    if (meetingUrl.contains('pwd=')) {
      try {
        final uri = Uri.parse(meetingUrl);
        return uri.queryParameters['pwd'] ?? '';
      } catch (_) {}
    }
    return '';
  }

  /// Generate Zoom Web Client SDK launch URL
  String getZoomWebClientUrl({String? studentName}) {
    final name = Uri.encodeComponent((studentName != null && studentName.isNotEmpty) ? studentName : 'Student');
    final pwd = zoomPasscode.isNotEmpty ? '&pwd=$zoomPasscode' : '';
    if (meetingUrl.startsWith('http://') || meetingUrl.startsWith('https://')) {
      if (meetingUrl.contains('zoom.us/j/')) {
        final id = zoomMeetingId;
        return 'https://zoom.us/wc/join/$id?prefer=1&un=$name$pwd';
      }
      return meetingUrl;
    }
    return 'https://zoom.us/wc/join/$zoomMeetingId?prefer=1&un=$name$pwd';
  }
}
