import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/competition_level.dart';
import '../../../services/supabase_service.dart';
import '../../../core/utils/app_logger.dart';

class LevelsSidePanel extends StatefulWidget {
  final CompetitionLevel? level;
  final VoidCallback onClose;
  final Function(CompetitionLevel) onSave;
  final bool isSaving;
  final Color primaryColor;
  final double? width;

  const LevelsSidePanel({
    super.key,
    required this.level,
    required this.onClose,
    required this.onSave,
    required this.isSaving,
    required this.primaryColor,
    this.width,
  });

  @override
  State<LevelsSidePanel> createState() => _LevelsSidePanelState();
}

class _LevelsSidePanelState extends State<LevelsSidePanel> {
  late TextEditingController _titleCtrl, _contentCtrl, _notesCtrl, _minAgeCtrl, _maxAgeCtrl, _capCtrl, _totalPointsCtrl, _passingPercentageCtrl, _rewayaMaxScoreCtrl, _availableRewayasCtrl, _tajweedMaxScoreCtrl, _voiceMaxScoreCtrl, _meaningMaxScoreCtrl, _branchesCtrl, _firstPrizeCtrl, _secondPrizeCtrl, _thirdPrizeCtrl, _prizesCtrl;
  bool _hasRewaya = false;
  bool _hasTajweed = false;
  bool _hasVoice = false;
  bool _hasMeaning = false;
  bool _isActive = true;
  bool _requireCustomAmount = false;
  bool _hasBranches = false;
  String _ageType = 'all';
  final _service = SupabaseService();
  Timer? _titleDebounce;
  bool _isDuplicateTitle = false;
  bool _isCheckingTitle = false;
  int _currentStudentsCount = 0;

  @override
  void initState() {
    super.initState();
    _initCtrls();
    _titleCtrl.addListener(_onTitleChanged);
    _loadStudentCount();
  }

  Future<void> _loadStudentCount() async {
    if (widget.level != null) {
      try {
        final count = await _service.getStudentsCountByLevel(widget.level!.title);
        if (mounted) {
          setState(() {
            _currentStudentsCount = count;
          });
        }
      } catch (e) {
        AppLogger.info('Error loading student count: $e');
      }
    }
  }

  void _initCtrls() {
    _titleCtrl = TextEditingController(text: widget.level?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.level?.content ?? '');
    _notesCtrl = TextEditingController(text: widget.level?.notes ?? '');
    _minAgeCtrl = TextEditingController(text: widget.level?.minAge?.toString() ?? '');
    _maxAgeCtrl = TextEditingController(text: widget.level?.maxAge?.toString() ?? '');
    _capCtrl = TextEditingController(text: widget.level?.maxCapacity?.toString() ?? '');
    _totalPointsCtrl = TextEditingController(text: widget.level?.totalPoints?.toString() ?? '100');
    _passingPercentageCtrl = TextEditingController(text: widget.level?.passingPercentage?.toString() ?? '95');
    _isActive = widget.level?.isActive ?? true;
    _rewayaMaxScoreCtrl = TextEditingController(text: widget.level?.rewayaMaxScore.toString() ?? '100');
    _availableRewayasCtrl = TextEditingController(text: widget.level?.availableRewayas.join('، ') ?? '');
    _tajweedMaxScoreCtrl = TextEditingController(text: widget.level?.tajweedMaxScore.toString() ?? '100');
    _voiceMaxScoreCtrl = TextEditingController(text: widget.level?.voiceMaxScore.toString() ?? '100');
    _meaningMaxScoreCtrl = TextEditingController(text: widget.level?.meaningMaxScore.toString() ?? '100');
    _branchesCtrl = TextEditingController(text: widget.level?.branches.join('، ') ?? '');
    _firstPrizeCtrl = TextEditingController(text: widget.level?.firstPrize ?? '');
    _secondPrizeCtrl = TextEditingController(text: widget.level?.secondPrize ?? '');
    _thirdPrizeCtrl = TextEditingController(text: widget.level?.thirdPrize ?? '');
    _prizesCtrl = TextEditingController(text: widget.level?.prizes ?? '');
    _hasRewaya = widget.level?.hasRewaya ?? false;
    _hasTajweed = widget.level?.hasTajweed ?? false;
    _hasVoice = widget.level?.hasVoice ?? false;
    _hasMeaning = widget.level?.hasMeaning ?? false;
    _requireCustomAmount = widget.level?.requireCustomAmount ?? false;
    _hasBranches = widget.level?.branches.isNotEmpty ?? false;

    _ageType = widget.level?.ageOp ?? 'all';
    if (_ageType == 'all') {
      final hasMin = widget.level?.minAge != null;
      final hasMax = widget.level?.maxAge != null;
      if (hasMin && hasMax) _ageType = 'range';
      else if (hasMin) _ageType = 'gte';
      else if (hasMax) _ageType = 'lte';
    }
  }

