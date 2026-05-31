import 'package:flutter_test/flutter_test.dart';
import 'package:quran_contest_app/core/utils/ranking_utils.dart';
import 'package:quran_contest_app/data/models/student.dart';
import 'package:quran_contest_app/data/models/competition_level.dart';

void main() {
  final levels = [
    CompetitionLevel(
      title: 'المستوى الأول',
      content: 'القرآن كاملاً',
      isActive: true,
      totalPoints: 100,
      hasRewaya: false,
      hasTajweed: false,
      hasVoice: false,
      hasMeaning: false,
    ),
    CompetitionLevel(
      title: 'المستوى الثاني',
      content: 'نصف القرآن',
      isActive: true,
      totalPoints: 80,
      hasRewaya: true,
      rewayaMaxScore: 20,
      hasTajweed: false,
      hasVoice: false,
      hasMeaning: false,
    ),
    CompetitionLevel(
      title: 'المستوى الثالث',
      content: 'ربع القرآن',
      isActive: false,
      totalPoints: 50,
      hasRewaya: true,
      rewayaMaxScore: 10,
      hasTajweed: true,
      tajweedMaxScore: 10,
      hasVoice: true,
      voiceMaxScore: 10,
      hasMeaning: true,
      meaningMaxScore: 20,
    ),
  ];

  group('getLevelMaxScore', () {
    test('returns totalPoints for level with no extras', () {
      expect(RankingUtils.getLevelMaxScore('المستوى الأول', levels), 100);
    });

    test('returns combined score for level with rewaya', () {
      expect(RankingUtils.getLevelMaxScore('المستوى الثاني', levels), 100);
    });

    test('returns combined score for level with all components', () {
      expect(RankingUtils.getLevelMaxScore('المستوى الثالث', levels), 100);
    });

    test('returns 100 for unknown level (default)', () {
      expect(RankingUtils.getLevelMaxScore('غير موجود', levels), 100);
    });
  });

  group('calculateRanks', () {
    test('ranks students by memorization amount and percentage descending', () {
      final students = [
        Student(name: 'الأول', age: 20, phone: '01000000001', level: 'المستوى الأول', score: 50),
        Student(name: 'الثاني', age: 22, phone: '01000000002', level: 'المستوى الأول', score: 90),
        Student(name: 'الثالث', age: 25, phone: '01000000003', level: 'المستوى الأول', score: 70),
      ];

      final results = RankingUtils.calculateRanks(students, levels);

      expect(results.length, 3);
      // Sorted by percentage descending
      expect(results[0].student.name, 'الثاني');
      expect(results[1].student.name, 'الثالث');
      expect(results[2].student.name, 'الأول');
      // Each has a rank title
      expect(results[0].rankTitle, isNotEmpty);
      expect(results[1].rankTitle, isNotEmpty);
      expect(results[2].rankTitle, isNotEmpty);
    });

    test('handles tied scores with same rank number', () {
      final students = [
        Student(name: 'الأول', age: 20, phone: '01000000001', level: 'المستوى الأول', score: 80),
        Student(name: 'الثاني', age: 22, phone: '01000000002', level: 'المستوى الأول', score: 80),
      ];

      final results = RankingUtils.calculateRanks(students, levels);

      expect(results.length, 2);
      expect(results[0].rankNumber, results[1].rankNumber);
      expect(results[0].isTied, true);
      expect(results[1].isTied, true);
    });

    test('handles null scores', () {
      final students = [
        Student(name: 'بنتيجة', age: 20, phone: '01000000001', level: 'المستوى الأول', score: 10),
        Student(name: 'بدون نتيجة', age: 22, phone: '01000000002', level: 'المستوى الأول'),
      ];

      final results = RankingUtils.calculateRanks(students, levels);
      // student without score is filtered out
      expect(results.length, 1);
      expect(results[0].student.name, 'بنتيجة');
    });

    test('calculates percentage', () {
      final students = [
        Student(name: 'طالب', age: 20, phone: '01000000001', level: 'المستوى الأول', score: 75),
      ];

      final results = RankingUtils.calculateRanks(students, levels);
      expect(results[0].maxLevelScore, 100);
    });

    test('empty list returns empty', () {
      final results = RankingUtils.calculateRanks([], levels);
      expect(results, isEmpty);
    });
  });
}
