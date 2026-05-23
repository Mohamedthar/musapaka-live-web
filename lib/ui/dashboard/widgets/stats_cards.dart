import 'package:flutter/material.dart';

class StatEntry {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const StatEntry({required this.title, required this.value, required this.icon, required this.color});
}

class DashboardStatsCards extends StatelessWidget {
  final List<StatEntry> stats;

  const DashboardStatsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 16, isMobile ? 12 : 24, 8),
      child: LayoutBuilder(builder: (ctx, c) {
        // Adjust columns based on the number of stats to fit nicely
        final int count = stats.length;
        // if more than 4, we might want different cols, but mostly 4 or 2
        final int cols = c.maxWidth > 900 ? (count >= 4 ? 4 : count) : (count > 1 ? 2 : 1);
        final double w = (c.maxWidth - (cols - 1) * 12) / cols;
        
        return Wrap(
          spacing: 12, 
          runSpacing: 12, 
          children: stats.map((s) => _card(s, w)).toList(),
        );
      }),
    );
  }

  Widget _card(StatEntry s, double width) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: s.color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: s.color.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: s.color.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(children: [
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
        child: Text(
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
      ),
      const SizedBox(width: 8),
      Text(
        s.value, 
        style: const TextStyle(
          fontFamily: 'Cairo', 
          fontSize: 20, 
          fontWeight: FontWeight.w900, 
          color: Color(0xFF03121C),
        ),
      ),
    ]),
  );
}
