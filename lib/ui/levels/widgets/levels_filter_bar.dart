import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class LevelsFilterBar extends StatelessWidget {
  final String currentFilterStatus;
  final Function(String) onStatusChanged;
  final Function(String) onSearchChanged;
  final int selectedIdsCount;
  final bool bulkUpdating;
  final bool bulkDeleting;
  final VoidCallback onBulkActivate;
  final VoidCallback onBulkDeactivate;
  final VoidCallback onBulkDelete;
  final int filteredCount;
  final Color primaryColor;

  const LevelsFilterBar({
    super.key,
    required this.currentFilterStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.selectedIdsCount,
    required this.bulkUpdating,
    required this.bulkDeleting,
    required this.onBulkActivate,
    required this.onBulkDeactivate,
    required this.onBulkDelete,
    required this.filteredCount,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    Widget rowContent = Row(children: [
      _filterDropdown(isMobile: isMobile),
      SizedBox(width: isMobile ? 8 : 12),
      isMobile
          ? SizedBox(width: 150, child: _searchField(isMobile: isMobile))
          : Expanded(child: _searchField(isMobile: isMobile)),
      if (selectedIdsCount > 0) ...[
        SizedBox(width: isMobile ? 6 : 8),
        _bulkActionBtn(
          'تنشيط ($selectedIdsCount)',
          Icons.check_circle_rounded,
          AppTheme.successColor,
          bulkUpdating ? null : onBulkActivate,
          isMobile,
        ),
        SizedBox(width: isMobile ? 6 : 8),
        _bulkActionBtn(
          'تعطيل ($selectedIdsCount)',
          Icons.cancel_rounded,
          AppTheme.warningColor,
          bulkUpdating ? null : onBulkDeactivate,
          isMobile,
        ),
        SizedBox(width: isMobile ? 6 : 8),
        _bulkActionBtn(
          'حذف ($selectedIdsCount)',
          Icons.delete_sweep_rounded,
          AppTheme.errorColor,
          bulkDeleting ? null : onBulkDelete,
          isMobile,
        ),
      ],
      SizedBox(width: isMobile ? 8 : 12),
      _resultsCount(filteredCount),
    ]);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 6),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SizedBox(
        height: 40,
        child: isMobile 
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: rowContent)
          : rowContent,
      ),
    );
  }

  Widget _bulkActionBtn(String label, IconData icon, Color color, VoidCallback? onTap, bool isMobile) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _filterDropdown({required bool isMobile}) {
    return Container(
      height: 40,
      constraints: BoxConstraints(maxWidth: isMobile ? 130 : 180, minWidth: isMobile ? 100 : 140),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentFilterStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: isMobile ? 12 : 13,
            color: primaryColor,
            fontWeight: FontWeight.w700,
          ),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Row(children: [
                Icon(Icons.filter_list_rounded, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Flexible(child: Text('الكل', overflow: TextOverflow.ellipsis)),
              ]),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Row(children: [
                Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Flexible(child: Text('نشط', overflow: TextOverflow.ellipsis)),
              ]),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Row(children: [
                Icon(Icons.pause_circle_rounded, size: 16, color: Colors.orange),
                SizedBox(width: 6),
                Flexible(child: Text('معطل', overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ],
          onChanged: (v) => onStatusChanged(v ?? 'all'),
        ),
      ),
    );
  }

  Widget _searchField({required bool isMobile}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: TextStyle(fontFamily: 'Cairo', fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: isMobile ? 'بحث...' : 'ابحث عن مستوى...',
          hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: isMobile ? 12 : 13),
          prefixIcon: Icon(Icons.search_rounded, size: isMobile ? 18 : 20, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _resultsCount(int count) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          '$count',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'نتائج',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}
