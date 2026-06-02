class CompetitionLevel {
  final int? id;
  final String title;
  final String content;
  final String? notes;
  final int? minAge;
  final int? maxAge;
  final String? ageOp;
  final int? maxCapacity;
  final bool isActive;
  final String? levelCode;  // A, B, C...
  final int? totalPoints;   // e.g., 100 for a level
  final bool hasRewaya;
  final int rewayaMaxScore;
  final List<String> availableRewayas;
  final bool hasTajweed;
  final int tajweedMaxScore;
  final bool hasVoice;
  final int voiceMaxScore;
  final bool hasMeaning;
  final int meaningMaxScore;
  final List<String> branches;
  final bool requireCustomAmount;
  final String? firstPrize;
  final String? secondPrize;
  final String? thirdPrize;
  final String? prizes;    // إذا وُجد، له الأولوية على first_prize/second_prize/third_prize في العرض

  CompetitionLevel({
    this.id,
    required this.title,
    required this.content,
    this.notes,
    this.minAge,
    this.maxAge,
    this.ageOp,
    this.maxCapacity,
    this.isActive = true,
    this.levelCode,
    this.totalPoints,
    this.hasRewaya = false,
    this.rewayaMaxScore = 100,
    this.availableRewayas = const [],
    this.hasTajweed = false,
    this.tajweedMaxScore = 100,
    this.hasVoice = false,
    this.voiceMaxScore = 100,
    this.hasMeaning = false,
    this.meaningMaxScore = 100,
    this.branches = const [],
    this.requireCustomAmount = false,
    this.firstPrize,
    this.secondPrize,
    this.thirdPrize,
    this.prizes,
  });

  factory CompetitionLevel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final content = json['content'] as String?;
    return CompetitionLevel(
      title: title ?? '',
      content: content ?? '',
      id: json['id'],
      notes: json['notes'],
      minAge: json['min_age'],
      maxAge: json['max_age'],
      ageOp: json['age_op'] ?? json['age_op'],
      maxCapacity: json['max_capacity'],
      isActive: json['is_active'] ?? true,
      levelCode: json['level_code'],
      totalPoints: json['total_points'],
      hasRewaya: json['has_rewaya'] ?? false,
      rewayaMaxScore: json['rewaya_max_score'] ?? 100,
      availableRewayas: (json['available_rewayas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      hasTajweed: json['has_tajweed'] ?? false,
      tajweedMaxScore: json['tajweed_max_score'] ?? 100,
      hasVoice: json['has_voice'] ?? false,
      voiceMaxScore: json['voice_max_score'] ?? 100,
      hasMeaning: json['has_meaning'] ?? false,
      meaningMaxScore: json['meaning_max_score'] ?? 100,
      branches: (json['branches'] as List?)?.map((e) => e.toString()).toList() ?? [],
      requireCustomAmount: json['require_custom_amount'] ?? false,
      firstPrize: json['first_prize'],
      secondPrize: json['second_prize'],
      thirdPrize: json['third_prize'],
      prizes: json['prizes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'notes': notes,
      'min_age': minAge,
      'max_age': maxAge,
      if (ageOp != null) 'age_op': ageOp,
      'max_capacity': maxCapacity,
      'is_active': isActive,
      if (levelCode != null) 'level_code': levelCode,
      if (totalPoints != null) 'total_points': totalPoints,
      'has_rewaya': hasRewaya,
      'rewaya_max_score': rewayaMaxScore,
      'available_rewayas': availableRewayas,
      'has_tajweed': hasTajweed,
      'tajweed_max_score': tajweedMaxScore,
      'has_voice': hasVoice,
      'voice_max_score': voiceMaxScore,
      'has_meaning': hasMeaning,
      'meaning_max_score': meaningMaxScore,
      'branches': branches,
      'require_custom_amount': requireCustomAmount,
      if (firstPrize != null) 'first_prize': firstPrize,
      if (secondPrize != null) 'second_prize': secondPrize,
      if (thirdPrize != null) 'third_prize': thirdPrize,
      if (prizes != null) 'prizes': prizes,
    };
  }

  static const _Unset _unset = _Unset();

  CompetitionLevel copyWith({
    int? id,
    String? title,
    String? content,
    Object? notes = _unset,
    Object? minAge = _unset,
    Object? maxAge = _unset,
    Object? ageOp = _unset,
    Object? maxCapacity = _unset,
    bool? isActive,
    Object? levelCode = _unset,
    Object? totalPoints = _unset,
    bool? hasRewaya,
    int? rewayaMaxScore,
    List<String>? availableRewayas,
    bool? hasTajweed,
    int? tajweedMaxScore,
    bool? hasVoice,
    int? voiceMaxScore,
    bool? hasMeaning,
    int? meaningMaxScore,
    List<String>? branches,
    bool? requireCustomAmount,
    Object? firstPrize = _unset,
    Object? secondPrize = _unset,
    Object? thirdPrize = _unset,
    Object? prizes = _unset,
  }) {
    return CompetitionLevel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      minAge: identical(minAge, _unset) ? this.minAge : minAge as int?,
      maxAge: identical(maxAge, _unset) ? this.maxAge : maxAge as int?,
      ageOp: identical(ageOp, _unset) ? this.ageOp : ageOp as String?,
      maxCapacity: identical(maxCapacity, _unset) ? this.maxCapacity : maxCapacity as int?,
      isActive: isActive ?? this.isActive,
      levelCode: identical(levelCode, _unset) ? this.levelCode : levelCode as String?,
      totalPoints: identical(totalPoints, _unset) ? this.totalPoints : totalPoints as int?,
      hasRewaya: hasRewaya ?? this.hasRewaya,
      rewayaMaxScore: rewayaMaxScore ?? this.rewayaMaxScore,
      availableRewayas: availableRewayas ?? this.availableRewayas,
      hasTajweed: hasTajweed ?? this.hasTajweed,
      tajweedMaxScore: tajweedMaxScore ?? this.tajweedMaxScore,
      hasVoice: hasVoice ?? this.hasVoice,
      voiceMaxScore: voiceMaxScore ?? this.voiceMaxScore,
      hasMeaning: hasMeaning ?? this.hasMeaning,
      meaningMaxScore: meaningMaxScore ?? this.meaningMaxScore,
      branches: branches ?? this.branches,
      requireCustomAmount: requireCustomAmount ?? this.requireCustomAmount,
      firstPrize: identical(firstPrize, _unset) ? this.firstPrize : firstPrize as String?,
      secondPrize: identical(secondPrize, _unset) ? this.secondPrize : secondPrize as String?,
      thirdPrize: identical(thirdPrize, _unset) ? this.thirdPrize : thirdPrize as String?,
      prizes: identical(prizes, _unset) ? this.prizes : prizes as String?,
    );
  }

  bool ageMatches(int age) {
    final op = ageOp;
    if (op != null && op != 'all') {
      switch (op) {
        case 'gt':  return minAge != null && age > minAge!;
        case 'gte': return minAge != null && age >= minAge!;
        case 'lt':  return maxAge != null && age < maxAge!;
        case 'lte': return maxAge != null && age <= maxAge!;
        case 'range': return (minAge == null || age >= minAge!) && (maxAge == null || age <= maxAge!);
      }
    }
    return (minAge == null || age >= minAge!) && (maxAge == null || age <= maxAge!);
  }

  String get ageDescription {
    final op = ageOp;
    if (op != null && op != 'all') {
      switch (op) {
        case 'gt':  return 'السن > $minAge';
        case 'gte': return 'السن ≥ $minAge';
        case 'lt':  return 'السن < $maxAge';
        case 'lte': return 'السن ≤ $maxAge';
        case 'range': return 'من $minAge إلى $maxAge سنة';
      }
    }
    if (minAge != null && maxAge != null) return 'من $minAge إلى $maxAge سنة';
    if (minAge != null) return 'السن ≥ $minAge';
    if (maxAge != null) return 'السن ≤ $maxAge';
    return 'جميع الأعمار';
  }

  int get totalMaxPoints {
    int total = totalPoints ?? 100;
    if (hasRewaya && rewayaMaxScore > 0) total += rewayaMaxScore;
    if (hasTajweed && tajweedMaxScore > 0) total += tajweedMaxScore;
    if (hasVoice && voiceMaxScore > 0) total += voiceMaxScore;
    if (hasMeaning && meaningMaxScore > 0) total += meaningMaxScore;
    return total;
  }

  static CompetitionLevel? findByTitle(List<CompetitionLevel> levels, String? title) {
    if (title == null) return null;
    try {
      return levels.firstWhere((l) => l.title == title);
    } catch (_) {
      return null;
    }
  }
}

class _Unset {
  const _Unset();
}
