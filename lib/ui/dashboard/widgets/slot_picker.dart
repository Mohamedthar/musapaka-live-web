import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';

// =============================================================================
// SlotInfo — snapshot of a single exam-hour slot
// =============================================================================
class SlotInfo {
  final DateTime date;
  final int hour;
  final int startHour;
  final int endHour;
  final int studentsPerHour;
  final int currentCount;
  final bool isAvailable;

  const SlotInfo({
    required this.date,
    required this.hour,
    required this.startHour,
    required this.endHour,
    required this.studentsPerHour,
    required this.currentCount,
    required this.isAvailable,
  });

  factory SlotInfo.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['exam_date'];
    final d = dateRaw is DateTime
        ? dateRaw
        : DateTime.tryParse(dateRaw.toString()) ?? DateTime(2024);
    return SlotInfo(
      date: DateTime(d.year, d.month, d.day),
      hour: (json['exam_hour'] as num).toInt(),
      startHour: (json['start_hour'] as num).toInt(),
      endHour: (json['end_hour'] as num).toInt(),
      studentsPerHour: (json['students_per_hour'] as num).toInt(),
      currentCount: (json['current_count'] as num).toInt(),
      isAvailable: json['is_available'] == true,
    );
  }

  String get hourLabel {
    if (hour == 0) return '12 منتصف الليل';
    if (hour < 12) return '$hour صباحاً';
    if (hour == 12) return '12 ظهراً';
    return '${hour - 12} مساءً';
  }

  String get capacityLabel => '$currentCount / $studentsPerHour';
}

// =============================================================================
// SlotPicker — dialog matching the app's confirm-dialog pattern
// =============================================================================
class SlotPicker extends StatefulWidget {
  final Color primaryColor;
  final DateTime? initialDate;
  final int? initialHour;
  final int? excludeStudentId;

  const SlotPicker({
    super.key,
    required this.primaryColor,
    this.initialDate,
    this.initialHour,
    this.excludeStudentId,
  });