  void _onTitleChanged() {
    if (_titleDebounce?.isActive ?? false) _titleDebounce?.cancel();

    final title = _titleCtrl.text.trim();
    if (title.length < 2) {
      if (_isDuplicateTitle) setState(() => _isDuplicateTitle = false);
      return;
    }

    _titleDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isCheckingTitle = true);

      try {
        final exists = await _service.checkLevelTitleExists(title,
            excludeId: widget.level?.id);
        if (mounted) {
          setState(() {
            _isDuplicateTitle = exists;
            _isCheckingTitle = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isCheckingTitle = false);
      }
    });
  }

  @override
  void didUpdateWidget(LevelsSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _titleCtrl.removeListener(_onTitleChanged);
      _initCtrls();
      _titleCtrl.addListener(_onTitleChanged);
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleDebounce?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _notesCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _capCtrl.dispose();
    _totalPointsCtrl.dispose();
    _passingPercentageCtrl.dispose();
    _rewayaMaxScoreCtrl.dispose();
    _availableRewayasCtrl.dispose();
    _tajweedMaxScoreCtrl.dispose();
    _voiceMaxScoreCtrl.dispose();
    _meaningMaxScoreCtrl.dispose();
    _branchesCtrl.dispose();
    _firstPrizeCtrl.dispose();
    _secondPrizeCtrl.dispose();
    _thirdPrizeCtrl.dispose();
    _prizesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Container(
      width: isMobile ? double.infinity : (widget.width ?? 400),
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        boxShadow: isMobile ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.circular(24),
        child: Column(children: [
          if (isMobile) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: widget.primaryColor,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.level == null ? Icons.layers_rounded : Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                widget.level == null ? 'إضافة مستوى جديد' : 'تعديل بيانات المستوى',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(_titleCtrl, 'اسم المستوى', Icons.layers_rounded,
                        suffixIcon: _isCheckingTitle
                            ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                            : _isDuplicateTitle
                                ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                : null),
                    if (_isDuplicateTitle)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 12),
                        child: Text(
                          'هذا الاسم موجود مسبقاً',
                          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _field(_contentCtrl, 'المحتوى المطلوب', Icons.menu_book_rounded, maxLines: 4),
                    const SizedBox(height: 12),
                    _field(_notesCtrl, 'ملاحظات إضافية (اختياري)', Icons.note_rounded, maxLines: 2),
                    const SizedBox(height: 12),
                    _ageDropdown(),
                    if (_ageType != 'all') ...[
                      const SizedBox(height: 12),
                      if (_ageType == 'gt')
                        _field(_minAgeCtrl, 'الحد الأدنى (أكبر من)', Icons.arrow_upward_rounded, isNum: true),
                      if (_ageType == 'gte')
                        _field(_minAgeCtrl, 'الحد الأدنى (أكبر من أو يساوي)', Icons.arrow_upward_rounded, isNum: true),
                      if (_ageType == 'lt')
                        _field(_maxAgeCtrl, 'الحد الأقصى (أصغر من)', Icons.arrow_downward_rounded, isNum: true),
                      if (_ageType == 'lte')
                        _field(_maxAgeCtrl, 'الحد الأقصى (أصغر من أو يساوي)', Icons.arrow_downward_rounded, isNum: true),
                      if (_ageType == 'range') ... [
                        Row(children: [
                          Expanded(child: _field(_minAgeCtrl, 'من عمر', Icons.arrow_upward_rounded, isNum: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_maxAgeCtrl, 'إلى عمر', Icons.arrow_downward_rounded, isNum: true)),
                        ]),
                      ],
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_capCtrl, 'الاستيعاب', Icons.group_rounded, isNum: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_totalPointsCtrl, 'النقاط الأساسية (درجة الحفظ)', Icons.score_rounded, isNum: true)),
                    ]),
                    const SizedBox(height: 12),
                    _field(_passingPercentageCtrl, 'نسبة النجاح للتكريم %', Icons.emoji_events_rounded, isNum: true),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // 1. Level Activation
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.check_circle_outline_rounded, 
                          color: _isActive ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل المستوى (يظهر للمتسابقين)', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 2. Rewaya Assessment
                    SwitchListTile(
                      value: _hasRewaya,
                      onChanged: (v) => setState(() => _hasRewaya = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.menu_book_rounded, 
                          color: _hasRewaya ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل اختبار الروايات أو القراءات', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _hasRewaya ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(children: [
                          _field(_rewayaMaxScoreCtrl, 'الدرجة العظمى لاختبار الرواية', Icons.score_rounded, isNum: true),
                          const SizedBox(height: 12),
                          _field(_availableRewayasCtrl, 'الروايات أو القراءات المتاحة (افصل بينها بفاصلة)', Icons.format_list_bulleted_rounded),
                        ]),
                      ) : const SizedBox.shrink(),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 3. Tajweed Assessment
                    SwitchListTile(
                      value: _hasTajweed,
                      onChanged: (v) => setState(() => _hasTajweed = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.record_voice_over_rounded, 
                          color: _hasTajweed ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل تقييم أحكام التجويد', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _hasTajweed ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _field(_tajweedMaxScoreCtrl, 'الدرجة العظمى لتقييم التجويد', Icons.score_rounded, isNum: true),
                      ) : const SizedBox.shrink(),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 4. Voice Assessment
                    SwitchListTile(
                      value: _hasVoice,
                      onChanged: (v) => setState(() => _hasVoice = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.hearing_rounded, 
                          color: _hasVoice ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل تقييم حلاوة الصوت والتأثير', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _hasVoice ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _field(_voiceMaxScoreCtrl, 'الدرجة العظمى لتقييم الصوت', Icons.score_rounded, isNum: true),
                      ) : const SizedBox.shrink(),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 5. Meaning Assessment
                    SwitchListTile(
                      value: _hasMeaning,
                      onChanged: (v) => setState(() => _hasMeaning = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.psychology_rounded, 
                          color: _hasMeaning ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل تقييم فهم معاني الكلمات', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _hasMeaning ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _field(_meaningMaxScoreCtrl, 'الدرجة العظمى لتقييم فهم المعاني', Icons.score_rounded, isNum: true),
                      ) : const SizedBox.shrink(),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 6. Level Branches
                    SwitchListTile(
                      value: _hasBranches,
                      onChanged: (v) => setState(() {
                        _hasBranches = v;
                        if (!v) _branchesCtrl.clear();
                      }),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.account_tree_outlined,
                          color: _hasBranches ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('تفعيل فروع / أقسام المستوى', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _hasBranches ? Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أدخل الفروع مفصولة بفاصلة (،) مرتبةً من الأكبر للأصغر.',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            _field(_branchesCtrl, 'الفروع (مثال: القرآن كاملاً، نصف القرآن، خمسة أجزاء)', Icons.list_alt_rounded, maxLines: 2),
                          ],
                        ),
                      ) : const SizedBox.shrink(),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 7. Prizes
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(Icons.emoji_events_rounded, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 10),
                        const Text('جوائز المستوى', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    _field(_firstPrizeCtrl, 'الجائزة الأولى', Icons.looks_one_rounded, maxLines: 1),
                    const SizedBox(height: 10),
                    _field(_secondPrizeCtrl, 'الجائزة الثانية', Icons.looks_two_rounded, maxLines: 1),
                    const SizedBox(height: 10),
                    _field(_thirdPrizeCtrl, 'الجائزة الثالثة', Icons.looks_3_rounded, maxLines: 1),
                    const SizedBox(height: 14),
                    _field(_prizesCtrl, 'نص عام للجوائز (اختياري — مثل: "الجائزة على أساس عدد الأجزاء المحفوظة")', Icons.description_rounded, maxLines: 3),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'إذا أُدخل هذا الحقل يُعرض بدلاً من الجوائز الثلاثة المنفصلة.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ),
                    Divider(height: 20, color: Colors.grey.shade200),

                    // 8. Require Custom Amount (ذوي الهمم)
                    SwitchListTile(
                      value: _requireCustomAmount,
                      onChanged: (v) => setState(() => _requireCustomAmount = v),
                      dense: true,
                      activeThumbColor: widget.primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: Row(children: [
                        Icon(Icons.edit_note_rounded,
                          color: _requireCustomAmount ? widget.primaryColor : Colors.grey.shade400, size: 20),
                        const SizedBox(width: 10),
                        const Text('يتطلب إدخال كمية الحفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _requireCustomAmount ? Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          'المتسابق سيكتب بيده الكمية التي يحفظها عند التسجيل (مناسب لمستوى ذوي الهمم).',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.grey.shade500),
                        ),
                      ) : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (widget.isSaving || _isDuplicateTitle) ? null : () {
                          if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
                          final cap = int.tryParse(_capCtrl.text);
                          if (cap != null && widget.level != null && cap < _currentStudentsCount) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'لا يمكن تقليل الحد الأقصى للمتسابقين ($cap) عن عدد المتسابقين المسجلين حالياً ($_currentStudentsCount)',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          widget.onSave(CompetitionLevel(
                            id: widget.level?.id,
                            title: _titleCtrl.text.trim(),
                            content: _contentCtrl.text.trim(),
                            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                            minAge: _ageType == 'all' || _ageType == 'lte' || _ageType == 'lt' ? null : int.tryParse(_minAgeCtrl.text),
                            maxAge: _ageType == 'all' || _ageType == 'gte' || _ageType == 'gt' ? null : int.tryParse(_maxAgeCtrl.text),
                            ageOp: _ageType == 'all' ? null : _ageType,
                            maxCapacity: cap,
                            isActive: _isActive,
                            totalPoints: int.tryParse(_totalPointsCtrl.text) ?? 100,
                            passingPercentage: int.tryParse(_passingPercentageCtrl.text) ?? 95,
                            hasRewaya: _hasRewaya,
                            rewayaMaxScore: int.tryParse(_rewayaMaxScoreCtrl.text) ?? 100,
                            availableRewayas: _availableRewayasCtrl.text.trim().isEmpty ? [] : _availableRewayasCtrl.text.split(RegExp(r'[،,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            hasTajweed: _hasTajweed,
                            tajweedMaxScore: int.tryParse(_tajweedMaxScoreCtrl.text) ?? 100,
                            hasVoice: _hasVoice,
                            voiceMaxScore: int.tryParse(_voiceMaxScoreCtrl.text) ?? 100,
                            hasMeaning: _hasMeaning,
                            meaningMaxScore: int.tryParse(_meaningMaxScoreCtrl.text) ?? 100,
                            branches: _branchesCtrl.text.trim().isEmpty ? [] : _branchesCtrl.text.split(RegExp(r'[،,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            requireCustomAmount: _requireCustomAmount,
                            firstPrize: _firstPrizeCtrl.text.trim().isEmpty ? null : _firstPrizeCtrl.text.trim(),
                            secondPrize: _secondPrizeCtrl.text.trim().isEmpty ? null : _secondPrizeCtrl.text.trim(),
                            thirdPrize: _thirdPrizeCtrl.text.trim().isEmpty ? null : _thirdPrizeCtrl.text.trim(),
                            prizes: _prizesCtrl.text.trim().isEmpty ? null : _prizesCtrl.text.trim(),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: widget.isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('حفظ البيانات', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool isNum = false, int maxLines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _ageDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _ageType,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        labelText: 'شروط العمر',
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.cake_outlined, size: 20, color: widget.primaryColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      isExpanded: true,
      onChanged: (v) => setState(() {
        _ageType = v!;
        if (_ageType == 'all') { _minAgeCtrl.clear(); _maxAgeCtrl.clear(); }
        if (_ageType == 'gt' || _ageType == 'gte') { _maxAgeCtrl.clear(); }
        if (_ageType == 'lt' || _ageType == 'lte') { _minAgeCtrl.clear(); }
      }),
      items: [
        _buildAgeMenuItem('all', 'جميع الأعمار', Icons.all_inclusive_rounded, Colors.green),
        _buildAgeMenuItem('gte', 'العمر ... فأكثر (≥)', Icons.arrow_upward_rounded, Colors.indigo),
        _buildAgeMenuItem('gt', 'العمر أكبر من (>)', Icons.arrow_upward_rounded, Colors.blue),
        _buildAgeMenuItem('lte', 'العمر ... فأقل (≤)', Icons.arrow_downward_rounded, Colors.deepOrange),
        _buildAgeMenuItem('lt', 'العمر أصغر من (<)', Icons.arrow_downward_rounded, Colors.orange),
        _buildAgeMenuItem('range', 'من عمر إلى عمر', Icons.compare_arrows_rounded, Colors.purple),
      ],
    );
  }

  DropdownMenuItem<String> _buildAgeMenuItem(String value, String label, IconData icon, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: widget.primaryColor)),
      ]),
    );
  }
}
