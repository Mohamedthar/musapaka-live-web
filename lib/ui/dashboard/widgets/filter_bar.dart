import 'package:flutter/material.dart';
import '../../../data/models/competition_level.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// DashboardFilterBar - الشريط العلوي للبحث والتصفية
// ─────────────────────────────────────────────
class DashboardFilterBar extends StatelessWidget {
  final String? currentLevelTitle;
  final List<CompetitionLevel> levels;
  final Function(String?) onLevelChanged;
  final int? minAge;
  final int? maxAge;
  final Function(int?) onMinAgeChanged;
  final Function(int?) onMaxAgeChanged;
  final double? minScore;
  final double? maxScore;
  final Function(double?) onMinScoreChanged;
  final Function(double?) onMaxScoreChanged;
  final String? currentGender;
  final Function(String?) onGenderChanged;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final int selectedIdsCount;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkPrint;
  final int filteredCount;
  final Color primaryColor;
  final DateTime? filterDateStart;
  final DateTime? filterDateEnd;
  final Function(DateTime?, DateTime?) onFilterDateRangeChanged;

  const DashboardFilterBar({
    super.key,
    required this.currentLevelTitle,
    required this.levels,
    required this.onLevelChanged,
    required this.minAge,
    required this.maxAge,
    required this.onMinAgeChanged,
    required this.onMaxAgeChanged,
    required this.minScore,
    required this.maxScore,
    required this.onMinScoreChanged,
    required this.onMaxScoreChanged,
    required this.currentGender,
    required this.onGenderChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedIdsCount,
    required this.onBulkDelete,
    required this.onBulkPrint,
    required this.filteredCount,
    required this.primaryColor,
    required this.filterDateStart,
    required this.filterDateEnd,
    required this.onFilterDateRangeChanged,
  });

  int get _activeFiltersCount {
    int count = 0;
    if (currentLevelTitle != null) count++;
    if (currentGender != null) count++;
    if (minAge != null || maxAge != null) count++;
    if (minScore != null || maxScore != null) count++;
    if (filterDateStart != null || filterDateEnd != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 6),
      child: Row(
        children: [
          _FilterButton(
            activeCount: _activeFiltersCount,
            isMobile: isMobile,
            primaryColor: primaryColor,
            onTap: () => _showFiltersModal(context),
          ),
          const SizedBox(width: 10),
          Expanded(child: _SearchBar(controller: searchController, onChanged: onSearchChanged)),
          const SizedBox(width: 10),
          _DateRangeFilterButton(
            startDate: filterDateStart,
            endDate: filterDateEnd,
            onChanged: onFilterDateRangeChanged,
            primaryColor: primaryColor,
            isMobile: isMobile,
          ),
          const SizedBox(width: 10),
          if (selectedIdsCount > 0) ...[
            if (!isMobile) ...[
              _BulkActionButton(label: 'طباعة ($selectedIdsCount)', color: Colors.blue.shade700, icon: Icons.print_rounded, loading: false, onTap: onBulkPrint),
              const SizedBox(width: 6),
              _BulkActionButton(label: 'حذف ($selectedIdsCount)', color: Colors.red.shade700, icon: Icons.delete_sweep_rounded, loading: false, onTap: onBulkDelete),
              const SizedBox(width: 10),
            ] else ...[
              _MobileBulkMenu(count: selectedIdsCount, onDelete: onBulkDelete, onPrint: onBulkPrint),
              const SizedBox(width: 6),
            ],
          ],
          _ResultCounter(count: filteredCount, isMobile: isMobile, color: primaryColor),
        ],
      ),
    );
  }

  void _showFiltersModal(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final content = FilterModalContent(
      initialLevelTitle: currentLevelTitle,
      levels: levels,
      initialGender: currentGender,
      minAge: minAge,
      maxAge: maxAge,
      minScore: minScore,
      maxScore: maxScore,
      filterDateStart: filterDateStart,
      filterDateEnd: filterDateEnd,
      primaryColor: primaryColor,
      onLevelChanged: onLevelChanged,
      onGenderChanged: onGenderChanged,
      onMinAgeChanged: onMinAgeChanged,
      onMaxAgeChanged: onMaxAgeChanged,
      onMinScoreChanged: onMinScoreChanged,
      onMaxScoreChanged: onMaxScoreChanged,
      onFilterDateRangeChanged: onFilterDateRangeChanged,
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: content,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: content,
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// مكوّنات مساعدة للشريط العلوي
// ─────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final bool isMobile;
  final Color primaryColor;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.isMobile, required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, color: primaryColor, size: 18),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text('تصفية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
        decoration: InputDecoration(
          hintText: 'بحث...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade400),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _BulkActionButton({required this.label, required this.color, required this.icon, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _MobileBulkMenu extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const _MobileBulkMenu({required this.count, required this.onDelete, required this.onPrint});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.primaryColor, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'delete') onDelete();
        if (val == 'print') onPrint();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'print', child: _menuRow(Icons.print_rounded, Colors.blue.shade700, 'طباعة ($count)')),
        PopupMenuItem(value: 'delete', child: _menuRow(Icons.delete_sweep_rounded, Colors.red.shade700, 'حذف ($count)')),
      ],
    );
  }

  Widget _menuRow(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
    ],
  );
}