  static Future<SlotInfo?> show(
    BuildContext context, {
    required Color primaryColor,
    DateTime? initialDate,
    int? initialHour,
    int? excludeStudentId,
  }) {
    return showDialog<SlotInfo>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => SlotPicker(
        primaryColor: primaryColor,
        initialDate: initialDate,
        initialHour: initialHour,
        excludeStudentId: excludeStudentId,
      ),
    );
  }

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  List<SlotInfo> _slots = [];
  bool _loading = true;
  String? _error;
  DateTime? _selectedDate;
  SlotInfo? _selectedSlot;

  Color get _primary => widget.primaryColor;
  static const _textDark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _selectedSlot = null;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = SupabaseService();
      final raw = await service.getSlotAvailability(
        excludeStudentId: widget.excludeStudentId,
      );
      if (!mounted) return;
      final slots = raw.map((m) => SlotInfo.fromJson(m)).toList();
      setState(() { _slots = slots; _loading = false; });
      if (widget.initialDate != null) {
        final d = DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day);
        if (uniqueDates.any((dd) => _sameDay(dd, d))) {
          setState(() => _selectedDate = d);
        }
        if (widget.initialHour != null) {
          final match = _slots.where((s) => _sameDay(s.date, d) && s.hour == widget.initialHour).firstOrNull;
          if (match != null && match.isAvailable) {
            setState(() => _selectedSlot = match);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل المواعيد'; _loading = false; });
    }
  }

  List<DateTime> get uniqueDates {
    final seen = <DateTime>{};
    for (final s in _slots) seen.add(s.date);
    return seen.toList()..sort();
  }

  List<SlotInfo> get slotsForSelectedDate =>
      _selectedDate == null ? [] : _slots.where((s) => _sameDay(s.date, _selectedDate!)).toList();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (_slots.isEmpty)
              _buildEmpty()
            else
              _buildContent(),
          ],
        ),
      ),
    );
  }

  // ── Header (clean, matching confirm dialog style) ──────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primary.withValues(alpha: 0.12),
                      _primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.schedule_rounded, color: _primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اختيار موعد الاختبار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedSlot != null
                          ? 'تم اختيار: ${_selectedSlot!.hourLabel}'
                          : 'اختر اليوم ثم الساعة المناسبة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 32, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مواعيد مجدولة حالياً',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إضافة أيام وفترات الاختبار من إعدادات النظام أولاً',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────

  Widget _buildContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDateSelector(),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          if (_selectedDate != null)
            Expanded(child: _buildHoursGrid())
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.touch_app_rounded, size: 32, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'الرجاء اختيار اليوم أولاً من الأعلى',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildActions(),
        ],
      ),
    );
  }

  // ── Date selector ──────────────────────────────────────────

  Widget _buildDateSelector() {
    final dates = uniqueDates;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'اختر اليوم',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (_selectedDate != null)
                Text(
                  '${dates.indexOf(_selectedDate!) + 1}/${dates.length}',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: _primary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final d = dates[index];
                final isSelected = _selectedDate != null && _sameDay(d, _selectedDate!);
                final availableCount = _slots.where((s) => _sameDay(s.date, d) && s.isAvailable).length;
                final totalCount = _slots.where((s) => _sameDay(s.date, d)).length;
                final allFull = availableCount == 0;

                return Material(
                  color: isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: isSelected ? 2 : 0,
                  shadowColor: _primary.withValues(alpha: 0.3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() { _selectedDate = d; _selectedSlot = null; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? _primary : Colors.grey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDateShort(d),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : _textDark,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            allFull ? 'مكتمل' : '$availableCount/$totalCount',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : allFull
                                      ? Colors.grey.shade400
                                      : _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Hours grid ─────────────────────────────────────────────

  Widget _buildHoursGrid() {
    final slots = slotsForSelectedDate;
    if (slots.isEmpty) {
      return const Center(
        child: Text('لا توجد ساعات متاحة في هذا اليوم',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'الساعات المتاحة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.7,
              ),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final isSelected = _selectedSlot != null &&
                    _sameDay(_selectedSlot!.date, slot.date) &&
                    _selectedSlot!.hour == slot.hour;
                return _buildHourChip(slot, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourChip(SlotInfo slot, bool isSelected) {
    final Color bg;
    final Color border;
    final Color text;

    if (isSelected) {
      bg = _primary;
      border = _primary;
      text = Colors.white;
    } else if (!slot.isAvailable) {
      bg = const Color(0xFFF9FAFB);
      border = const Color(0xFFE5E7EB);
      text = const Color(0xFF9CA3AF);
    } else {
      bg = Colors.white;
      border = const Color(0xFFE5E7EB);
      text = _textDark;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 2 : 0,
      shadowColor: _primary.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: slot.isAvailable ? () => setState(() => _selectedSlot = slot) : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: border, width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour label — strikethrough when full
              Text(
                slot.hourLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: text,
                  decoration: !slot.isAvailable ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFF9CA3AF),
                  decorationThickness: 2,
                ),
              ),
              const SizedBox(height: 3),
              // Capacity label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.15)
                      : !slot.isAvailable
                          ? const Color(0xFFFEE2E2)
                          : _primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slot.capacityLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : !slot.isAvailable
                            ? const Color(0xFFDC2626)
                            : _primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Thin capacity bar
              _buildCapacityBar(slot, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapacityBar(SlotInfo slot, bool isSelected) {
    final ratio = slot.studentsPerHour > 0
        ? slot.currentCount / slot.studentsPerHour
        : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 3,
        child: Row(
          children: [
            Flexible(
              flex: (ratio * 100).round().clamp(0, 100),
              child: Container(color: !slot.isAvailable ? const Color(0xFFFCA5A5) : isSelected ? Colors.white.withValues(alpha: 0.5) : _primary.withValues(alpha: 0.2)),
            ),
            if (ratio < 1.0)
              Flexible(
                flex: ((1 - ratio) * 100).round().clamp(1, 100),
                child: Container(color: isSelected ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF3F4F6)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(const Color(0xFFE5E7EB), 'متاح'),
        const SizedBox(width: 14),
        _legendDot(const Color(0xFFFCA5A5), 'ممتلئ'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  // ── Actions (matching confirm dialog pattern) ──────────────

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'تخطي (تلقائي)',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedSlot != null ? () => Navigator.pop(context, _selectedSlot) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selectedSlot != null ? 'تأكيد الموعد' : 'اختر موعداً',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _formatDateShort(DateTime d) {
    const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return '${days[d.weekday % 7]} ${d.day}/${d.month}';
  }
}
