import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../datasources/live_lecture_remote_data_source.dart';
import '../models/student_live_lecture_model.dart';

class LiveLectureRepository {
  final LiveLectureRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  bool useMockFallback;

  LiveLectureRepository({
    LiveLectureRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
    this.useMockFallback = false,
  })  : _remoteDataSource = remoteDataSource ?? LiveLectureRemoteDataSource(),
        _localDataSource = localDataSource ?? AuthLocalDataSource();

  /// Fetch live lectures calendar for student's enrolled subjects within [start] and [end]
  Future<List<StudentLiveLecture>> getLiveLecturesCalendar({
    required DateTime start,
    required DateTime end,
    String? courseId,
  }) async {
    final startDateStr = _formatIsoDate(start);
    final endDateStr = _formatIsoDate(end);

    try {
      final token = await _localDataSource.getAccessToken();
      final lectures = await _remoteDataSource.fetchLiveLectureCalendar(
        startDate: startDateStr,
        endDate: endDateStr,
        courseId: courseId,
        token: token,
      );

      if (lectures.isNotEmpty || !useMockFallback) {
        return lectures;
      }
    } on ApiException {
      // Fall through to mock fallback for any API error (including 403)
    } catch (_) {}

    if (useMockFallback) {
      return _getMockLectures(start);
    }

    return [];
  }

  /// Helper to format DateTime as YYYY-MM-DD
  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Mock live lecture dataset following student_live_lectures_api_documentation.md
  List<StudentLiveLecture> _getMockLectures(DateTime referenceDate) {
    final todayStr = _formatIsoDate(referenceDate);

    return [
      StudentLiveLecture(
        id: '7b89f641-8912-4a62-b3fc-2c963f66af10',
        courseId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        courseName: 'Advanced Fluid Mechanics',
        subjectCode: 'MECH-301',
        title: 'Unit 3: Navier-Stokes Equations Live Discussion',
        date: todayStr,
        time: '08:00:00',
        lectureType: LiveLectureType.normal,
        batchDurationDays: 5,
        meetingUrl: 'https://meet.pme.com/room/fluid-mech-live-301',
        cancelledDates: [],
        isCancelledForDate: false,
      ),
      StudentLiveLecture(
        id: '9c12a452-1102-4c62-a3ff-1c963f66bf22',
        courseId: '1a2b3c4d-5717-4562-b3fc-2c963f66afa7',
        courseName: 'Applied Mathematics III',
        subjectCode: 'MATH-302',
        title: 'Batch Workshop - Fourier Transforms & Laplace',
        date: todayStr,
        time: '11:00:00',
        lectureType: LiveLectureType.batch,
        batchDurationDays: 7,
        meetingUrl: 'https://meet.pme.com/room/math-fourier-workshop',
        cancelledDates: [],
        isCancelledForDate: false,
      ),
      StudentLiveLecture(
        id: '4d32e109-7717-4562-b3fc-9c963f66cf33',
        courseId: '5b6c7d8e-5717-4562-b3fc-2c963f66afa8',
        courseName: 'Data Structures & Algorithms',
        subjectCode: 'CS-201',
        title: 'Graph Algorithms & Shortest Path Live Coding',
        date: todayStr,
        time: '14:00:00',
        lectureType: LiveLectureType.normal,
        batchDurationDays: 3,
        meetingUrl: 'https://meet.pme.com/room/dsa-graph-live',
        cancelledDates: [],
        isCancelledForDate: false,
      ),
      StudentLiveLecture(
        id: '2a11b22c-8818-4562-b3fc-1c963f66df44',
        courseId: '9e8d7c6b-5717-4562-b3fc-2c963f66afa9',
        courseName: 'Object Oriented Java',
        subjectCode: 'CS-204',
        title: 'Multi-threading & Memory Management Batch Session',
        date: todayStr,
        time: '18:00:00',
        lectureType: LiveLectureType.batch,
        batchDurationDays: 5,
        meetingUrl: 'https://meet.pme.com/room/java-multithread-live',
        cancelledDates: [],
        isCancelledForDate: false,
      ),
    ];
  }
}
