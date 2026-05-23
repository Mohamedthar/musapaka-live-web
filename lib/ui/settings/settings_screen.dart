import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/exam_schedule_slot.dart';
import '../../services/supabase_service.dart';
import 'models/day_block.dart';
import 'widgets/section_card.dart';
import 'widgets/form_fields.dart';

class SettingsScreen extends StatefulWidget {
  final Color? primaryColor;
  final String initialSection;
  const SettingsScreen({super.key, this.primaryColor, this.initialSection = 'dates'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _service = SupabaseService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMsg;

  bool _isRegistrationOpen = false;
  bool _isCeremonyQueryOpen = false;
  bool _isResultQueryOpen = false;
  DateTime? _registrationStart;
  DateTime? _registrationEnd;
  DateTime? _examPeriodStart;
  DateTime? _examPeriodEnd;
  List<DayBlock> _days = [];
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _totalPrizesCtrl = TextEditingController();
  int _committeesCount = 3;

  late String _activeSection;

  Color get _primary => widget.primaryColor ?? AppTheme.primaryColor;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
    _load();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      setState(() => _activeSection = widget.initialSection);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _totalPrizesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _successMsg = null; });
    try {
      final row = await _service.getSettings();
      if (!mounted) return;
      if (row != null) _apply(row);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل الإعدادات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(Map<String, dynamic> row) {
    _isRegistrationOpen = row['is_registration_open'] ?? false;
    _isCeremonyQueryOpen = row['is_ceremony_query_open'] ?? false;
    _isResultQueryOpen = row['is_result_query_open'] ?? false;
    _registrationStart = ExamScheduleSlot.parseDate(row['registration_start_date']);
    _registrationEnd = ExamScheduleSlot.parseDate(row['registration_end_date']);
    _examPeriodStart = ExamScheduleSlot.parseDate(row['exam_period_start']);
    _examPeriodEnd = ExamScheduleSlot.parseDate(row['exam_period_end']);
    _days = _group(ExamScheduleSlot.listFromJson(row['exam_schedule']));
    _committeesCount = (row['committees_count'] as num?)?.toInt() ?? 3;
    _titleCtrl.text = row['title'] ?? 'مسابقة القرآن الكريم';
    _descriptionCtrl.text = row['description'] ?? '';
    _totalPrizesCtrl.text = row['total_prizes'] ?? '50,000+';
  }

  List<DayBlock> _group(List<ExamScheduleSlot> slots) {
    final grouped = <String, List<ExamScheduleSlot>>{};
    for (final slot in slots) {
      if (slot.date == null) continue;
      final key = intl.DateFormat('yyyy-MM-dd').format(slot.date!);
      grouped.putIfAbsent(key, () => []).add(slot);
    }
    final keys = grouped.keys.toList()..sort();
    return keys.map((key) {
      final list = grouped[key]!..sort((a, b) => a.startHour.compareTo(b.startHour));
      return DayBlock(date: list.first.date, periods: list);
    }).toList();
  }

  List<ExamScheduleSlot> _flatten() {
    final out = <ExamScheduleSlot>[];
    for (final day in _days) {
      if (day.date == null) continue;
      for (final period in day.periods) {
        out.add(period.copyWith(date: day.date));
      }
    }
    return out;
  }

  bool get _hasIncompleteDays => _days.any((d) => d.date == null);
  bool get _hasOverlaps {
    final slots = _flatten();
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        if (slots[i].overlaps(slots[j])) return true;
      }
    }
    return false;
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2024),
    lastDate: DateTime(2030),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: _primary)),
      child: child!,
    ),
  );

  Future<void> _save() async {
    final validationError = _validateBeforeSave();
    if (validationError != null) {
      setState(() { _error = validationError; _successMsg = null; });
      return;
    }

    setState(() { _saving = true; _error = null; _successMsg = null; });
    try {
      await _service.updateSettings({
        'is_registration_open': _isRegistrationOpen,
        'is_ceremony_query_open': _isCeremonyQueryOpen,
        'is_result_query_open': _isResultQueryOpen,
        'registration_start_date': _registrationStart?.toIso8601String(),
        'registration_end_date': _registrationEnd?.toIso8601String(),
        'exam_period_start': _examPeriodStart?.toIso8601String(),
        'exam_period_end': _examPeriodEnd?.toIso8601String(),
        'exam_schedule': _flatten().map((s) => s.toJson()).toList(),
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'total_prizes': _totalPrizesCtrl.text.trim(),
        'committees_count': _committeesCount,
      });

      if (!mounted) return;
      await _load();
      setState(() => _successMsg = 'تم حفظ إعدادات النظام بنجاح ✓');
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateBeforeSave() {
    if (_registrationStart != null && _registrationEnd != null && _registrationEnd!.isBefore(_registrationStart!)) return 'نهاية التقديم تسبق البداية.';
    if (_examPeriodStart != null && _examPeriodEnd != null && _examPeriodEnd!.isBefore(_examPeriodStart!)) return 'نهاية الاختبارات تسبق البداية.';
    if (_hasIncompleteDays) return 'يوجد أيام بدون تاريخ، يُرجى تحديدها.';
    if (_hasOverlaps) return 'يوجد تداخل بين فترات بعض اللجان.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final isMobile = screenType == ScreenType.mobile;

    return Column(
      children: [
        _buildTopBar(isMobile),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F7),
            child: _loading
              ? Center(child: CircularProgressIndicator(color: _primary))
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) _buildAlert(_error!, true),
                        if (_successMsg != null) _buildAlert(_successMsg!, false),
                        _buildActiveContent(isMobile),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isMobile) {
    final sectionLabel = _activeSection == 'dates'
        ? 'المواعيد واللجان'
        : 'جدول الفترات';
    final sectionIcon = _activeSection == 'dates'
        ? Icons.calendar_today_rounded
        : Icons.view_timeline_rounded;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          // Section icon badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(sectionIcon, size: 18, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF03121C),
                  ),
                ),
                if (!isMobile)
                  Text(
                    _activeSection == 'dates'
                        ? 'إدارة تواريخ التسجيل والاختبار وضبط لجان التحكيم'
                        : 'جدولة فترات لجان الاختبار اليومية وتحديد سعة كل فترة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          // Refresh button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saving ? null : _load,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: _saving ? Colors.grey.shade300 : const Color(0xFF03121C),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Save button
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: Text(
              _saving ? 'جاري الحفظ...' : 'حفظ',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saving ? Colors.grey.shade400 : Colors.green.shade600,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContent(bool isMobile) {
    switch (_activeSection) {
      case 'dates':
        return _buildRegistrationDatesSection();
      case 'schedule':
        return _buildSchedule(isMobile);
      default:
        return _buildRegistrationDatesSection();
    }
  }

  Widget _buildRegistrationDatesSection() {
    return SectionCard(
      title: 'مواعيد التقديم ولجان التحكيم',
      description: 'إدارة تواريخ تقديم الطلاب، وفترات الاختبارات، ونشاط بوابة التسجيل مع لجان التقييم',
      icon: Icons.calendar_today_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsFormFields.enhancedToggleField(
            label: 'بوابة تسجيل الطلاب الإلكترونية',
            description: 'عند التفعيل، يمكن للطلاب ملء استمارات التقديم عبر الإنترنت والتسجيل فوراً.',
            value: _isRegistrationOpen,
            onChanged: (v) => setState(() => _isRegistrationOpen = v),
            primaryColor: _primary,
          ),
          const SizedBox(height: 16),
          SettingsFormFields.enhancedToggleField(
            label: 'قسم الاستعلام عن حضور الحفل',
            description: 'عند التفعيل، يظهر قسم خاص للطلاب للبحث بالرقم القومي ومعرفة استحقاقهم لحضور الحفل الختامي.',
            value: _isCeremonyQueryOpen,
            onChanged: (v) => setState(() => _isCeremonyQueryOpen = v),
            primaryColor: Colors.purple,
          ),
          const SizedBox(height: 16),
          SettingsFormFields.enhancedToggleField(
            label: 'قسم الاستعلام عن النتيجة النهائية',
            description: 'عند التفعيل، يظهر قسم خاص للطلاب للبحث بالرقم القومي ومعرفة نتيجتهم بالتفصيل.',
            value: _isResultQueryOpen,
            onChanged: (v) => setState(() => _isResultQueryOpen = v),
            primaryColor: Colors.amber.shade800,
          ),
          const SizedBox(height: 24),
          _buildSectionDivider('فترة التسجيل الإلكتروني للطلاب', Icons.how_to_reg_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'بداية التسجيل',
                  selectedDate: _registrationStart,
                  onTap: () async {
                    final d = await _pickDate(_registrationStart);
                    if (d != null) setState(() => _registrationStart = d);
                  },
                  primaryColor: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'نهاية التسجيل',
                  selectedDate: _registrationEnd,
                  onTap: () async {
                    final d = await _pickDate(_registrationEnd);
                    if (d != null) setState(() => _registrationEnd = d);
                  },
                  primaryColor: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionDivider('فترة إجراء الاختبارات والتصفيات الفعلية', Icons.quiz_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'بداية الاختبارات',
                  selectedDate: _examPeriodStart,
                  onTap: () async {
                    final d = await _pickDate(_examPeriodStart);
                    if (d != null) setState(() => _examPeriodStart = d);
                  },
                  primaryColor: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'نهاية الاختبارات',
                  selectedDate: _examPeriodEnd,
                  onTap: () async {
                    final d = await _pickDate(_examPeriodEnd);
                    if (d != null) setState(() => _examPeriodEnd = d);
                  },
                  primaryColor: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsFormFields.enhancedStepperField(
            value: _committeesCount,
            onChanged: (v) => setState(() => _committeesCount = v),
            primaryColor: _primary,
            label: 'عدد لجان التحكيم والتسميع',
            description: 'تحديد عدد لجان التقييم المنفصلة التي تقوم باختبار المتسابقين في نفس الوقت.',
            minValue: 1,
            maxValue: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF03121C).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule(bool isMobile) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final needsScroll = screenType == ScreenType.mobile || screenType == ScreenType.tablet;

    return SectionCard(
      title: 'جدول اللجان والفترات المتاحة للاختبار',
      description: 'إضافة الأيام المخصصة للاختبار وتحديد الفترات الزمنية وسعة كل فترة',
      icon: Icons.view_timeline_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _days.add(DayBlock())),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'إضافة يوم اختبار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary.withValues(alpha: 0.1),
                  foregroundColor: _primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_days.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.date_range_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد أي فترات أو أيام مجدولة حالياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: needsScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 850),
                          child: _buildScheduleTable(),
                        ),
                      )
                    : _buildScheduleTable(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FixedColumnWidth(120),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: _primary),
          children: [
            _th('تاريخ اليوم'),
            _th('من الساعة', center: true),
            _th('إلى الساعة', center: true),
            _th('السعة', center: true),
            _th('الإجراءات', center: true),
          ],
        ),
        ..._days.asMap().entries.expand((dayEntry) {
          final dayIndex = dayEntry.key;
          final day = dayEntry.value;
          final dayHasError = day.date == null;
          
          if (day.periods.isEmpty) {
            day.periods.add(DayBlock.defaultSlot());
          }

          return day.periods.asMap().entries.map((periodEntry) {
            final periodIndex = periodEntry.key;
            final slot = periodEntry.value;
            final isFirstRowOfDay = periodIndex == 0;

            return TableRow(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              children: [
                // Day Date Column
                isFirstRowOfDay
                  ? _td(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: dayHasError ? Colors.orange.shade50 : _primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: dayHasError ? Colors.orange.shade200 : _primary.withValues(alpha: 0.1)),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final d = await _pickDate(day.date);
                            if (d != null) setState(() => day.date = d);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 16, color: dayHasError ? Colors.orange.shade800 : _primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  day.date == null ? 'حدد التاريخ' : intl.DateFormat('EEEE, d MMM yyyy', 'ar').format(day.date!),
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: dayHasError ? Colors.orange.shade800 : _primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    )
                  : const TableCell(child: SizedBox()),

                // Start Hour
                _td(
                  _CompactDropdown(
                    value: slot.startHour,
                    items: List.generate(15, (i) => i + 8),
                    onChanged: (v) => setState(() { slot.startHour = v; slot.clampInclusiveRange(); }),
                    primaryColor: _primary,
                  ),
                  center: true
                ),

                // End Hour
                _td(
                  _CompactDropdown(
                    value: slot.endHour,
                    items: List.generate(24 - slot.startHour, (i) => i + slot.startHour + 1),
                    onChanged: (v) => setState(() => slot.endHour = v),
                    primaryColor: _primary,
                  ),
                  center: true
                ),

                // Capacity
                _td(
                  TextFormField(
                    controller: TextEditingController(text: '${slot.studentsPerHour}'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primary, width: 2)),
                    ),
                    onChanged: (v) => slot.studentsPerHour = int.tryParse(v) ?? 1,
                  ),
                ),

                // Actions
                _td(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFirstRowOfDay)
                        IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: _primary, size: 20),
                          tooltip: 'إضافة فترة',
                          onPressed: () => setState(() => day.periods.add(DayBlock.defaultSlot())),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        tooltip: day.periods.length == 1 ? 'حذف اليوم' : 'حذف الفترة',
                        onPressed: () => setState(() {
                          if (day.periods.length == 1) {
                            _days.removeAt(dayIndex);
                          } else {
                            day.periods.removeAt(periodIndex);
                          }
                        }),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  center: true,
                ),
              ],
            );
          });
        }),
      ],
    );
  }

  // --- Helpers ---

  Widget _th(String label, {bool center = false}) {
    return TableCell(
      child: Container(
        alignment: center ? Alignment.center : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _td(Widget child, {bool center = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: center ? Center(child: child) : child,
      ),
    );
  }

  Widget _buildAlert(String message, bool isError) {
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    final iconColor = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final textColor = isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _CompactDropdown extends StatelessWidget {
  final int value;
  final List<int> items;
  final Function(int) onChanged;
  final Color primaryColor;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.primaryColor,
  });

  String _formatTime(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 || hour == 24 ? 12 : hour);
    final amPm = (hour >= 12 && hour < 24) ? 'م' : 'ص';
    return '${h.toString().padLeft(2, '0')}:00 $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF03121C)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(_formatTime(i)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
