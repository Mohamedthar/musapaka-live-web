import 'package:flutter/material.dart';
import '../../../data/models/competition_level.dart';
import '../../../data/models/student.dart';
import '../../../core/utils/responsive.dart';

class LevelsTable extends StatelessWidget {
  final List<CompetitionLevel> levels;
  final List<Student> allStudents;
  final Set<int> selectedIds;
  final Function(int, bool) onSelectionChanged;
  final Function(CompetitionLevel) onEditLevel;
  final Color primaryColor;
  final ScreenType? screenType;

  const LevelsTable({
    super.key,
    required this.levels,
    required this.allStudents,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onEditLevel,
    required this.primaryColor,
    this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) return _noResults();
    if (screenType == ScreenType.mobile) return _buildMobileCards();

    return LayoutBuilder(builder: (ctx, constraints) {
      final bool needsScroll = constraints.maxWidth < 1000;

      Widget tableContent = Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FlexColumnWidth(3.0),
          2: FlexColumnWidth(4.0),
          3: FlexColumnWidth(2.5),
          4: FlexColumnWidth(2.0),
          5: FlexColumnWidth(2.5),
          6: FixedColumnWidth(100),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: primaryColor),
            children: [
              _thCheckbox(),
              _th('المستوى'),
              _th('المحتوى المطلوب'),
              _th('شروط العمر'),
              _th('إجمالي النقاط'),
              _th('الإشغال والسعة'),
              _th('الحالة', center: true),
            ],
          ),
          ...levels.map((l) => _tableRow(l)),
        ],
      );

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
                      constraints: const BoxConstraints(minWidth: 1000),
                      child: tableContent,
                    ),
                  )
                : tableContent,
          ),
        ),
      );
    });
  }

  Widget _buildMobileCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: levels.length,
      itemBuilder: (ctx, i) {
        final l = levels[i];
        final isSelected = l.id != null && selectedIds.contains(l.id);
        final count = allStudents.where((s) => s.level == l.title).length;
        final cap = l.maxCapacity ?? 0;
        final double percent = cap > 0 ? (count / cap).clamp(0.0, 1.0) : 0.0;

        String age = 'جميع الأعمار';
        if (l.minAge != null && l.maxAge != null) {
          age = 'فوق ${l.minAge} عام و ${l.maxAge} عام فأقل';
        } else if (l.minAge != null) {
          age = 'فوق ${l.minAge} عام';
        } else if (l.maxAge != null) {
          age = '${l.maxAge} عام فأقل';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isSelected ? primaryColor.withValues(alpha: 0.02) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          elevation: isSelected ? 2 : 0.5,
          shadowColor: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.black12,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onEditLevel(l),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: l.id == null ? null : (v) => onSelectionChanged(l.id!, v ?? false),
                    activeColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      if (l.levelCode != null)
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l.levelCode!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.title, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w800, color: primaryColor)),
                          if (l.notes != null)
                            Text(l.notes!, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (l.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (l.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.2)),
                    ),
                    child: Text(l.isActive ? 'نشط' : 'معطل',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700,
                        color: l.isActive ? Colors.green.shade700 : Colors.grey.shade700)),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 8),
                    Text(l.content, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(children: [
                      _infoChip(Icons.cake_outlined, age, Colors.blue),
                      const SizedBox(width: 8),
                      _infoChip(Icons.star_outline_rounded, '${l.totalMaxPoints} نقطة', Colors.orange),
                      const Spacer(),
                      _infoChip(Icons.people_outline_rounded, '$count/${cap > 0 ? cap : "∞"}', primaryColor),
                    ]),

                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: cap > 0 ? percent : 0,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent > 0.9 ? Colors.red.shade400 : (percent > 0.7 ? Colors.orange.shade400 : Colors.green.shade400)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }


  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _noResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 48, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(
            'لا توجد مستويات',
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 14,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thCheckbox() {
    final allSelected = levels.isNotEmpty && selectedIds.length == levels.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Checkbox(
        value: allSelected,
        activeColor: Colors.white,
        checkColor: primaryColor,
        side: const BorderSide(color: Colors.white70),
        onChanged: (_) {
          if (allSelected) {
            for (final l in levels) {
              if (l.id != null) onSelectionChanged(l.id!, false);
            }
          } else {
            for (final l in levels) {
              if (l.id != null && !selectedIds.contains(l.id)) {
                onSelectionChanged(l.id!, true);
              }
            }
          }
        },
      ),
    );
  }

  Widget _th(String label, {bool center = false}) {
    return TableCell(
      child: Container(
        alignment: center ? Alignment.center : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Cairo', 
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  TableRow _tableRow(CompetitionLevel l) {
    final isSelected = l.id != null && selectedIds.contains(l.id);
    final count = allStudents.where((s) => s.level == l.title).length;
    final cap = l.maxCapacity ?? 0;
    final double percent = cap > 0 ? (count / cap).clamp(0.0, 1.0) : 0.0;
    onTapEdit() => onEditLevel(l);

    String age = 'جميع الأعمار';
    if (l.minAge != null && l.maxAge != null) {
      age = 'فوق ${l.minAge} عام و ${l.maxAge} عام فأقل';
    } else if (l.minAge != null) {
      age = 'فوق ${l.minAge} عام';
    } else if (l.maxAge != null) {
      age = '${l.maxAge} عام فأقل';
    }

    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withValues(alpha: 0.4) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: l.id == null
                  ? null
                  : (v) => onSelectionChanged(l.id!, v ?? false),
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        _td(
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Level Code Badge
            if (l.levelCode != null)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  l.levelCode!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  l.title,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                if (l.notes != null)
                  Text(
                    l.notes!,
                    style: TextStyle(fontFamily: 'Cairo', 
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ]),
            ),
          ]),
          onTap: onTapEdit,
        ),
        _td(
          Text(
            l.content,
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onTapEdit,
        ),
        _td(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cake_outlined, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  age,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ),
          onTap: onTapEdit,
        ),
        _td(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_outline_rounded, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${l.totalMaxPoints}',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 12,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ),
          onTap: onTapEdit,
        ),
        _td(
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                'الإشغال',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                '$count/${cap > 0 ? cap : "∞"}',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: cap > 0 ? percent : 0,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent > 0.9
                        ? Colors.red.shade400
                        : (percent > 0.7
                            ? Colors.orange.shade400
                            : Colors.green.shade400),
                  ),
                ),
              ),
            ),
          ]),
          onTap: onTapEdit,
        ),

        _td(
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (l.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (l.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                l.isActive ? 'نشط' : 'معطل',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: l.isActive ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          onTap: onTapEdit,
        ),
      ],
    );
  }


  Widget _td(Widget child, {VoidCallback? onTap}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}
