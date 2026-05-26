import 'package:flutter/material.dart';

enum DashboardView { dashboard, levels, statistics, settings }

class DashboardSidebar extends StatefulWidget {
  final DashboardView currentView;
  final Function(DashboardView) onViewChanged;
  final VoidCallback onLogout;
  final Color primaryColor;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String settingsSection;
  final Function(String) onSettingsSectionChanged;

  const DashboardSidebar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    required this.onLogout,
    required this.primaryColor,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.settingsSection,
    required this.onSettingsSectionChanged,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _widthAnim;
  late Animation<double> _labelFade;

  static const double _expandedWidth = 260.0;
  static const double _collapsedWidth = 68.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.collapsed ? 0.0 : 1.0,
    );
    _widthAnim = Tween<double>(begin: _collapsedWidth, end: _expandedWidth)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _labelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DashboardSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapsed != oldWidget.collapsed) {
      widget.collapsed ? _animCtrl.reverse() : _animCtrl.forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final showLabels = _animCtrl.value > 0.65;
        final isSettings = widget.currentView == DashboardView.settings;

        return ClipRect(
          child: SizedBox(
            width: _widthAnim.value,
            child: Container(
              width: _expandedWidth,
              color: widget.primaryColor,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Logo + Name ─────────────────────────────────────────
                  if (showLabels)
                    FadeTransition(
                      opacity: _labelFade,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo_musapaka.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'مسابقة أهل القرآن الكبرى بالديدامون',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_musapaka.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Toggle button ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: showLabels
                          ? AlignmentDirectional.centerEnd
                          : Alignment.center,
                      child: Tooltip(
                        message: widget.collapsed ? 'فتح القائمة' : 'طي القائمة',
                        child: InkWell(
                          onTap: widget.onToggleCollapse,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              showLabels
                                  ? Icons.keyboard_double_arrow_right_rounded
                                  : Icons.keyboard_double_arrow_left_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Navigation items ─────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _sideItem(
                            Icons.dashboard_rounded,
                            'لوحة التحكم',
                            widget.currentView == DashboardView.dashboard,
                            showLabels: showLabels,
                            onTap: () => widget.onViewChanged(DashboardView.dashboard),
                          ),
                          _sideItem(
                            Icons.layers_rounded,
                            'المستويات وشروطها',
                            widget.currentView == DashboardView.levels,
                            showLabels: showLabels,
                            onTap: () => widget.onViewChanged(DashboardView.levels),
                          ),
                          _sideItem(
                            Icons.analytics_rounded,
                            'الإحصائيات والنتائج',
                            widget.currentView == DashboardView.statistics,
                            showLabels: showLabels,
                            onTap: () => widget.onViewChanged(DashboardView.statistics),
                          ),

                          // ── Settings parent item ──────────────────────────
                          _sideItem(
                            Icons.settings_rounded,
                            'إعدادات النظام',
                            isSettings,
                            showLabels: showLabels,
                            onTap: () {
                              widget.onViewChanged(DashboardView.settings);
                            },
                          ),

                          // ── Settings sub-items (only when in settings & expanded) ──
                          if (isSettings && showLabels) ...[
                            _subItem(
                              icon: Icons.calendar_today_rounded,
                              label: 'المواعيد واللجان',
                              isActive: widget.settingsSection == 'dates',
                              onTap: () => widget.onSettingsSectionChanged('dates'),
                            ),
                            _subItem(
                              icon: Icons.view_timeline_rounded,
                              label: 'جدول الفترات',
                              isActive: widget.settingsSection == 'schedule',
                              onTap: () => widget.onSettingsSectionChanged('schedule'),
                            ),
                            _subItem(
                              icon: Icons.help_outline_rounded,
                              label: 'الأسئلة الشائعة',
                              isActive: widget.settingsSection == 'faqs',
                              onTap: () => widget.onSettingsSectionChanged('faqs'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  const SizedBox(height: 4),
                  _sideItem(
                    Icons.logout_rounded,
                    'تسجيل الخروج',
                    false,
                    showLabels: showLabels,
                    onTap: widget.onLogout,
                    isDestructive: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _subItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 8, bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // vertical line connector
              Container(
                width: 2,
                height: 18,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    String title,
    bool active, {
    VoidCallback? onTap,
    required bool showLabels,
    bool isDestructive = false,
  }) {
    final Color iconColor = isDestructive
        ? Colors.red.shade300
        : active
            ? Colors.white
            : Colors.white54;
    final Color textColor = isDestructive
        ? Colors.red.shade200
        : active
            ? Colors.white
            : Colors.white60;

    return Tooltip(
      message: showLabels ? '' : title,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: showLabels
                ? Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeTransition(
                          opacity: _labelFade,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: textColor,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (active)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                : Center(child: Icon(icon, color: iconColor, size: 22)),
          ),
        ),
      ),
    );
  }
}
