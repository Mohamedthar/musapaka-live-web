class CompetitionLevel {
  final int? id;
  final String title;
  final String content;
  final String? notes;
  final int? minAge;
  final int? maxAge;
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

  CompetitionLevel({
    this.id,
    required this.title,
    required this.content,
    this.notes,
    this.minAge,
    this.maxAge,
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
  });

  factory CompetitionLevel.fromJson(Map<String, dynamic> json) {
    return CompetitionLevel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      notes: json['notes'],
      minAge: json['min_age'],
      maxAge: json['max_age'],
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
    };
  }

  CompetitionLevel copyWith({
    int? id,
    String? title,
    String? content,
    String? notes,
    int? minAge,
    int? maxAge,
    int? maxCapacity,
    bool? isActive,
    String? levelCode,
    int? totalPoints,
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
    String? firstPrize,
    String? secondPrize,
    String? thirdPrize,
  }) {
    return CompetitionLevel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      notes: notes ?? this.notes,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      isActive: isActive ?? this.isActive,
      levelCode: levelCode ?? this.levelCode,
      totalPoints: totalPoints ?? this.totalPoints,
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
      firstPrize: firstPrize ?? this.firstPrize,
      secondPrize: secondPrize ?? this.secondPrize,
      thirdPrize: thirdPrize ?? this.thirdPrize,
    );
  }

  int get totalMaxPoints {
    int total = totalPoints ?? 100;
    if (hasRewaya) total += rewayaMaxScore;
    if (hasTajweed) total += tajweedMaxScore;
    if (hasVoice) total += voiceMaxScore;
    if (hasMeaning) total += meaningMaxScore;
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
