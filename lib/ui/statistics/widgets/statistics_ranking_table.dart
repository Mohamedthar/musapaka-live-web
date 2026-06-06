import 'package:flutter/material.dart';
import '../../../core/utils/ranking_utils.dart';

class StatisticsRankingTable extends StatelessWidget {
  final List<RankedStudent> rankedStudents;
  final bool isMobile;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool)? onSort;

  const StatisticsRankingTable({
    super.key,
    required this.rankedStudents,
    required this.isMobile,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
  });

  static const _primary = Color(0xFF03121C);

  @override
  Widget build(BuildContext context) {
    if (rankedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.military_tech_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج مضافة بعد في هذا المستوى',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإدخال الدرجات من لوحة التحكم لرؤية الترتيب هنا',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    if (isMobile) return _buildMobileList();

    return _buildDesktopTable();
  }

  // ─── Desktop: exactly matches LevelsTable / StudentTable pattern ────────────

  Widget _buildDesktopTable() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final bool needsScroll = constraints.maxWidth < 900;

        final tableContent = Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(44),   // #
            1: FixedColumnWidth(120),  // الترتيب / المركز
            2: FlexColumnWidth(1.5),   // اسم المتسابق
            3: FixedColumnWidth(140),  // كود الحفل
            4: FixedColumnWidth(88),   // المحفوظ
            5: FlexColumnWidth(1.2),   // الهاتف
            6: FlexColumnWidth(1.5),   // الرقم القومي
            7: FixedColumnWidth(130),  // الدرجة
            8: FixedColumnWidth(110),  // النسبة
          },
          children: [
            // ─── Header row (dark background, white text) ────────────────────
            TableRow(
              decoration: const BoxDecoration(color: _primary),
              children: [
                _th('#', center: true, index: 0),
                _th('الترتيب / المركز', center: true, sortable: false),
                _th('اسم المتسابق', index: 1),
                _th('كود الحفل', center: true, sortable: false),
                _th('المحفوظ', center: true, sortable: false),
                _th('الهاتف', center: true, index: 2),
                _th('الرقم القومي', center: true, index: 3),
                _th('الدرجة', center: true, index: 4),
                _th('النسبة', center: true, index: 4),
              ],
            ),
            // ─── Data rows ──────────────────────────────────────────────────
            ...List.generate(rankedStudents.length, (i) {
              final rs = rankedStudents[i];
              void onTap() => _showStudentDetails(ctx, rs);
              return TableRow(
                decoration: BoxDecoration(
                  color: _rowBgColor(rs.rankNumber, i),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                children: [
                  // index number
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // rank badge
                  _td(
                    Center(child: _buildRankBadge(rs)),
                    onTap: onTap,
                  ),
                  // name
                  _td(
                    Text(
                      rs.student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    onTap: onTap,
                  ),
                  // ceremony code
                  _td(
                    Text(
                      rs.student.ceremonyCode ?? '---',
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: rs.student.ceremonyCode != null ? Colors.purple.shade700 : Colors.grey.shade400,
                      ),
                    ),
                    center: true,
                    onTap: onTap,
                  ),
                  // memorization amount
                  _td(
                    _buildMemorizationBadge(rs.student.memorizationAmount),
                    center: true,
                    onTap: onTap,
                  ),
                  // phone
                  _td(
                    Text(
                      rs.student.phone,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    center: true,
                    onTap: onTap,
                  ),
                  // national id
                  _td(
                    Text(
                      rs.student.nationalId?.isNotEmpty == true
                          ? rs.student.nationalId!
                          : '---',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    center: true,
                    onTap: onTap,
                  ),
                  // score badge
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: _buildScoreBadge(rs)),
                      ),
                    ),
                  ),
                  // percentage badge
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: _buildPercentageBadge(rs)),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        );

        // Exact same wrapper as LevelsTable / StudentTable
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
                        constraints: const BoxConstraints(minWidth: 900),
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

  // ─── Mobile List ────────────────────────────────────────────────────────────

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rankedStudents.length,
      itemBuilder: (ctx, i) {
        final rs = rankedStudents[i];
        return InkWell(
          onTap: () => _showStudentDetails(ctx, rs),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _rowBgColor(rs.rankNumber, i),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildMedalIcon(rs.rankNumber, i),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rs.student.name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildRankBadge(rs),
                      if (rs.student.memorizationAmount != null) ...[
                        const SizedBox(height: 4),
                        _buildMemorizationBadge(rs.student.memorizationAmount),
                      ],
                      if (rs.student.ceremonyCode != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'كود الحفل: ${rs.student.ceremonyCode}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        rs.student.phone,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (rs.student.nationalId?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          rs.student.nationalId!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildScoreBadge(rs),
                    const SizedBox(height: 6),
                    _buildPercentageBadge(rs),
                  ],
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _rowBgColor(int rank, int index) {
    if (rank == 1) return Colors.amber.withValues(alpha: 0.04);
    if (rank == 2) return Colors.blueGrey.withValues(alpha: 0.04);
    if (rank == 3) return Colors.brown.withValues(alpha: 0.04);
    return index % 2 == 0 ? Colors.white : const Color(0xFFF9FBFF);
  }

  Widget _buildMedalIcon(int rank, int index) {
    if (rank == 1) {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
      );
    } else if (rank == 2) {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.emoji_events_rounded, color: Colors.blueGrey.shade400, size: 22),
      );
    } else if (rank == 3) {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.brown.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.emoji_events_rounded, color: Colors.brown.shade300, size: 22),
      );
    }
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(RankedStudent rs) {
    Color color;
    Color bg;
    if (rs.rankNumber == 1) {
      color = Colors.amber.shade700;
      bg = Colors.amber.withValues(alpha: 0.1);
    } else if (rs.rankNumber == 2) {
      color = Colors.blueGrey.shade600;
      bg = Colors.blueGrey.withValues(alpha: 0.1);
    } else if (rs.rankNumber == 3) {
      color = Colors.brown.shade400;
      bg = Colors.brown.withValues(alpha: 0.1);
    } else {
      color = Colors.grey.shade700;
      bg = Colors.grey.withValues(alpha: 0.08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        rs.rankTitle,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }


  Widget _buildMemorizationBadge(int? amount) {
    if (amount == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Text(
        amount == 1 ? 'جزء واحد' : amount == 2 ? 'جزئين' : '$amount أجزاء',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildScoreBadge(RankedStudent rs) {
    final score = rs.student.totalScore ?? 0.0;
    final maxScore = rs.maxLevelScore;
    final percentage = rs.percentage / 100.0;
    Color color;
    if (percentage >= 0.95) {
      color = Colors.green;
    } else if (percentage >= 0.75) {
      color = Colors.blue;
    } else if (percentage >= 0.50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${score.truncateToDouble() == score ? score.toInt() : score.toStringAsFixed(1)}/$maxScore',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPercentageBadge(RankedStudent rs) {
    final percentage = rs.percentage;
    Color color;
    if (percentage >= 95) {
      color = Colors.green;
    } else if (percentage >= 75) {
      color = Colors.blue;
    } else if (percentage >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // ─── Table cell builders ─────────────────────────────────────────────────────

  Widget _th(String label, {bool center = false, int? index, bool sortable = true}) {
    Widget content = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );

    if (sortable && index != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.end,
        children: [
          content,
          if (sortColumnIndex == index) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      );
    }

    Widget cell = Container(
      alignment: center ? Alignment.center : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: content,
    );

    if (sortable && index != null && onSort != null) {
      cell = InkWell(
        onTap: () {
          if (sortColumnIndex == index) {
            onSort!(index, !sortAscending);
          } else {
            onSort!(index, false); // Default sort descending for scores, ascending for names
          }
        },
        child: cell,
      );
    }

    return TableCell(child: cell);
  }

  Widget _td(Widget child, {bool center = false, VoidCallback? onTap}) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: center ? Center(child: child) : child,
          ),
        ),
      );

  void _showStudentDetails(BuildContext context, RankedStudent rs) {
    final s = rs.student;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _primary)),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.memorizationAmount != null)
                  _buildDetailRow('عدد الأجزاء المحفوظة', s.memorizationAmount!.toDouble()),
                _buildDetailRow('درجة الحفظ', s.score),
                if (s.rewayaScore != null) _buildDetailRow('درجة الرواية', s.rewayaScore),
                if (s.tajweedScore != null) _buildDetailRow('درجة التجويد', s.tajweedScore),
                if (s.voiceScore != null) _buildDetailRow('درجة الصوت', s.voiceScore),
                if (s.meaningScore != null) _buildDetailRow('درجة المعاني', s.meaningScore),
                const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
                _buildDetailRow('الدرجة الكلية', s.totalScore, isTotal: true),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double? score, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, fontSize: isTotal ? 16 : 14, color: isTotal ? _primary : Colors.grey.shade700)),
          Text(score != null ? (score.truncateToDouble() == score ? score.toInt().toString() : score.toStringAsFixed(1)) : '-', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 15, color: isTotal ? _primary : Colors.black87)),
        ],
      ),
    );
  }
}
