import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

class DashboardTopBar extends StatelessWidget {
  final bool isWide;
  final VoidCallback onRefresh;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPDF;
  final bool showAddPanel;
  final VoidCallback onToggleAddPanel;
  final Color primaryColor;

  const DashboardTopBar({
    super.key,
    required this.isWide,
    required this.onRefresh,
    required this.onExportExcel,
    required this.onExportPDF,
    required this.showAddPanel,
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
            child: Row(children: [
              if (isMobile) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo_musapaka.jpeg',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('لوحة التحكم',
                      style: TextStyle(fontFamily: 'Cairo', 
                          fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w800, color: primaryColor)),
                  if (!isMobile)
                    Text('إدارة المتسابقين',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade500)),
                ]),
              ),
            ]),
          ),
          IconButton(
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: onRefresh,
              visualDensity: VisualDensity.compact),
          if (isMobile) ...[
            IconButton(
                icon: const Icon(Icons.table_chart_rounded, size: 20, color: Colors.green),
                onPressed: onExportExcel,
                tooltip: 'تصدير Excel',
                visualDensity: VisualDensity.compact),
            IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.red),
                onPressed: onExportPDF,
                tooltip: 'تصدير PDF',
                visualDensity: VisualDensity.compact),
          ] else ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: onExportExcel,
              icon: const Icon(Icons.table_chart_rounded, size: 18, color: Colors.green),
              label: Text('تصدير Excel',
                  style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onExportPDF,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.red),
              label: Text('تصدير PDF',
                  style: TextStyle(fontFamily: 'Cairo', 
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
          ],
          if (isWide) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
                onPressed: onToggleAddPanel,
                icon: Icon(showAddPanel ? Icons.close : Icons.person_add_rounded,
                    size: 18, color: Colors.white),
                label: Text(showAddPanel ? 'إلغاء' : 'إضافة متسابق',
                    style: const TextStyle(fontFamily: 'Cairo', 
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: showAddPanel ? Colors.grey.shade700 : primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)))),
          ],
        ]));
  }
}
