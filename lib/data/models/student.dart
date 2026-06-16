class Student {
  final int? id;
  final String name;
  final int age;
  final String phone;
  final String level;
  final int? levelId;
  final double? score;
  final String? nationalId;
  final String? gender;
  final String? memorizerName;
  final String? memorizerPhone;
  final String? memorizerAddress;
  final String? location;
  final String? profileImageUrl;
  final String? birthCertificateUrl;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final String? studentCode;  // e.g. A1001, B0002
  final String? ceremonyCode;
  final DateTime? examDate;
  final int? examHour;
  final bool isWaitlisted;
  final String? selectedRewaya;
  final double? rewayaScore;
  final double? tajweedScore;
  final double? voiceScore;
  final double? meaningScore;
  final String? branchName;
  final int? memorizationAmount;
  final String? ipCity;
  final String? ipRegion;
  final double? ipLat;
  final double? ipLng;

  Student({
    this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.level,
    this.levelId,
    this.score,
    this.nationalId,
    this.gender,
    this.memorizerName,
    this.memorizerPhone,
    this.memorizerAddress,
    this.location,
    this.profileImageUrl,
    this.birthCertificateUrl,
    this.birthDate,
    this.createdAt,
    this.studentCode,
    this.ceremonyCode,
    this.examDate,
    this.examHour,
    this.isWaitlisted = false,
    this.selectedRewaya,
    this.rewayaScore,
    this.tajweedScore,
    this.voiceScore,
    this.meaningScore,
    this.branchName,
    this.memorizationAmount,
    this.ipCity,
    this.ipRegion,
    this.ipLat,
    this.ipLng,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      phone: json['phone'] ?? '',
      level: json['level'] ?? '',
      levelId: json['level_id'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      nationalId: json['national_id'],
      gender: json['gender'],
      memorizerName: json['memorizer_name'],
      memorizerPhone: json['memorizer_phone'],
      memorizerAddress: json['memorizer_address'],
      location: json['location'],
      profileImageUrl: json['profile_image_url'],
      birthCertificateUrl: json['birth_certificate_url'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])?.toLocal()
          : null,
      studentCode: json['student_code'],
      ceremonyCode: json['ceremony_code'],
      examDate: json['exam_date'] != null ? DateTime.tryParse(json['exam_date']) : null,
      examHour: json['exam_hour'],
      isWaitlisted: json['is_waitlisted'] ?? false,
      selectedRewaya: json['selected_rewaya'],
      rewayaScore: (json['rewaya_score'] as num?)?.toDouble(),
      tajweedScore: (json['tajweed_score'] as num?)?.toDouble(),
      voiceScore: (json['voice_score'] as num?)?.toDouble(),
      meaningScore: (json['meaning_score'] as num?)?.toDouble(),
      branchName: json['branch_name'],
      memorizationAmount: json['memorization_amount'] as int?,
      ipCity: json['ip_city'],
      ipRegion: json['ip_region'],
      ipLat: (json['ip_lat'] as num?)?.toDouble(),
      ipLng: (json['ip_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'phone': phone,
      'level': level,
      if (levelId != null) 'level_id': levelId,
      if (score != null) 'score': score,
      if (nationalId != null) 'national_id': nationalId,
      if (gender != null) 'gender': gender,
      if (memorizerName != null) 'memorizer_name': memorizerName,
      if (memorizerPhone != null) 'memorizer_phone': memorizerPhone,
      if (memorizerAddress != null) 'memorizer_address': memorizerAddress,
      if (location != null) 'location': location,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (birthCertificateUrl != null) 'birth_certificate_url': birthCertificateUrl,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T')[0],
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (examDate != null) 'exam_date': examDate!.toIso8601String().split('T')[0],
      if (examHour != null) 'exam_hour': examHour,
      'is_waitlisted': isWaitlisted,
      if (selectedRewaya != null) 'selected_rewaya': selectedRewaya,
      if (rewayaScore != null) 'rewaya_score': rewayaScore,
      if (tajweedScore != null) 'tajweed_score': tajweedScore,
      if (voiceScore != null) 'voice_score': voiceScore,
      if (meaningScore != null) 'meaning_score': meaningScore,
      if (branchName != null) 'branch_name': branchName,
      if (memorizationAmount != null) 'memorization_amount': memorizationAmount,
      if (ipCity != null) 'ip_city': ipCity,
      if (ipRegion != null) 'ip_region': ipRegion,
      if (ipLat != null) 'ip_lat': ipLat,
      if (ipLng != null) 'ip_lng': ipLng,
    };
  }

  /// Used for update — always sends all nullable fields so they can be cleared on the server
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'name': name,
      'age': age,
      'phone': phone,
      'level': level,
      'level_id': levelId,
      'score': score,
      'national_id': nationalId,
      'gender': gender,
      'memorizer_name': memorizerName,
      'memorizer_phone': memorizerPhone,
      'memorizer_address': memorizerAddress,
      'location': location,
      'birth_date': birthDate != null ? birthDate!.toIso8601String().split('T')[0] : null,
      'profile_image_url': profileImageUrl,
      'birth_certificate_url': birthCertificateUrl,
      'selected_rewaya': selectedRewaya,
      'rewaya_score': rewayaScore,
      'tajweed_score': tajweedScore,
      'voice_score': voiceScore,
      'meaning_score': meaningScore,
      'branch_name': branchName,
      'memorization_amount': memorizationAmount,
    };
  }

  // Sentinel object used in copyWith to distinguish "not passed" from explicit null
  static const _unset = _Unset();

  Student copyWith({
    int? id,
    String? name,
    int? age,
    String? phone,
    String? level,
    Object? levelId = _unset,
    Object? score = _unset,
    Object? nationalId = _unset,
    Object? gender = _unset,
    Object? memorizerName = _unset,
    Object? memorizerPhone = _unset,
    Object? memorizerAddress = _unset,
    Object? location = _unset,
    Object? profileImageUrl = _unset,
    Object? birthCertificateUrl = _unset,
    Object? birthDate = _unset,
    Object? createdAt = _unset,
    Object? studentCode = _unset,
    Object? ceremonyCode = _unset,
    Object? examDate = _unset,
    Object? examHour = _unset,
    bool? isWaitlisted,
    Object? selectedRewaya = _unset,
    Object? rewayaScore = _unset,
    Object? tajweedScore = _unset,
    Object? voiceScore = _unset,
    Object? meaningScore = _unset,
    Object? branchName = _unset,
    Object? memorizationAmount = _unset,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      level: level ?? this.level,
      levelId: identical(levelId, _unset) ? this.levelId : levelId as int?,
      score: identical(score, _unset) ? this.score : score as double?,
      nationalId: identical(nationalId, _unset) ? this.nationalId : nationalId as String?,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      memorizerName: identical(memorizerName, _unset) ? this.memorizerName : memorizerName as String?,
      memorizerPhone: identical(memorizerPhone, _unset) ? this.memorizerPhone : memorizerPhone as String?,
      memorizerAddress: identical(memorizerAddress, _unset) ? this.memorizerAddress : memorizerAddress as String?,
      location: identical(location, _unset) ? this.location : location as String?,
      profileImageUrl: identical(profileImageUrl, _unset) ? this.profileImageUrl : profileImageUrl as String?,
      birthCertificateUrl: identical(birthCertificateUrl, _unset) ? this.birthCertificateUrl : birthCertificateUrl as String?,
      birthDate: identical(birthDate, _unset) ? this.birthDate : birthDate as DateTime?,
      createdAt: identical(createdAt, _unset) ? this.createdAt : createdAt as DateTime?,
      studentCode: identical(studentCode, _unset) ? this.studentCode : studentCode as String?,
      ceremonyCode: identical(ceremonyCode, _unset) ? this.ceremonyCode : ceremonyCode as String?,
      examDate: identical(examDate, _unset) ? this.examDate : examDate as DateTime?,
      examHour: identical(examHour, _unset) ? this.examHour : examHour as int?,
      isWaitlisted: isWaitlisted ?? this.isWaitlisted,
      selectedRewaya: identical(selectedRewaya, _unset) ? this.selectedRewaya : selectedRewaya as String?,
      rewayaScore: identical(rewayaScore, _unset) ? this.rewayaScore : rewayaScore as double?,
      tajweedScore: identical(tajweedScore, _unset) ? this.tajweedScore : tajweedScore as double?,
      voiceScore: identical(voiceScore, _unset) ? this.voiceScore : voiceScore as double?,
      meaningScore: identical(meaningScore, _unset) ? this.meaningScore : meaningScore as double?,
      branchName: identical(branchName, _unset) ? this.branchName : branchName as String?,
      memorizationAmount: identical(memorizationAmount, _unset) ? this.memorizationAmount : memorizationAmount as int?,
    );
  }

  double? get totalScore {
    if (score == null && rewayaScore == null && tajweedScore == null && voiceScore == null && meaningScore == null) return null;
    double total = score ?? 0;
    if (rewayaScore != null) total += rewayaScore!;
    if (tajweedScore != null) total += tajweedScore!;
    if (voiceScore != null) total += voiceScore!;
    if (meaningScore != null) total += meaningScore!;
    return total;
  }
}

class _Unset {
  const _Unset();
}
