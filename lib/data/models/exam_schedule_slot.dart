import 'dart:convert';

/// One row in `app_settings.exam_schedule`.
///
/// Stored in JSON as half-open interval **[startHour, endHour)** (same as before):
/// - `start_hour`: first hour included (e.g. 8 → work during 08:00–09:00 period).
/// - `end_hour`: exclusive upper bound; last worked hour is `endHour - 1`.
///
/// UI presents **inclusive** «من … إلى … شاملاً» via [lastInclusiveHour].
class ExamScheduleSlot {
  ExamScheduleSlot({
    this.date,
    this.startHour = 8,
    this.endHour = 12,
    this.studentsPerHour = 4,
  }) {
    if (endHour <= startHour) endHour = startHour + 1;
  }

  DateTime? date;

  /// First hour included (0–23).
  int startHour;

  /// Exclusive end (1–24). Hours counted: startHour … endHour−1.
  int endHour;

  /// Last hour included in the block (what the admin selects as «إلى الساعة» شاملاً).
  int get lastInclusiveHour => endHour - 1;

  set lastInclusiveHour(int value) {
    endHour = value + 1;
    if (endHour <= startHour) endHour = startHour + 1;
  }

  int studentsPerHour;

  static const int minStartHour = 6;

  /// Latest hour that can be included as end of a slot (23 → 11 مساءً).
  static const int maxLastInclusiveHour = 23;

  /// Accepts Supabase `DATE`, ISO strings, local `DateTime`, or `"yyyy-MM-dd HH:mm:ss"`.
  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return DateTime(v.year, v.month, v.day);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final datePart =
        s.contains('T') ? s.split('T').first : s.split(RegExp(r'\s+')).first;
    final parts = datePart.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  factory ExamScheduleSlot.fromJson(Map<String, dynamic> json) {
    final start = (json['start_hour'] as num?)?.toInt() ?? 8;
    var endExcl = (json['end_hour'] as num?)?.toInt() ?? (start + 1);
    if (endExcl <= start) endExcl = start + 1;
    if (endExcl > maxLastInclusiveHour + 1) endExcl = maxLastInclusiveHour + 1;
    return ExamScheduleSlot(
      date: parseDate(json['date']),
      startHour: start,
      endHour: endExcl,
      studentsPerHour: (json['students_per_hour'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    String? dateStr;
    final d = date;
    if (d != null) {
      dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return {
      if (dateStr != null) 'date': dateStr,
      'start_hour': startHour,
      'end_hour': endHour,
      'students_per_hour': studentsPerHour,
    };
  }

  int get durationHours => endHour - startHour;

  int get estimatedStudentCapacity => durationHours * studentsPerHour;

  ExamScheduleSlot copyWith({
    DateTime? date,
    int? startHour,
    int? endHour,
    int? studentsPerHour,
  }) {
    return ExamScheduleSlot(
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      studentsPerHour: studentsPerHour ?? this.studentsPerHour,
    );
  }

  /// After changing [startHour], keep at least one hour and caps within the day.
  void clampInclusiveRange() {
    if (startHour < minStartHour) startHour = minStartHour;
    if (startHour > maxLastInclusiveHour) startHour = maxLastInclusiveHour;
    if (endHour <= startHour) endHour = startHour + 1;
    if (endHour > maxLastInclusiveHour + 1) endHour = maxLastInclusiveHour + 1;
  }

  /// Half-open overlap on the same calendar day.
  bool overlaps(ExamScheduleSlot other) {
    final da = date;
    final db = other.date;
    if (da == null || db == null) return false;
    if (da.year != db.year || da.month != db.month || da.day != db.day) return false;
    return startHour < other.endHour && other.startHour < endHour;
  }

  static String hourCaptionAr(int hour) {
    if (hour < 0 || hour > 24) return '${hour.toString().padLeft(2, '0')}:00';
    if (hour == 0 || hour == 24) {
      return '12 منتصف الليل';
    } else if (hour < 12) {
      return '$hour صباحاً';
    } else if (hour == 12) {
      return '12 ظهراً';
    } else {
      return '${hour - 12} مساءً';
    }
  }

  static List<ExamScheduleSlot> listFromJson(dynamic raw) {
    if (raw == null) return [];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == 'null') return [];
      try {
        final decoded = jsonDecode(trimmed);
        return listFromJson(decoded);
      } catch (_) {
        return [];
      }
    }
    if (raw is! List) return [];
    return raw.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ExamScheduleSlot.fromJson(map);
    }).toList();
  }
}
