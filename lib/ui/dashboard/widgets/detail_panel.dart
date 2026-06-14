import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';

import '../../../data/models/student.dart';
import '../../../data/models/competition_level.dart';
import '../../../data/models/exam_schedule_slot.dart';
import '../../shared/widgets/gender_safe_image.dart';


class StudentDetailPanel extends StatelessWidget {
  final Student student;
  final Color primaryColor;
  final TextEditingController scoreController;
  final TextEditingController? rewayaScoreController;
  final TextEditingController? tajweedScoreController;
  final TextEditingController? voiceScoreController;
  final TextEditingController? meaningScoreController;
  final CompetitionLevel? level;
  final bool isUpdating;
  final VoidCallback onClose;
  final VoidCallback onSaveScore;
  final VoidCallback onEdit;
  final Function(Student) onPrint;
  final Function(int) onDelete;

  final double? width;

  const StudentDetailPanel({
    super.key,
    required this.student,
    required this.primaryColor,
    required this.scoreController,
    this.rewayaScoreController,
    this.tajweedScoreController,
    this.voiceScoreController,
    this.meaningScoreController,
    this.level,
    required this.isUpdating,
    required this.onClose,
    required this.onSaveScore,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Container(
      width: isMobile ? double.infinity : (width ?? 400),
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        boxShadow: isMobile ? [] : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        child: Column(children: [
          if (isMobile) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: primaryColor,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 15),
              const Text('بيانات المتسابق',
                  style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const Spacer(),
              InkWell(
                onTap: onClose,
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close, color: Colors.white, size: 18)),
              ),
            ]),
          ),

