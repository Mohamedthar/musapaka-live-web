import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/competition_level.dart';
import '../../../data/models/student.dart';

class StudentTable extends StatelessWidget {
  final List<Student> students;
  final List<CompetitionLevel> levels;
  final Set<int> selectedIds;
  final Function(int, bool) onSelectionChanged;
  final VoidCallback onSelectAll;
  final Function(Student) onStudentTap;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int) onSort;
  final Color primaryColor;
  final Set<int> revealedIds;
  final Function(int) onToggleReveal;
  final Function(Student) onEdit;
  final Function(Student) onPrint;
  final Function(Student) onDelete;
  final Function(Student, double) onAddScore;
  final ScreenType? screenType;

  const StudentTable({
    super.key,
    required this.students,
    required this.levels,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onStudentTap,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.primaryColor,
    required this.revealedIds,
    required this.onToggleReveal,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    required this.onAddScore,
    this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    if (screenType == ScreenType.mobile) return _buildMobileCards();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final needsScroll = constraints.maxWidth < 1000;

        final tableContent = Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(50),
            1: FlexColumnWidth(2.6),
            2: FlexColumnWidth(1.8),
            3: FlexColumnWidth(2.2),
            4: FlexColumnWidth(2.2),
            5: FlexColumnWidth(0.8),
            6: FlexColumnWidth(1.4),
            7: FixedColumnWidth(50),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: primaryColor),
              children: [
                _thCheckbox(),
                _thSortable('الاسم', 0),
                _th('رقم الهاتف'),
                _th('الرقم القومي'),
                _thSortable('المستوى', 3),
                _thSortable('العمر', 4, alignment: Alignment.center),
                _thSortable('الدرجة', 5, alignment: Alignment.center),
                _th(''),
              ],
            ),
            ...students.map(_tableRow),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: needsScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 1250),
                        child: tableContent,
                      ),
                    )
                  : tableContent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (ctx, i) {
        final student = students[i];
        final isSelected = selectedIds.contains(student.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isSelected ? primaryColor.withValues(alpha: 0.02) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          elevation: isSelected ? 2 : 0.5,
          shadowColor: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.black12,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onStudentTap(student),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionsMenu(student),
                      const SizedBox(width: 8),
                      Expanded(child: _mobileHeader(student, isSelected)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: Color(0xFF03121C)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _levelLabel(student),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF03121C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(
                        Icons.star_outline_rounded,
                        student.score != null ? '${student.score} درجة' : 'بدون درجة',
                        Colors.teal,
                      ),
                      if (student.examDate != null)
                        _infoChip(
                          Icons.calendar_today_outlined,
                          '${student.examDate!.day}/${student.examDate!.month}',
                          Colors.blueGrey,
                        ),
                      if (student.examHour != null)
                        _infoChip(
                          Icons.access_time_outlined,
                          _formatHour(student.examHour!),
                          Colors.blueGrey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _mobileHeader(Student student, bool isSelected) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: isSelected,
          onChanged: student.id != null
              ? (v) => onSelectionChanged(student.id!, v ?? false)
              : null,
          activeColor: primaryColor,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            image: student.profileImageUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(student.profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: student.profileImageUrl == null
              ? Icon(Icons.person, size: 24, color: Colors.grey.shade400)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  if (student.gender != null) ...[
                    Icon(
                      student.gender == 'ذكر'
                          ? Icons.male_rounded
                          : Icons.female_rounded,
                      size: 14,
                      color: student.gender == 'ذكر'
                          ? Colors.blue
                          : Colors.pink,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF03121C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (student.studentCode != null)
                _studentCodeBadge(student.studentCode!, compact: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final amPm = hour >= 12 ? 'م' : 'ص';
    return '$h:00 $amPm';
  }

  Widget _studentCodeBadge(String code, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _th(String label) => TableCell(
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  Widget _thSortable(
    String label,
    int index, {
    Alignment alignment = Alignment.centerRight,
  }) {
    final active = sortColumnIndex == index;
    return TableCell(
      child: InkWell(
        onTap: () => onSort(index),
        child: Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 4),
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _thCheckbox() {
    final allSelected =
        students.isNotEmpty && selectedIds.length == students.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Checkbox(
        value: allSelected,
        activeColor: Colors.white,
        checkColor: primaryColor,
        side: const BorderSide(color: Colors.white70),
        onChanged: (_) => onSelectAll(),
      ),
    );
  }

  TableRow _tableRow(Student student) {
    final isSelected = selectedIds.contains(student.id);
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withValues(alpha: 0.3) : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Checkbox(
              value: isSelected,
              onChanged: student.id != null
                  ? (val) => onSelectionChanged(student.id!, val ?? false)
                  : null,
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        _td(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  image: student.profileImageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            student.profileImageUrl!,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: student.profileImageUrl == null
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (student.gender != null) ...[
                          Icon(
                            student.gender == 'ذكر'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            size: 14,
                            color: student.gender == 'ذكر'
                                ? Colors.blue
                                : Colors.pink,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            student.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF03121C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (student.studentCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.studentCode!,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${student.createdAt?.day ?? '--'}/${student.createdAt?.month ?? '--'}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          student,
        ),
        _td(
          Text(
            student.phone,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          student,
        ),
        _td(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  revealedIds.contains(student.id)
                      ? (student.nationalId ?? '---')
                      : (student.nationalId != null
                          ? '••••••••••••••'
                          : '---'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    letterSpacing: revealedIds.contains(student.id) ? 0 : 1.5,
                  ),
                ),
              ),
              if (student.nationalId != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onToggleReveal(student.id!),
                  child: Icon(
                    revealedIds.contains(student.id)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 15,
                    color: Colors.blue.shade300,
                  ),
                ),
              ],
            ],
          ),
          student,
        ),
        _td(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _levelLabel(student),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          student,
        ),
        _td(
          Center(
            child: Text(
              '${student.age}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          student,
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Center(child: _scoreWidget(student)),
          ),
        ),
        _td(_actionsMenu(student)),
      ],
    );
  }

  Widget _td(Widget child, [Student? student]) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: InkWell(
          onTap: student == null ? null : () => onStudentTap(student),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      );

  Widget _actionsMenu(Student student) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: (val) {
        if (val == 'edit') {
          onEdit(student);
        } else if (val == 'print') {
          onPrint(student);
        } else if (val == 'delete') {
          onDelete(student);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text('تعديل البيانات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          ]),
        ),
        const PopupMenuItem(
          value: 'print',
          child: Row(children: [
            Icon(Icons.print_rounded, size: 18, color: Colors.teal),
            SizedBox(width: 8),
            Text('طباعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_rounded, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  Widget _scoreWidget(Student student) {
    final score = student.score;
    Color color;
    if (score == null) {
      color = Colors.grey;
    } else if (score < 50) {
      color = Colors.red;
    } else if (score < 75) {
      color = Colors.orange;
    } else if (score < 90) {
      color = Colors.blue;
    } else {
      color = Colors.green;
    }

    final level = CompetitionLevel.findByTitle(levels, student.level);

    return _ScoreCell(
      student: student,
      level: level,
      color: color,
      onTap: () => onStudentTap(student),
    );
  }

  String _levelLabel(Student student) {
    final level = CompetitionLevel.findByTitle(levels, student.level);
    final branchSuffix = student.branchName != null && student.branchName!.isNotEmpty ? ' (${student.branchName})' : '';
    if (level == null) return '${student.level}${student.selectedRewaya != null && student.selectedRewaya!.isNotEmpty ? ' - ${student.selectedRewaya}' : ''}$branchSuffix';
    return '${level.title} - ${level.content}${student.selectedRewaya != null && student.selectedRewaya!.isNotEmpty ? ' - ${student.selectedRewaya}' : ''}$branchSuffix';
  }
}

// ─── Score Badge Cell: read-only, redirects to details panel on tap ───
class _ScoreCell extends StatelessWidget {
  final Student student;
  final CompetitionLevel? level;
  final Color color;
  final VoidCallback onTap;

  const _ScoreCell({
    required this.student,
    this.level,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = student.score;
    final level = this.level;
    final maxPoints = level?.totalMaxPoints ?? 100;
    final totalScore = student.totalScore;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: score != null ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: score != null ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          ),
        ),
        child: score != null
            ? Text(
                '${AppTheme.formatScore(totalScore ?? score)}/$maxPoints',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              )
            : Text(
                '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
      ),
    );
  }
}
