import 'package:flutter/material.dart';

class DashboardSection extends StatelessWidget {
  final bool isRegistrationOpen;
  final int daysCount;
  final int periodsCount;
  final int capacity;
  final Color primaryColor;
  final bool isMobile;

  const DashboardSection({
    super.key,
    required this.isRegistrationOpen,
    required this.daysCount,
    required this.periodsCount,
    required this.capacity,
    required this.primaryColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('حالة النظام الحالية', Icons.radio_button_checked_rounded),
        const SizedBox(height: 12),
        _buildRegistrationStatusCard(),
        const SizedBox(height: 32),
        _buildSectionLabel('ملخص إحصائيات الجدولة', Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        _buildStatsGrid(),
        const SizedBox(height: 32),
        _buildQuickTipsCard(),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationStatusCard() {
    final isOpen = isRegistrationOpen;
    final statusColor = isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bgGrad = isOpen
        ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
        : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)];
    final borderColor = isOpen ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGrad,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with pulse
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOpen ? 'بوابة التسجيل مفتوحة' : 'بوابة التسجيل مغلقة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PulsingLedIndicator(color: statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOpen
                      ? 'يمكن للطلاب التسجيل وتقديم استماراتهم الآن عبر الموقع الإلكتروني.'
                      : 'بوابة التسجيل مغلقة. لن يتمكن الطلاب من إرسال استمارات جديدة.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              isOpen ? 'نشط' : 'مغلق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatCard(
        title: 'أيام الاختبار',
        value: '$daysCount',
        subtitle: 'يوم مُجدَّل',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        accentColor: const Color(0xFFBFDBFE),
      ),
      _StatCard(
        title: 'إجمالي الفترات',
        value: '$periodsCount',
        subtitle: 'فترة عمل نشطة',
        icon: Icons.access_time_rounded,
        color: const Color(0xFFB45309),
        bgColor: const Color(0xFFFEF9C3),
        accentColor: const Color(0xFFFDE68A),
      ),
      _StatCard(
        title: 'الطاقة الاستيعابية',
        value: '$capacity',
        subtitle: 'طالب كحد أقصى',
        icon: Icons.groups_3_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        accentColor: const Color(0xFFDDD6FE),
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStatCardWidget(c),
        )).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildStatCardWidget(c),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCardWidget(_StatCard data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: data.color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: data.color,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'تلميحات وإرشادات سريعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            'استخدم قسم "جدول الفترات" لتحديد مواعيد لجان الاختبار قبل فتح التسجيل.',
            'تأكد من ضبط تواريخ التسجيل والاختبارات في قسم "المواعيد" بدقة.',
            'بعد إغلاق التسجيل، يمكنك تفعيل قسم الاستعلامات للطلاب.',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5, left: 10),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatCard {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.accentColor,
  });
}

// ── Pulsing LED Indicator ───────────────────────────────────────────────
class _PulsingLedIndicator extends StatefulWidget {
  final Color color;
  const _PulsingLedIndicator({required this.color});

  @override
  State<_PulsingLedIndicator> createState() => _PulsingLedIndicatorState();
}

class _PulsingLedIndicatorState extends State<_PulsingLedIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: _opacityAnim.value),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
