import 'package:flutter/material.dart';

class SettingsNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const SettingsNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class SettingsSidebar extends StatelessWidget {
  final String activeSection;
  final List<SettingsNavItem> items;
  final ValueChanged<String> onItemSelected;
  final bool isTablet;
  final Color primaryColor;

  const SettingsSidebar({
    super.key,
    required this.activeSection,
    required this.items,
    required this.onItemSelected,
    required this.isTablet,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isTablet ? 72 : 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isTablet) ...[
            // Sidebar header branding
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'لوحة الإعدادات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'التحكم الكامل بإعدادات النظام',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'الأقسام',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 12, vertical: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.id == activeSection;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSidebarItem(item, isSelected),
                );
              },
            ),
          ),
          // Bottom version badge
          if (!isTablet)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 8),
                  Text(
                    'بيئة الإنتاج النشطة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(SettingsNavItem item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(item.id),
        borderRadius: BorderRadius.circular(12),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        splashColor: primaryColor.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 0 : 14,
            vertical: isTablet ? 14 : 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: isTablet
              ? Tooltip(
                  message: item.label,
                  preferBelow: false,
                  textStyle: const TextStyle(fontFamily: 'Cairo'),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? primaryColor
                          : Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                  ),
                )
              : Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected
                            ? primaryColor
                            : Colors.white.withValues(alpha: 0.4),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          if (!isSelected)
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
