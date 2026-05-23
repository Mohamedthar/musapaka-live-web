import 'package:flutter/material.dart';

class StatisticsKpiCards extends StatelessWidget {
  final int totalStudents;
  final int testedStudents;
  final double highestScore;
  final double lowestScore;
  final int passedCount;
  final int malesCount;
  final int femalesCount;
  final int maxLevelScore;
  final bool isMobile;

  const StatisticsKpiCards({
    super.key,
    required this.totalStudents,
    required this.testedStudents,
    required this.highestScore,
    required this.lowestScore,
    required this.passedCount,
    required this.malesCount,
    required this.femalesCount,
    required this.maxLevelScore,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final int notTested = totalStudents - testedStudents;
    final int percentageTested =
        totalStudents > 0 ? ((testedStudents / totalStudents) * 100).round() : 0;
    final int passPercent =
        testedStudents > 0 ? ((passedCount / testedStudents) * 100).round() : 0;

    final stats = [
      _StatEntry(
        title: 'إجمالي المسجلين',
        value: '$totalStudents',
        sub: 'متسابق في هذا المستوى',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF1565C0),
      ),
      _StatEntry(
        title: 'الذكور',
        value: '$malesCount',
        sub: 'متسابق',
        icon: Icons.male_rounded,
        color: Colors.blue.shade700,
      ),
      _StatEntry(
        title: 'الإناث',
        value: '$femalesCount',
        sub: 'متسابقة',
        icon: Icons.female_rounded,
        color: Colors.pink.shade500,
      ),
      _StatEntry(
        title: 'تم اختبارهم',
        value: '$testedStudents',
        sub: '$percentageTested% من الإجمالي',
        icon: Icons.fact_check_rounded,
        color: Colors.purple,
      ),
      _StatEntry(
        title: 'لم يُختبروا بعد',
        value: '$notTested',
        sub: '${100 - percentageTested}% من الإجمالي',
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
      ),
      _StatEntry(
        title: 'نسبة النجاح',
        value: '$passPercent%',
        sub: '$passedCount ناجح من $testedStudents',
        icon: Icons.verified_rounded,
        color: Colors.teal,
      ),

      _StatEntry(
        title: 'أعلى درجة',
        value: highestScore > 0
            ? '${highestScore.truncateToDouble() == highestScore ? highestScore.toInt() : highestScore.toStringAsFixed(1)}/$maxLevelScore'
            : '—',
        sub: 'المركز الأول',
        icon: Icons.military_tech_rounded,
        color: Colors.amber.shade700,
      ),
      _StatEntry(
        title: 'أدنى درجة',
        value: lowestScore > 0
            ? '${lowestScore.truncateToDouble() == lowestScore ? lowestScore.toInt() : lowestScore.toStringAsFixed(1)}/$maxLevelScore'
            : '—',
        sub: 'آخر المتسابقين',
        icon: Icons.trending_down_rounded,
        color: Colors.red,
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 16, isMobile ? 12 : 24, 8),
      child: LayoutBuilder(builder: (ctx, c) {
      final int count = stats.length;
      int cols;
      if (c.maxWidth > 1100) {
        cols = count >= 7 ? 4 : (count >= 4 ? 4 : count);
      } else if (c.maxWidth > 700) {
        cols = 3;
      } else if (c.maxWidth > 400) {
        cols = 2;
      } else {
        cols = 1;
      }
      final double w = (c.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stats.map((s) => _card(s, w)).toList(),
      );
      }),
    );
  }

  Widget _card(_StatEntry s, double width) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: s.color.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.icon, color: s.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (s.sub != null)
                    Text(
                      s.sub!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: s.color,
              ),
            ),
          ],
        ),
      );
}

class _StatEntry {
  final String title;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;
  const _StatEntry({
    required this.title,
    required this.value,
    this.sub,
    required this.icon,
    required this.color,
  });
}
