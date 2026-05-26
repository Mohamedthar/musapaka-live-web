import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';

class RankedStudent {
  final Student student;
  final int rankNumber;
  final bool isTied;
  final String rankTitle;
  final double percentage;
  final int maxLevelScore;

  RankedStudent({
    required this.student,
    required this.rankNumber,
    required this.isTied,
    required this.rankTitle,
    required this.percentage,
    required this.maxLevelScore,
  });
}

class RankingUtils {
  /// Converts a number to its Arabic rank title
  static String _getArabicRank(int rank) {
    switch (rank) {
      case 1: return 'المركز الأول';
      case 2: return 'المركز الثاني';
      case 3: return 'المركز الثالث';
      case 4: return 'المركز الرابع';
      case 5: return 'المركز الخامس';
      case 6: return 'المركز السادس';
      case 7: return 'المركز السابع';
      case 8: return 'المركز الثامن';
      case 9: return 'المركز التاسع';
      case 10: return 'المركز العاشر';
      default: return 'المركز $rank';
    }
  }

  static int getLevelMaxScore(String levelName, List<CompetitionLevel> levels) {
    String normalizeArabic(String text) {
      return text
        .replaceAll('ي', 'ى').replaceAll('أ', 'ا').replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا').replaceAll('ة', 'ه')
        .replaceAll('المستو', 'المستوى')
        .trim();
    }

    final normalized = normalizeArabic(levelName);
    try {
      return levels.firstWhere((l) => normalizeArabic(l.title) == normalized).totalMaxPoints;
    } catch (_) {
      try {
        return levels.firstWhere((l) => normalizeArabic(l.title).contains(normalized) || normalized.contains(normalizeArabic(l.title))).totalMaxPoints;
      } catch (_) {
        return 100;
      }
    }
  }

  /// Calculates dense ranks for a list of students based on their percentage.
  /// Ignores students with null scores.
  static List<RankedStudent> calculateRanks(List<Student> students, List<CompetitionLevel> levels) {
    // 1. Filter out students without scores
    final scoredStudents = students.where((s) => s.totalScore != null).toList();

    // 2. Map to a structure holding percentage
    final tempScored = scoredStudents.map((s) {
      final maxScore = getLevelMaxScore(s.level, levels);
      final percentage = maxScore > 0 ? (s.totalScore! / maxScore) * 100 : 0.0;
      return _TempScored(s, percentage, maxScore, s.memorizationAmount);
    }).toList();

    // 3. Sort by memorization amount descending first, then percentage descending
    tempScored.sort((a, b) {
      final amountCompare = (b.memorizationAmount ?? 0).compareTo(a.memorizationAmount ?? 0);
      if (amountCompare != 0) return amountCompare;
      return b.percentage.compareTo(a.percentage);
    });

    if (tempScored.isEmpty) return [];

    final List<RankedStudent> rankedList = [];
    int currentRank = 1;
    double? previousPct;
    List<_TempScored> currentTieGroup = [];

    void processTieGroup() {
      if (currentTieGroup.isEmpty) return;

      bool isTied = currentTieGroup.length > 1;
      String baseTitle = _getArabicRank(currentRank);
      String finalTitle = isTied ? '$baseTitle مكرر' : baseTitle;

      for (var ts in currentTieGroup) {
        rankedList.add(RankedStudent(
          student: ts.student,
          rankNumber: currentRank,
          isTied: isTied,
          rankTitle: finalTitle,
          percentage: ts.percentage,
          maxLevelScore: ts.maxScore,
        ));
      }
    }

    for (var ts in tempScored) {
      // Round to 2 decimals to avoid tiny floating point differences causing ties to fail
      double roundedPct = double.parse(ts.percentage.toStringAsFixed(2));

      if (previousPct == null) {
        currentTieGroup.add(ts);
        previousPct = roundedPct;
      } else if (roundedPct == previousPct) {
        currentTieGroup.add(ts);
      } else {
        processTieGroup();
        currentRank++;
        currentTieGroup = [ts];
        previousPct = roundedPct;
      }
    }

    // Process the last group
    processTieGroup();

    return rankedList;
  }
}

class _TempScored {
  final Student student;
  final double percentage;
  final int maxScore;
  final int? memorizationAmount;
  _TempScored(this.student, this.percentage, this.maxScore, this.memorizationAmount);
}