class _ResultCounter extends StatelessWidget {
  final int count;
  final bool isMobile;
  final Color color;

  const _ResultCounter({required this.count, required this.isMobile, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          if (!isMobile) ...[
            const SizedBox(width: 4),
            Text('متسابق', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FilterModalContent - نافذة التصفية المُعاد تصميمها
// ─────────────────────────────────────────────
class FilterModalContent extends StatefulWidget {
  final String? initialLevelTitle;
  final List<CompetitionLevel> levels;
  final String? initialGender;
  final int? minAge;
  final int? maxAge;
  final double? minScore;
  final double? maxScore;
  final DateTime? filterDateStart;
  final DateTime? filterDateEnd;
  final Color primaryColor;
  final Function(String?) onLevelChanged;
  final Function(String?) onGenderChanged;
  final Function(int?) onMinAgeChanged;
  final Function(int?) onMaxAgeChanged;
  final Function(double?) onMinScoreChanged;
  final Function(double?) onMaxScoreChanged;
  final Function(DateTime?, DateTime?) onFilterDateRangeChanged;

  const FilterModalContent({
    super.key,
    required this.initialLevelTitle,
    required this.levels,
    required this.initialGender,
    required this.minAge,
    required this.maxAge,
    required this.minScore,
    required this.maxScore,
    this.filterDateStart,
    this.filterDateEnd,
    required this.primaryColor,
    required this.onLevelChanged,
    required this.onGenderChanged,
    required this.onMinAgeChanged,
    required this.onMaxAgeChanged,
    required this.onMinScoreChanged,
    required this.onMaxScoreChanged,
    required this.onFilterDateRangeChanged,
  });

  @override
  State<FilterModalContent> createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<FilterModalContent> {
  late String? level;
  late String? gender;
  late String? minAgeStr;
  late String? maxAgeStr;
  late String? minScoreStr;
  late String? maxScoreStr;
  late DateTime? _dateStart;
  late DateTime? _dateEnd;

  @override
  void initState() {
    super.initState();
    level = widget.initialLevelTitle;
    gender = widget.initialGender;
    minAgeStr = widget.minAge?.toString();
    maxAgeStr = widget.maxAge?.toString();
    minScoreStr = widget.minScore?.toString();
    maxScoreStr = widget.maxScore?.toString();
    _dateStart = widget.filterDateStart;
    _dateEnd = widget.filterDateEnd;
  }

  void _clearFilters() {
    setState(() {
      level = null;
      gender = null;
      minAgeStr = null;
      maxAgeStr = null;
      minScoreStr = null;
      maxScoreStr = null;
      _dateStart = null;
      _dateEnd = null;
    });
    widget.onLevelChanged(null);
    widget.onGenderChanged(null);
    widget.onMinAgeChanged(null);
    widget.onMaxAgeChanged(null);
    widget.onMinScoreChanged(null);
    widget.onMaxScoreChanged(null);
    widget.onFilterDateRangeChanged(null, null);
  }

  int get _appliedCount {
    int c = 0;
    if (level != null) c++;
    if (gender != null) c++;
    if (minAgeStr != null || maxAgeStr != null) c++;
    if (minScoreStr != null || maxScoreStr != null) c++;
    if (_dateStart != null || _dateEnd != null) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: isMobile
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      child: Container(
        decoration: boxDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMobile) ...[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 4),
            ],
            _buildHeader(context),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGenderDropdown(),
                    const SizedBox(height: 14),
                    _buildLevelDropdown(),
                    const SizedBox(height: 14),
                    _buildSectionDivider(),
                    const SizedBox(height: 12),
                    _buildAgeAndScoreRow(),
                    const SizedBox(height: 12),
                    _buildSectionDivider(),
                    const SizedBox(height: 12),
                    _buildDateRangeSection(),
                    const SizedBox(height: 20),
                    _buildApplyButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune_rounded, color: widget.primaryColor, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'تصفية النتائج',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
          ),
          if (_appliedCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_appliedCount',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _appliedCount > 0 ? _clearFilters : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              disabledForegroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('مسح', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return _FilterGroup(
      label: 'النوع',
      child: _buildDropdown<String?>(
        value: gender,
        items: const [
          DropdownMenuItem(value: null, child: Text('الكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          DropdownMenuItem(value: 'ذكر', child: Text('ذكر', style: TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          DropdownMenuItem(value: 'أنثى', child: Text('أنثى', style: TextStyle(fontFamily: 'Cairo', fontSize: 13))),
        ],
        onChanged: (val) { setState(() => gender = val); widget.onGenderChanged(val); },
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return _FilterGroup(
      label: 'المستوى',
      child: _buildDropdown<String?>(
        value: (level != null && widget.levels.any((l) => l.title == level)) ? level : null,
        items: [
          const DropdownMenuItem(value: null, child: Text('جميع المستويات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          ...widget.levels.map((l) => l.title).toSet().map(
            (t) => DropdownMenuItem<String?>(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          ),
        ],
        onChanged: (val) { setState(() => level = val); widget.onLevelChanged(val); },
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 1, color: const Color(0xFFF0F0F0));
  }

  Widget _buildAgeAndScoreRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RangeGroup(
            label: 'العمر (سنة)',
            val1: minAgeStr,
            val2: maxAgeStr,
            onChanged1: (v) { setState(() => minAgeStr = v); widget.onMinAgeChanged(int.tryParse(v)); },
            onChanged2: (v) { setState(() => maxAgeStr = v); widget.onMaxAgeChanged(int.tryParse(v)); },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RangeGroup(
            label: 'الدرجة',
            val1: minScoreStr,
            val2: maxScoreStr,
            onChanged1: (v) { setState(() => minScoreStr = v); widget.onMinScoreChanged(double.tryParse(v)); },
            onChanged2: (v) { setState(() => maxScoreStr = v); widget.onMaxScoreChanged(double.tryParse(v)); },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    final hasDate = _dateStart != null || _dateEnd != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range_rounded, size: 14, color: widget.primaryColor.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              'نطاق تاريخ التسجيل',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w900, color: widget.primaryColor.withValues(alpha: 0.7)),
            ),
            if (hasDate) ...[
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() { _dateStart = null; _dateEnd = null; });
                  widget.onFilterDateRangeChanged(null, null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('مسح', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade400)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDateRange(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasDate ? widget.primaryColor.withValues(alpha: 0.05) : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate ? widget.primaryColor.withValues(alpha: 0.3) : const Color(0xFFE5E5E5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 18, color: hasDate ? widget.primaryColor : Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasDate
                        ? '${_formatDate(_dateStart!)} → ${_formatDate(_dateEnd!)}'
                        : 'اختر نطاق التاريخ...',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasDate ? AppTheme.primaryColor : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, size: 18, color: AppTheme.primaryColor.withValues(alpha: 0.6)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 18),
            SizedBox(width: 8),
            Text('تطبيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final result = await _showDateRangePickerSheet(
      context,
      primaryColor: widget.primaryColor,
      initialStart: _dateStart,
      initialEnd: _dateEnd,
    );
    if (result != null && mounted) {
      setState(() {
        _dateStart = result.start;
        _dateEnd = result.end;
      });
      widget.onFilterDateRangeChanged(result.start, result.end);
    }
  }
}

// ─────────────────────────────────────────────
// _CustomDateRangePicker - منتقي تاريخ مخصص بتصميم النظام
// ─────────────────────────────────────────────
class _CustomDateRangePicker extends StatefulWidget {
  final Color primaryColor;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _CustomDateRangePicker({
    required this.primaryColor,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = widget.initialStart ?? now;
    _endDate = widget.initialEnd ?? now;
  }

  void _confirm() {
    final start = _startDate;
    final end = _endDate;
    Navigator.pop(context, DateTimeRange(start: start, end: end));
  }

  void _applyPreset(DateTime start, DateTime end) {
    Navigator.pop(context, DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.initialStart != null && widget.initialEnd != null;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 12)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDesktop) ...[
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.date_range_rounded, color: widget.primaryColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('نطاق تاريخ التسجيل',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 8),
            // Date display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'من تاريخ',
                      date: widget.initialStart,
                      primaryColor: widget.primaryColor,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: widget.initialStart ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: widget.primaryColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                              textTheme: const TextTheme(
                                bodyMedium: TextStyle(fontFamily: 'Cairo'),
                                labelLarge: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFCCCCCC)),
                  ),
                  Expanded(
                    child: _DateField(
                      label: 'إلى تاريخ',
                      date: widget.initialEnd,
                      primaryColor: widget.primaryColor,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: widget.initialEnd ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: widget.primaryColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                              textTheme: const TextTheme(
                                bodyMedium: TextStyle(fontFamily: 'Cairo'),
                                labelLarge: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Presets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(
                    label: 'اليوم',
                    primaryColor: widget.primaryColor,
                    isActive: hasSelection && widget.initialStart == DateTime.now() && widget.initialEnd == DateTime.now(),
                    onTap: () {
                      final now = DateTime.now();
                      _applyPreset(now, now);
                    },
                  ),
                  _PresetChip(
                    label: 'آخر ٧ أيام',
                    primaryColor: widget.primaryColor,
                    isActive: false,
                    onTap: () {
                      final now = DateTime.now();
                      _applyPreset(now.subtract(const Duration(days: 6)), now);
                    },
                  ),
                  _PresetChip(
                    label: 'هذا الشهر',
                    primaryColor: widget.primaryColor,
                    isActive: false,
                    onTap: () {
                      final now = DateTime.now();
                      _applyPreset(DateTime(now.year, now.month, 1), now);
                    },
                  ),
                  if (hasSelection)
                    _PresetChip(
                      label: 'إلغاء التحديد',
                      primaryColor: Colors.red,
                      isActive: false,
                      onTap: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF555555))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('تطبيق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasDate ? primaryColor.withValues(alpha: 0.05) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFE5E5E5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w800, color: primaryColor.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: hasDate ? primaryColor : Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasDate
                        ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                        : 'اختر...',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasDate ? AppTheme.primaryColor : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final Color primaryColor;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.primaryColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? primaryColor : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _DateRangeFilterButton - زر فلتر التاريخ في الشريط العلوي
// ─────────────────────────────────────────────
class _DateRangeFilterButton extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onChanged;
  final Color primaryColor;
  final bool isMobile;

  const _DateRangeFilterButton({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    required this.primaryColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = startDate != null || endDate != null;

    String? dateLabel() {
      if (startDate == null || endDate == null) return null;
      return '${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}';
    }

    return Tooltip(
      message: 'تصفية بنطاق تاريخ التسجيل',
      child: InkWell(
        onTap: () async {
          final result = await _showDateRangePickerSheet(
            context,
            primaryColor: primaryColor,
            initialStart: startDate,
            initialEnd: endDate,
          );
          if (result != null) {
            onChanged(result.start, result.end);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: hasFilter ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasFilter ? primaryColor : const Color(0xFFE5E5E5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.date_range_rounded, color: hasFilter ? primaryColor : Colors.grey.shade400, size: 18),
              if (!isMobile && hasFilter) ...[
                const SizedBox(width: 6),
                Text(
                  dateLabel() ?? 'مخصص',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => onChanged(null, null),
                  child: const Icon(Icons.close, size: 14, color: AppTheme.primaryColor),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

/// دالة مساعدة لعرض منتقي التاريخ — BottomSheet على الموبايل، Dialog على ديسكتوب
Future<DateTimeRange?> _showDateRangePickerSheet(
  BuildContext context, {
  required Color primaryColor,
  DateTime? initialStart,
  DateTime? initialEnd,
}) async {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showDialog<DateTimeRange>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _CustomDateRangePicker(
            primaryColor: primaryColor,
            initialStart: initialStart,
            initialEnd: initialEnd,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CustomDateRangePicker(
      primaryColor: primaryColor,
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

// ─────────────────────────────────────────────
// _FilterGroup - مجموعة تصفية بتسمية
// ─────────────────────────────────────────────
class _FilterGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryColor.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _RangeGroup - مجموعة مدخل رقمي (من/إلى)
// ─────────────────────────────────────────────
class _RangeGroup extends StatelessWidget {
  final String label;
  final String? val1;
  final String? val2;
  final Function(String) onChanged1;
  final Function(String) onChanged2;

  const _RangeGroup({required this.label, this.val1, this.val2, required this.onChanged1, required this.onChanged2});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryColor.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _RangeInput(hint: 'من', onChanged: onChanged1, initial: val1)),
            const SizedBox(width: 6),
            Expanded(child: _RangeInput(hint: 'إلى', onChanged: onChanged2, initial: val2)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _RangeInput - حقل إدخال رقمي
// ─────────────────────────────────────────────
class _RangeInput extends StatefulWidget {
  final String hint;
  final Function(String) onChanged;
  final String? initial;

  const _RangeInput({required this.hint, required this.onChanged, this.initial});

  @override
  State<_RangeInput> createState() => _RangeInputState();
}

class _RangeInputState extends State<_RangeInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
    if (widget.initial != null) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.initial!.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        keyboardType: TextInputType.number,
        onChanged: widget.onChanged,
        controller: _controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        ),
      ),
    );
  }
}
