import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/core/utils/filter_utils.dart';
import 'package:quran_contest_app/data/models/student.dart';
import 'package:quran_contest_app/data/models/competition_level.dart';

void main() {
  final students = [
    Student(name: 'أحمد محمد علي حسن', age: 20, phone: '01012345678', level: 'المستوى الأول', score: 85, gender: 'ذكر'),
    Student(name: 'فاطمة علي محمد حسن', age: 18, phone: '01087654321', level: 'المستوى الأول', score: 92, gender: 'أنثى'),
    Student(name: 'محمد خالد سعيد سالم', age: 25, phone: '01112345678', level: 'المستوى الثاني', score: 70, gender: 'ذكر'),
    Student(name: 'سارة أحمد فوزي محمود', age: 22, phone: '01212345678', level: 'المستوى الثاني', score: null, gender: 'أنثى'),
  ];

  final levels = [
    CompetitionLevel(title: 'المستوى الأول', content: 'القرآن كاملاً', isActive: true, maxAge: 25, maxCapacity: 50),
    CompetitionLevel(title: 'المستوى الثاني', content: 'نصف القرآن', isActive: false, minAge: 18, maxCapacity: 30),
    CompetitionLevel(title: 'المستوى الثالث', content: 'ربع القرآن', isActive: true, minAge: 10, maxAge: 15, maxCapacity: null),
  ];

  group('filterStudents', () {
    test('returns all students with no filters', () {
      final result = filterStudents(students);
      expect(result.length, 4);
    });

    test('filters by level', () {
      final result = filterStudents(students, level: 'المستوى الأول');
      expect(result.length, 2);
    });

    test('filters by min score', () {
      final result = filterStudents(students, minScore: 80);
      expect(result.length, 2);
    });

    test('filters by max score', () {
      final result = filterStudents(students, maxScore: 75);
      expect(result.length, 2);
    });

    test('filters by score range', () {
      final result = filterStudents(students, minScore: 80, maxScore: 90);
      expect(result.length, 1);
    });

    test('students with null score treated as 0', () {
      final result = filterStudents(students, minScore: 0, maxScore: 10);
      expect(result.any((s) => s.score == null), true);
    });

    test('combined filters', () {
      final result = filterStudents(students, level: 'المستوى الأول', minScore: 80);
      expect(result.length, 2);
    });
  });

  group('filterLevels', () {
    test('returns all levels with default status', () {
      final result = filterLevels(levels);
      expect(result.length, 3);
    });

    test('filters active only', () {
      final result = filterLevels(levels, status: 'active');
      expect(result.length, 2);
      expect(result.every((l) => l.isActive), true);
    });

    test('filters inactive only', () {
      final result = filterLevels(levels, status: 'inactive');
      expect(result.length, 1);
      expect(result.first.isActive, false);
    });

    test('filters by minimum age', () {
      final result = filterLevels(levels, minAge: 20);
      expect(result.length, 2); // المستوى الأول (maxAge: 25 >= 20) and المستوى الثاني (maxAge: null = unlimited)
    });

    test('filters by maximum age', () {
      final result = filterLevels(levels, maxAge: 17);
      expect(result.length, 2); // المستوى الأول (maxAge: 25 >= 17) and المستوى الثالث (minAge: 10, maxAge: 15 <= 17)
    });

    test('unlimited capacity level is included', () {
      final result = filterLevels(levels);
      expect(result.any((l) => l.title == 'المستوى الثالث'), true);
    });
  });
}
