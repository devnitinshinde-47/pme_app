import 'package:flutter_test/flutter_test.dart';
import 'package:pawanmateeducation/features/courses/data/models/course_model.dart';
import 'package:pawanmateeducation/features/courses/data/repositories/course_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CourseModel Serialization Test', () {
    test('CourseModel correctly parses JSON with university and thumbnail', () {
      final jsonMap = {
        "id": "c100",
        "name": "SPPU Advanced Fluid Mechanics",
        "description": "Fluid Mechanics for SPPU B.Tech",
        "type": "ENGINEERING",
        "mode": "REGULAR",
        "price": 3499.0,
        "accessDurationMonths": 12,
        "branches": ["Mechanical Engineering"],
        "year": "3rd Year",
        "university": "SPPU",
        "thumbnailUrl": "https://r2.pme.com/fluid.webp",
        "status": "ACTIVE",
        "studentsCount": 142
      };

      final course = CourseModel.fromJson(jsonMap);

      expect(course.id, equals('c100'));
      expect(course.name, equals('SPPU Advanced Fluid Mechanics'));
      expect(course.university, equals('SPPU'));
      expect(course.type, equals('ENGINEERING'));
      expect(course.thumbnailUrl, equals('https://r2.pme.com/fluid.webp'));
      expect(course.price, equals(3499.0));
      expect(course.studentsCount, equals(142));
    });

    test('NoteModel accepts flat and nested lesson references', () {
      final flatNote = NoteModel.fromJson({
        'id': 'note-flat',
        'lessonId': 'lesson-1',
        'title': 'Flat lesson note',
      });
      final nestedNote = NoteModel.fromJson({
        'id': 'note-nested',
        'lesson': {'id': 'lesson-2'},
        'title': 'Nested lesson note',
      });

      expect(flatNote.lessonId, equals('lesson-1'));
      expect(nestedNote.lessonId, equals('lesson-2'));
    });
  });

  group('CourseRepository Filter Test (MSBTE, SPPU, DBATU)', () {
    late CourseRepository repository;

    setUp(() {
      repository = CourseRepository(useMockFallback: true);
    });

    test('getCourses filters by MSBTE university correctly', () async {
      final response = await repository.getCourses(university: 'MSBTE');
      expect(response.content, isNotEmpty);
      for (final course in response.content) {
        expect(course.university, equals('MSBTE'));
      }
    });

    test('getCourses filters by SPPU university correctly', () async {
      final response = await repository.getCourses(university: 'SPPU');
      expect(response.content, isNotEmpty);
      for (final course in response.content) {
        expect(course.university, equals('SPPU'));
      }
    });

    test('getCourses filters by DBATU university correctly', () async {
      final response = await repository.getCourses(university: 'DBATU');
      expect(response.content, isNotEmpty);
      for (final course in response.content) {
        expect(course.university, equals('DBATU'));
      }
    });

    test('getCourses filters by POLYTECHNIC type correctly', () async {
      final response = await repository.getCourses(type: 'POLYTECHNIC');
      expect(response.content, isNotEmpty);
      for (final course in response.content) {
        expect(course.type, equals('POLYTECHNIC'));
      }
    });
  });
}