          // Content
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Profile Image
              GenderSafeImage(
                gender: student.gender,
                image: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: primaryColor.withValues(alpha: 0.08), width: 3),
                ),
                child: Validator.isValidImageUrl(student.profileImageUrl)
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: student.profileImageUrl!,
                          placeholder: (_, __) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.person,
                                  size: 40, color: Colors.grey)),
                          errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.person,
                                  size: 40, color: Colors.grey)),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.person,
                            size: 40, color: Colors.grey),
                      ),
                ),
              ),
              const SizedBox(height: 10),
              Text(student.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', 
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryColor)),
              const SizedBox(height: 8),

              // Badges & Info Chips Row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (student.studentCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            student.studentCode!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _infoChip(Icons.cake_outlined, '${student.age} سنة', Colors.amber.shade800),
                  if (student.gender != null)
                    _infoChip(Icons.wc_outlined, student.gender!, Colors.blue.shade700),
                  if (student.location != null)
                    _infoChip(Icons.location_on_outlined, student.location!, Colors.teal.shade700),
                ],
              ),

              const SizedBox(height: 20),

              // Card 1: البيانات التعليمية والاختبار
              _infoGroup('البيانات التعليمية والاختبار', Icons.menu_book_rounded, [
                _infoItem(Icons.school_outlined, 'مستوى الحفظ', 
                    '${student.level}${level?.content != null ? ' - ${level!.content}' : ''}${student.selectedRewaya != null && student.selectedRewaya!.isNotEmpty ? ' - ${student.selectedRewaya}' : ''}${student.branchName != null && student.branchName!.isNotEmpty ? ' (${student.branchName})' : ''}'),
                if (student.nationalId != null)
                  _infoItem(Icons.badge_outlined, 'الرقم القومي', student.nationalId!),
                if (student.birthDate != null)
                  _infoItem(Icons.calendar_today_outlined, 'تاريخ الميلاد', 
                      "${student.birthDate!.year}-${student.birthDate!.month.toString().padLeft(2, '0')}-${student.birthDate!.day.toString().padLeft(2, '0')}"),
                if (student.examDate != null && student.examHour != null)
                  _infoItem(Icons.event_available_rounded, 'موعد الاختبار', 
                      "${student.examDate!.year}-${student.examDate!.month.toString().padLeft(2, '0')}-${student.examDate!.day.toString().padLeft(2, '0')} - ${ExamScheduleSlot.hourCaptionAr(student.examHour!)}"),
              ]),

              const SizedBox(height: 16),

              // Card 2: التواصل والمحفظ
              _infoGroup('بيانات التواصل والمحفظ', Icons.contact_phone_rounded, [
                _infoItem(Icons.phone_outlined, 'رقم هاتف الطالب / ولي الأمر', student.phone),
                if (student.memorizerName != null)
                  _infoItem(Icons.person_outline, 'اسم محفظ الطالب', student.memorizerName!),
                if (student.memorizerPhone != null)
                  _infoItem(Icons.phone_iphone_rounded, 'هاتف محفظ الطالب', student.memorizerPhone!),
                if (student.memorizerAddress != null)
                  _infoItem(Icons.location_on_outlined, 'عنوان محفظ الطالب', student.memorizerAddress!),
              ]),

              const SizedBox(height: 24),

              // Score Section
              AnimatedBuilder(
                animation: Listenable.merge([
                  scoreController,
                  if (rewayaScoreController != null) rewayaScoreController!,
                  if (tajweedScoreController != null) tajweedScoreController!,
                  if (voiceScoreController != null) voiceScoreController!,
                  if (meaningScoreController != null) meaningScoreController!,
                ]),
                builder: (context, _) {
                  final sVal = double.tryParse(scoreController.text.trim()) ?? 0.0;
                  final rVal = (level?.hasRewaya ?? false) ? (double.tryParse(rewayaScoreController?.text.trim() ?? '') ?? 0.0) : 0.0;
                  final tVal = (level?.hasTajweed ?? false) ? (double.tryParse(tajweedScoreController?.text.trim() ?? '') ?? 0.0) : 0.0;
                  final vVal = (level?.hasVoice ?? false) ? (double.tryParse(voiceScoreController?.text.trim() ?? '') ?? 0.0) : 0.0;
                  final mVal = (level?.hasMeaning ?? false) ? (double.tryParse(meaningScoreController?.text.trim() ?? '') ?? 0.0) : 0.0;
                  final totalSum = sVal + rVal + tVal + vVal + mVal;
                  
                  final maxTotal = (level?.totalPoints ?? 100) + 
                                   ((level?.hasRewaya ?? false) ? (level!.rewayaMaxScore) : 0) + 
                                   ((level?.hasTajweed ?? false) ? (level!.tajweedMaxScore) : 0) +
                                   ((level?.hasVoice ?? false) ? (level!.voiceMaxScore) : 0) +
                                   ((level?.hasMeaning ?? false) ? (level!.meaningMaxScore) : 0);
                                   
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, right: 4),
                        child: Row(
                          children: [
                            Icon(Icons.stars_rounded, size: 18, color: primaryColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text('تقييم المتسابق', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Main Score
                            _scoreInputRow(
                              label: 'درجة الحفظ',
                              controller: scoreController,
                              color: primaryColor,
                              icon: Icons.star_rounded,
                              maxPoints: level?.totalPoints ?? 100,
                            ),

                            // Rewaya Score (conditional)
                            if ((level?.hasRewaya ?? false) && rewayaScoreController != null) ...[  
                              const SizedBox(height: 8),
                              _scoreInputRow(
                                label: 'درجة الرواية',
                                controller: rewayaScoreController!,
                                color: Colors.indigo,
                                icon: Icons.menu_book_rounded,
                                maxPoints: level!.rewayaMaxScore,
                                suffix: student.selectedRewaya != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(student.selectedRewaya!,
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10,
                                            fontWeight: FontWeight.w700, color: Colors.indigo.shade700)),
                                    )
                                  : null,
                              ),
                            ],

                            // Tajweed Score (conditional)
                            if ((level?.hasTajweed ?? false) && tajweedScoreController != null) ...[  
                              const SizedBox(height: 8),
                              _scoreInputRow(
                                label: 'درجة التجويد',
                                controller: tajweedScoreController!,
                                color: Colors.teal,
                                icon: Icons.record_voice_over_rounded,
                                maxPoints: level!.tajweedMaxScore,
                              ),
                            ],

                            // Voice Score (conditional)
                            if ((level?.hasVoice ?? false) && voiceScoreController != null) ...[  
                              const SizedBox(height: 8),
                              _scoreInputRow(
                                label: 'حلاوة الصوت والتأثير',
                                controller: voiceScoreController!,
                                color: Colors.deepPurple,
                                icon: Icons.mic_none_rounded,
                                maxPoints: level!.voiceMaxScore,
                              ),
                            ],

                            // Meaning Score (conditional)
                            if ((level?.hasMeaning ?? false) && meaningScoreController != null) ...[  
                              const SizedBox(height: 8),
                              _scoreInputRow(
                                label: 'فهم المعاني',
                                controller: meaningScoreController!,
                                color: Colors.amber.shade800,
                                icon: Icons.psychology_rounded,
                                maxPoints: level!.meaningMaxScore,
                              ),
                            ],

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Icon(Icons.stars_rounded, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('الدرجة الكلية المحسوبة:',
                                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                ]),
                                Text('${totalSum.toStringAsFixed(totalSum.truncateToDouble() == totalSum ? 0 : 1)} من $maxTotal',
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 15, color: primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUpdating ? null : onSaveScore,
                  icon: isUpdating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ التقييم',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),

              const SizedBox(height: 24),

              // Edit, Print & Delete
              isMobile 
              ? Column(children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('تعديل البيانات',
                          style: TextStyle(fontFamily: 'Cairo', 
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onPrint(student),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('طباعة البيانات',
                            style: TextStyle(fontFamily: 'Cairo', 
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onDelete(student.id!),
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('حذف',
                            style: TextStyle(fontFamily: 'Cairo', 
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ])
              : Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('تعديل البيانات',
                        style: TextStyle(fontFamily: 'Cairo', 
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => onPrint(student),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('طباعة البيانات',
                        style: TextStyle(fontFamily: 'Cairo', 
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => onDelete(student.id!),
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('حذف',
                        style: TextStyle(fontFamily: 'Cairo', 
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),

              const SizedBox(height: 24),

              // Documents
              if (Validator.isValidImageUrl(student.profileImageUrl) ||
                  Validator.isValidImageUrl(student.birthCertificateUrl)) ...[
                Text('المستندات المرفقة',
                    style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryColor)),
                const SizedBox(height: 12),
                Row(children: [
                  if (Validator.isValidImageUrl(student.profileImageUrl))
                      Expanded(
                        child: _docCard(
                            student.profileImageUrl!, 'الصورة الشخصية', student.gender)),
                  if (Validator.isValidImageUrl(student.profileImageUrl) &&
                      Validator.isValidImageUrl(student.birthCertificateUrl))
                    const SizedBox(width: 12),
                  if (Validator.isValidImageUrl(student.birthCertificateUrl))
                    Expanded(
                        child: _docCard(
                            student.birthCertificateUrl!, 'شهادة الميلاد', student.gender)),
                ]),
              ],
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _scoreInputRow({
    required String label,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
    required int maxPoints,
    Widget? suffix,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(من $maxPoints)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 8),
                    suffix,
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 85,
              height: 38,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.shade300,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _infoGroup(String title, IconData icon, List<Widget> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: primaryColor.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: items),
        ),
      ]);

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: Text(val,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontFamily: 'Cairo', 
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87))),
        ]),
      );

  Widget _docCard(String url, String label, String? gender) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GenderSafeImage(
          gender: gender,
          image: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url, 
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.red.shade50,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 24, color: Colors.red.shade300),
                        const SizedBox(height: 4),
                        Text(
                          'فشل تحميل الصورة', 
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade600)),
      ]);

}

