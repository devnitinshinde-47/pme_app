import 'package:flutter_test/flutter_test.dart';
import 'package:pawanmateeducation/features/home/data/models/student_live_lecture_model.dart';
import 'package:pawanmateeducation/features/home/data/repositories/live_lecture_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudentLiveLecture Model & Security Test', () {
    test('fromJson parses API response accurately', () {
      final json = {
        'id': '7b89f641-8912-4a62-b3fc-2c963f66af10',
        'courseId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'courseName': 'Advanced Fluid Mechanics',
        'subjectCode': 'MECH-301',
        'title': 'Unit 3: Navier-Stokes Equations Live Discussion',
        'date': '2026-08-03',
        'time': '10:30:00',
        'lectureType': 'NORMAL',
        'batchDurationDays': 5,
        'meetingUrl': 'https://meet.pme.com/room/fluid-mech-live-301',
        'cancelledDates': ['2026-08-05'],
        'isCancelledForDate': false,
        'enrollmentValidUntil': '2027-07-31',
        'zakToken': 'sample_zak_token_123',
        'zoomAccessToken': 'sample_zoom_access_token_456'
      };

      final lecture = StudentLiveLecture.fromJson(json);

      expect(lecture.id, '7b89f641-8912-4a62-b3fc-2c963f66af10');
      expect(lecture.courseName, 'Advanced Fluid Mechanics');
      expect(lecture.subjectCode, 'MECH-301');
      expect(lecture.lectureType, LiveLectureType.normal);
      expect(lecture.batchDurationDays, 5);
      expect(lecture.cancelledDates, contains('2026-08-05'));
      expect(lecture.zakToken, 'sample_zak_token_123');
      expect(lecture.zoomAccessToken, 'sample_zoom_access_token_456');
    });

    test('Daily Expansion Logic (occursOnDate)', () {
      final lecture = StudentLiveLecture(
        id: '1',
        courseId: 'c1',
        courseName: 'Test Course',
        title: 'Batch Lecture',
        date: '2026-08-01',
        time: '10:00:00',
        lectureType: LiveLectureType.batch,
        batchDurationDays: 3, // 2026-08-01, 2026-08-02, 2026-08-03
        meetingUrl: 'https://meet.com/room',
        cancelledDates: ['2026-08-02'],
      );

      expect(lecture.occursOnDate(DateTime(2026, 8, 1)), isTrue);
      expect(lecture.occursOnDate(DateTime(2026, 8, 2)), isFalse); // Cancelled
      expect(lecture.occursOnDate(DateTime(2026, 8, 3)), isTrue);
      expect(lecture.occursOnDate(DateTime(2026, 8, 4)), isFalse); // Out of range
    });

    test('Meeting URL Security 15-minute protection rule', () {
      final lecture = StudentLiveLecture(
        id: '1',
        courseId: 'c1',
        courseName: 'Test Course',
        title: 'Live Lecture',
        date: '2026-08-01',
        time: '10:00:00',
        meetingUrl: 'https://meet.com/room',
      );

      final start = DateTime(2026, 8, 1, 10, 0);

      // 30 mins before start -> NOT joinable
      final t30MinsBefore = start.subtract(const Duration(minutes: 30));
      expect(lecture.isJoinableNow(nowOverride: t30MinsBefore), isFalse);

      // 10 mins before start -> Joinable
      final t10MinsBefore = start.subtract(const Duration(minutes: 10));
      expect(lecture.isJoinableNow(nowOverride: t10MinsBefore), isTrue);

      // During class (20 mins into class) -> Joinable
      final tDuring = start.add(const Duration(minutes: 20));
      expect(lecture.isJoinableNow(nowOverride: tDuring), isTrue);
    });

    test('Zoom Web Client URL & ID extraction', () {
      final zoomLecture = StudentLiveLecture(
        id: '1',
        courseId: 'c1',
        courseName: 'Maths III',
        title: 'Fourier Transforms',
        date: '2026-08-01',
        time: '10:00:00',
        meetingUrl: 'https://zoom.us/j/98765432100?pwd=secretpasscode',
      );

      expect(zoomLecture.zoomMeetingId, '98765432100');
      expect(zoomLecture.zoomPasscode, 'secretpasscode');

      final webUrl = zoomLecture.getZoomWebClientUrl(studentName: 'Rahul Sharma');
      expect(webUrl, contains('https://zoom.us/wc/join/98765432100'));
      expect(webUrl, contains('un=Rahul%20Sharma'));
      expect(webUrl, contains('pwd=secretpasscode'));
    });
  });

  group('LiveLectureRepository Test', () {
    test('getLiveLecturesCalendar returns scheduled lectures list', () async {
      final repo = LiveLectureRepository(useMockFallback: true);
      final today = DateTime.now();
      final lectures = await repo.getLiveLecturesCalendar(
        start: today,
        end: today.add(const Duration(days: 7)),
      );

      expect(lectures, isNotEmpty);
      expect(lectures.first.courseName, contains('Fluid Mechanics'));
    });
  });
}
