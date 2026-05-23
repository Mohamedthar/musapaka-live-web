import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

class LevelsTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPDF;
  final bool showSidePanel;
  final bool isAddingNew;
  final VoidCallback onToggleAddPanel;
  final Color primaryColor;

  const LevelsTopBar({
    super.key,
    required this.onRefresh,
    required this.onExportExcel,
    required this.onExportPDF,
    required this.showSidePanel,
    required this.isAddingNew,
    required this.onToggleAddPanel,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'إدارة المستويات',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            if (!isMobile)
              Text(
                'تحديد فئات المسابقة وشروط الاشتراك لكل مستوى',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade500),
              ),
          ]),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded, color: primaryColor),
          visualDensity: VisualDensity.compact,
        ),
        if (isMobile) ...[
          IconButton(
            onPressed: onExportExcel,
            icon: const Icon(Icons.table_chart_rounded, size: 20, color: Colors.green),
            tooltip: 'تصدير Excel',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onExportPDF,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.red),
            tooltip: 'تصدير PDF',
            visualDensity: VisualDensity.compact,
          ),
        ] else ...[
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onExportExcel,
            icon: const Icon(Icons.table_chart_rounded, size: 18, color: Colors.green),
            label: Text(
              'تصدير Excel',
              style: TextStyle(fontFamily: 'Cairo', 
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onExportPDF,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.red),
            label: Text(
              'تصدير PDF',
              style: TextStyle(fontFamily: 'Cairo', 
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
        const SizedBox(width: 8),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: onToggleAddPanel,
            icon: Icon(
              showSidePanel && isAddingNew ? Icons.close : Icons.add_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              showSidePanel && isAddingNew ? 'إلغاء' : 'إضافة مستوى جديد',
              style: const TextStyle(fontFamily: 'Cairo', 
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  showSidePanel && isAddingNew ? Colors.grey.shade700 : primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ]),
    );
  }
}
