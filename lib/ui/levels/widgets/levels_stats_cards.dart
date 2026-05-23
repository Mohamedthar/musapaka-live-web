import 'package:flutter/material.dart';

class LevelsStatsCards extends StatelessWidget {
  final int totalLevels;
  final int activeLevels;
  final int inactiveLevels;
  final int totalStudents;
  final Color primaryColor;

  const LevelsStatsCards({
    super.key,
    required this.totalLevels,
    required this.activeLevels,
    required this.inactiveLevels,
    required this.totalStudents,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 16, isMobile ? 12 : 24, 8),
      child: LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 900 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          _statCard('إجمالي المستويات', '$totalLevels', Icons.layers_rounded, Colors.blue, w),
          _statCard('المستويات النشطة', '$activeLevels', Icons.check_circle_rounded, Colors.green, w),
          _statCard('المعطلة مؤقتاً', '$inactiveLevels', Icons.pause_circle_rounded, Colors.orange, w),
          _statCard('إجمالي الطلاب', '$totalStudents', Icons.group_rounded, Colors.purple, w),
        ]);
      }),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, double w) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
      ]),
    );
  }
}
