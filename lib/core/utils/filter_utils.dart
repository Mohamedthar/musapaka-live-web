import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';

List<Student> filterStudents(
  List<Student> students, {
  String? level,
  double? minScore,
  double? maxScore,
  String? searchQuery,
}) {
  return students.where((s) {
    final matchesLevel = level == null || s.level == level;
    final scoreVal = s.totalScore ?? 0.0;
    final matchesScore = (minScore == null || scoreVal >= minScore) &&
                         (maxScore == null || scoreVal <= maxScore);
    final matchesSearch = searchQuery == null || searchQuery.isEmpty ||
        s.name.contains(searchQuery) ||
        (s.phone.contains(searchQuery)) ||
        (s.nationalId != null && s.nationalId!.contains(searchQuery)) ||
        (s.studentCode != null && s.studentCode!.contains(searchQuery));
    return matchesLevel && matchesScore && matchesSearch;
  }).toList();
}

List<CompetitionLevel> filterLevels(
  List<CompetitionLevel> levels, {
  String status = 'all',
  int? minAge,
  int? maxAge,
}) {
  return levels.where((l) {
    final matchesStatus = status == 'all' ||
        (status == 'active' ? l.isActive : !l.isActive);
    final matchesMin = minAge == null || l.maxAge == null || l.maxAge! >= minAge;
    final matchesMax = maxAge == null || l.minAge == null || l.minAge! <= maxAge;
    return matchesStatus && matchesMin && matchesMax;
  }).toList();
}
