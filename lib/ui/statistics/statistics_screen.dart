import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ranking_utils.dart';
import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';
import '../../services/supabase_service.dart';
import '../../services/export_service.dart';
import '../dashboard/widgets/stats_cards.dart';
import 'widgets/statistics_kpi_cards.dart';
import 'widgets/statistics_ranking_table.dart';

class MemorizerStat {
  final String name;
  final String? phone;
  final int totalStudents;
  final int winnersCount;
  final int top3Count;

  MemorizerStat({
    required this.name,
    required this.phone,
    required this.totalStudents,
    required this.winnersCount,
    required this.top3Count,
  });
}

class _MemorizerStudentDetail {
  final String studentName;
  final String level;
  final int rank;
  final double? totalScore;
  final String rankTitle;
  final double percentage;

  _MemorizerStudentDetail({
    required this.studentName,
    required this.level,
    required this.rank,
    required this.totalScore,
    required this.rankTitle,
    required this.percentage,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  String? _error;

  List<CompetitionLevel> _levels = [];
  List<Student> _allStudents = [];
  CompetitionLevel? _selectedLevel;

  // Search State
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Score Filter State
  double? _minScoreFilter;
  double? _maxScoreFilter;

  // Percentage Filter State
  double? _minPctFilter;
  double? _maxPctFilter;

  // Sort State
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Cached results
  List<Student> _cachedFiltered = [];
  List<RankedStudent> _cachedRanked = [];
  bool _needsRecompute = true;

  // View toggle
  bool _showMemorizerBoard = false;
  List<MemorizerStat> _memorizerStats = [];
  Map<String, List<_MemorizerStudentDetail>> _memorizerDetails = {};
  String _memorizerSearch = '';
  int? _expandedMemorizerIndex;
  final TextEditingController _memorizerSearchCtrl = TextEditingController();

  static const _primary = Color(0xFF03121C);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _memorizerSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_service.getLevels(), _service.getAllStudents()]);
      final levels = results[0] as List<CompetitionLevel>;
      final students = results[1] as List<Student>;
      if (!mounted) return;
      setState(() {
        _levels = levels;
        _allStudents = students;
        if (_levels.isNotEmpty) _selectedLevel = _levels.first;
        _isLoading = false;
        _needsRecompute = true;
        _computeMemorizerStats();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل البيانات: $e';
        _isLoading = false;
        _needsRecompute = true;
      });
    }
  }

  List<Student> get _filteredStudents {
    if (_needsRecompute) _computeDerived();
    return _cachedFiltered;
  }

  List<RankedStudent> get _rankedStudents {
    if (_needsRecompute) _computeDerived();
    return _cachedRanked;
  }

  void _computeDerived() {
    _needsRecompute = false;
    if (_selectedLevel == null) {
      _cachedFiltered = [];
      _cachedRanked = [];
      return;
    }
    Iterable<Student> filtered = _allStudents.where((s) => s.level == _selectedLevel!.title);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          (s.nationalId != null && s.nationalId!.contains(q)));
    }
    
    if (_minScoreFilter != null) {
      filtered = filtered.where((s) => (s.totalScore ?? 0) >= _minScoreFilter!);
    }
    if (_maxScoreFilter != null) {
      filtered = filtered.where((s) => (s.totalScore ?? 0) <= _maxScoreFilter!);
    }
    
    _cachedFiltered = filtered.toList();
    _cachedRanked = RankingUtils.calculateRanks(_cachedFiltered, _levels);

    if (_minPctFilter != null) {
      _cachedRanked.removeWhere((r) => r.percentage < _minPctFilter!);
    }
    if (_maxPctFilter != null) {
      _cachedRanked.removeWhere((r) => r.percentage > _maxPctFilter!);
    }
    
    if (_sortColumnIndex != null) {
      _cachedRanked.sort((a, b) {
        int comp = 0;
        switch (_sortColumnIndex) {
          case 0:
            comp = a.rankNumber.compareTo(b.rankNumber);
            break;
          case 1:
            comp = a.student.name.compareTo(b.student.name);
            break;
          case 2:
            comp = a.student.phone.compareTo(b.student.phone);
            break;
          case 3:
            comp = (a.student.nationalId ?? '').compareTo(b.student.nationalId ?? '');
            break;
          case 4:
            comp = (a.student.totalScore ?? 0).compareTo(b.student.totalScore ?? 0);
            break;
        }
        return _sortAscending ? comp : -comp;
      });
    }
  }

  void _computeMemorizerStats() {
    final map = <String, Map<String, dynamic>>{};
    final detailsMap = <String, List<_MemorizerStudentDetail>>{};
    for (final level in _levels) {
      final levelStudents = _allStudents.where((s) => s.level == level.title).toList();
      final ranked = RankingUtils.calculateRanks(levelStudents, [level]);
      for (final r in ranked) {
        final name = r.student.memorizerName?.trim();
        if (name == null || name.isEmpty) continue;
        final phone = r.student.memorizerPhone?.trim();
        final key = (phone != null && phone.isNotEmpty) ? '📞$phone' : '👤$name';
        if (!map.containsKey(key)) {
          map[key] = {'name': name, 'phone': phone, 'total': 0, 'winners': 0, 'top3': 0};
          detailsMap[key] = [];
        }
        map[key]!['total'] = map[key]!['total'] + 1;
        if (r.rankNumber == 1) map[key]!['winners'] = map[key]!['winners'] + 1;
        if (r.rankNumber <= 3) map[key]!['top3'] = map[key]!['top3'] + 1;
        detailsMap[key]!.add(_MemorizerStudentDetail(
          studentName: r.student.name,
          level: r.student.level,
          rank: r.rankNumber,
          totalScore: r.student.totalScore,
          rankTitle: r.rankTitle,
          percentage: r.percentage,
        ));
      }
    }
    _memorizerStats = map.entries.map((e) => MemorizerStat(
      name: e.value['name'],
      phone: e.value['phone'],
      totalStudents: e.value['total'],
      winnersCount: e.value['winners'],
      top3Count: e.value['top3'],
    )).toList()
      ..sort((a, b) => b.totalStudents.compareTo(a.totalStudents));
    _memorizerDetails = detailsMap;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _invalidateCache();
    });
  }

  void _exportToExcel() async {
    if (_selectedLevel == null) return;
    try {
      final ranked = _rankedStudents;
      if (ranked.isEmpty) {
        AppTheme.showSnack(context, 'لا توجد بيانات للتصدير',
            color: Colors.orange);
        return;
      }
      AppTheme.showSnack(context, 'جاري التصدير...', color: Colors.blue);
      final exportService = ExportService();
      await exportService.exportRankingsToExcel(
          _selectedLevel!, ranked);
      if (mounted) {
        AppTheme.showSnack(context, 'تم تصدير النتائج بنجاح',
            color: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnack(context, 'خطأ أثناء التصدير: $e',
            color: Colors.red);
      }
    }
  }

  Widget _viewToggleBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? _primary : Colors.grey.shade500)),
      ),
    );
  }

  void _invalidateCache() {
    _needsRecompute = true;
  }

  void _generateCeremonyCodes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد توليد الأكواد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _primary)),
        content: const Text('هل أنت متأكد من رغبتك في توليد أكواد الحفل لجميع الطلاب المتفوقين (95% فأكثر)؟\nسيتم استبدال أي أكواد قديمة إن وجدت.', style: TextStyle(fontFamily: 'Cairo')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('توليد الآن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.generateCeremonyCodes();
      await _loadData();
      if (mounted) AppTheme.showSnack(context, 'تم توليد الأكواد بنجاح!', color: Colors.green);
    } catch (e) {
      if (mounted) {
        AppTheme.showSnack(context, 'خطأ: $e', color: Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final isMobile = screenType == ScreenType.mobile;

    final ranked = _rankedStudents;
    final totalStudents = _filteredStudents.length;
    final testedStudents = ranked.length;
    final malesCount = _filteredStudents.where((s) => s.gender == 'ذكر').length;
    final femalesCount = _filteredStudents.where((s) => s.gender == 'أنثى').length;

    double highestScore = 0;
    double lowestScore = 0;
    int passedCount = 0;
    final maxLevelScore = _selectedLevel?.totalMaxPoints ?? 100;

    if (testedStudents > 0) {
      final sortedByScoreDesc = List<RankedStudent>.from(ranked)
        ..sort((a, b) => (b.student.totalScore ?? 0).compareTo(a.student.totalScore ?? 0));

      highestScore = sortedByScoreDesc.first.student.totalScore ?? 0;
      lowestScore = sortedByScoreDesc.last.student.totalScore ?? 0;
      final passingScore = maxLevelScore / 2;
      passedCount = ranked.where((r) => (r.student.totalScore ?? 0) >= passingScore).length;
    }

    return Column(
      children: [
        // ─── Top Bar ────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإحصائيات والنتائج',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                    if (!isMobile)
                      Text(
                        'لوحة الشرف وتصنيف المتسابقين حسب المستويات',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              // Generate Ceremony Codes
              if (isMobile)
                IconButton(
                  onPressed: _generateCeremonyCodes,
                  icon: const Icon(Icons.celebration_rounded, size: 20, color: Colors.purple),
                  tooltip: 'توليد أكواد الحفل',
                  visualDensity: VisualDensity.compact,
                )
              else
                ElevatedButton.icon(
                  onPressed: _generateCeremonyCodes,
                  icon: const Icon(Icons.celebration_rounded, size: 18, color: Colors.white),
                  label: const Text('توليد أكواد الحفل',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(width: 12),
              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _viewToggleBtn('المتسابقين', !_showMemorizerBoard, () => setState(() => _showMemorizerBoard = false)),
                  _viewToggleBtn('المحفظين', _showMemorizerBoard, () => setState(() => _showMemorizerBoard = true)),
                ]),
              ),
              const SizedBox(width: 12),
              // Export button
              if (isMobile)
                IconButton(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart_rounded, size: 20, color: Colors.green),
                  tooltip: 'تصدير Excel',
                  visualDensity: VisualDensity.compact,
                )
              else
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart_rounded, size: 18, color: Colors.white),
                  label: const Text('تصدير Excel',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),

        // ─── Main Body ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F7),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontFamily: 'Cairo')))
                    : _levels.isEmpty
                        ? const Center(
                            child: Text('لا توجد مستويات مضافة بعد.',
                                style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 16)))
                        : _showMemorizerBoard
                            ? _buildMemorizerBoard(isMobile)
                            : isMobile
                            // ── Mobile ─────────────────────────────────────
                            ? Column(
                                children: [
                                  Container(
                                    color: Colors.white,
                                    child: StatisticsKpiCards(
                                      totalStudents: totalStudents,
                                      testedStudents: testedStudents,
                                      highestScore: highestScore,
                                      lowestScore: lowestScore,
                                      passedCount: passedCount,
                                      malesCount: malesCount,
                                      femalesCount: femalesCount,
                                      maxLevelScore: maxLevelScore,
                                      isMobile: true,
                                    ),
                                  ),
                                  _buildFilterRow(isMobile, totalStudents),
                                  Expanded(
                                    child: StatisticsRankingTable(
                                      rankedStudents: ranked,
                                      isMobile: true,
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      onSort: _onSort,
                                    ),
                                  ),
                                ],
                              )
                            // ── Desktop ─────────────────────────────────────
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        StatisticsKpiCards(
                                            totalStudents: totalStudents,
                                            testedStudents: testedStudents,
                                            highestScore: highestScore,
                                            lowestScore: lowestScore,
                                            passedCount: passedCount,
                                            malesCount: malesCount,
                                            femalesCount: femalesCount,
                                            maxLevelScore: maxLevelScore,
                                            isMobile: false,
                                          ),
                                        _buildFilterRow(isMobile, totalStudents),
                                        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                                        Expanded(
                                          child: StatisticsRankingTable(
                                            rankedStudents: ranked,
                                            isMobile: false,
                                            sortColumnIndex: _sortColumnIndex,
                                            sortAscending: _sortAscending,
                                            onSort: _onSort,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(bool isMobile, int totalStudentsCount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
      child: isMobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 8),
                  _buildCounterBox(totalStudentsCount, isMobile),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildLevelDropdown()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildScoreFilter()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPercentageFilter()),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 2, child: _buildSearchField()),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildLevelDropdown()),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildScoreFilter()),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildPercentageFilter()),
              const SizedBox(width: 12),
              _buildCounterBox(totalStudentsCount, isMobile),
            ],
          ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() { _searchQuery = val; _invalidateCache(); }),
        style: const TextStyle(
          fontFamily: 'Cairo', 
          fontSize: 13, 
          fontWeight: FontWeight.w700, 
          color: AppTheme.primaryColor
        ),
        decoration: InputDecoration(
          hintText: 'بحث بالاسم، الهاتف أو الرقم القومي...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400, 
            fontSize: 13, 
            fontWeight: FontWeight.normal
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade400),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CompetitionLevel>(
          value: _selectedLevel,
          isExpanded: true,
          icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600,
              size: 20),
          dropdownColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: _primary,
              fontWeight: FontWeight.w700),
          items: _levels
              .map((l) => DropdownMenuItem(
                  value: l, 
                  child: Row(
                    children: [
                      Icon(Icons.layers_rounded, size: 16, color: _primary.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(l.title),
                    ],
                  ),
              ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() { _selectedLevel = val; _invalidateCache(); });
            }
          },
        ),
      ),
    );
  }

  Widget _buildScoreFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _minScoreFilter = double.tryParse(val);
                  _invalidateCache();
                });
              },
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'من',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('-', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _maxScoreFilter = double.tryParse(val);
                  _invalidateCache();
                });
              },
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'إلى',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _minPctFilter = double.tryParse(val);
                  _invalidateCache();
                });
              },
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'من %',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('-', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _maxPctFilter = double.tryParse(val);
                  _invalidateCache();
                });
              },
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'إلى %',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemorizerBoard(bool isMobile) {
    final allStats = _memorizerStats;
    final q = _memorizerSearch.trim().toLowerCase();
    final filteredStats = q.isEmpty
        ? allStats
        : allStats.where((m) => m.name.toLowerCase().contains(q) || (m.phone?.contains(q) ?? false)).toList();

    if (allStats.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_pin_circle_rounded, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text('لا يوجد محفظين مسجلين', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF595959))),
        ]),
      );
    }

    final totalMemorizers = allStats.length;
    final totalStudents = allStats.fold(0, (sum, m) => sum + m.totalStudents);
    final totalWinners = allStats.fold(0, (sum, m) => sum + m.winnersCount);
    final totalTop3 = allStats.fold(0, (sum, m) => sum + m.top3Count);

    if (isMobile) {
      return Column(children: [
        Container(
          color: Colors.white,
          child: DashboardStatsCards(stats: [
            StatEntry(title: 'المحفظين', value: '$totalMemorizers', icon: Icons.group_rounded, color: Colors.purple),
            StatEntry(title: 'إجمالي الطلاب', value: '$totalStudents', icon: Icons.people_rounded, color: Colors.blue),
            StatEntry(title: 'المركز الأول', value: '$totalWinners', icon: Icons.emoji_events_rounded, color: Colors.amber),
            StatEntry(title: 'أول 3 مراكز', value: '$totalTop3', icon: Icons.leaderboard_rounded, color: Colors.indigo),
          ]),
        ),
        _buildMemorizerFilterRow(true, filteredStats.length),
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: filteredStats.asMap().entries.map((e) => _buildMemorizerCard(e.key, e.value)).toList())),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DashboardStatsCards(stats: [
              StatEntry(title: 'المحفظين', value: '$totalMemorizers', icon: Icons.group_rounded, color: Colors.purple),
              StatEntry(title: 'إجمالي الطلاب', value: '$totalStudents', icon: Icons.people_rounded, color: Colors.blue),
              StatEntry(title: 'المركز الأول', value: '$totalWinners', icon: Icons.emoji_events_rounded, color: Colors.amber),
              StatEntry(title: 'أول 3 مراكز', value: '$totalTop3', icon: Icons.leaderboard_rounded, color: Colors.indigo),
            ]),
            _buildMemorizerFilterRow(false, filteredStats.length),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            Expanded(child: _buildMemorizerTable(filteredStats)),
          ]),
        ),
      ),
    );
  }

  Widget _buildMemorizerFilterRow(bool isMobile, int filteredCount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
      child: isMobile
          ? Row(children: [Expanded(child: _buildMemorizerSearchField()), const SizedBox(width: 8), _buildCounterBox(filteredCount, true)])
          : Row(children: [
              Expanded(child: _buildMemorizerSearchField()),
              const SizedBox(width: 16),
              _buildCounterBox(filteredCount, false),
            ]),
    );
  }

  Widget _buildMemorizerSearchField() {
    return TextField(
      controller: _memorizerSearchCtrl,
      onChanged: (v) => setState(() => _memorizerSearch = v),
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
      decoration: InputDecoration(
        hintText: 'ابحث باسم المحفظ أو رقم الهاتف...',
        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
        suffixIcon: _memorizerSearch.isNotEmpty
            ? IconButton(icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400), onPressed: () { _memorizerSearchCtrl.clear(); setState(() => _memorizerSearch = ''); })
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }

  Widget _buildMemorizerTable(List<MemorizerStat> stats) {
    if (stats.isEmpty) {
      return const Center(child: Text('لا توجد نتائج', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Color(0xFF595959))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(color: _primary),
              child: Row(children: [
                _mh2('#', 44),
                _mh2('المحفظ', null, flex: 14),
                _mh2('الهاتف', null, flex: 12, center: true),
                _mh2('الطلاب', null, flex: 6, center: true),
                _mh2('الأول', null, flex: 6, center: true),
                _mh2('أول 3', null, flex: 6, center: true),
              ]),
            ),
            ...stats.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              final phone = m.phone != null && m.phone!.isNotEmpty ? m.phone! : '';
              final isExpanded = _expandedMemorizerIndex == i;
              final students = _memorizerDetails[(phone.isNotEmpty ? '📞$phone' : '👤${m.name}')] ?? [];
              return Column(children: [
                InkWell(
                  onTap: () => setState(() => _expandedMemorizerIndex = isExpanded ? null : i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _memRowBg(i),
                      border: Border(bottom: BorderSide(color: isExpanded ? _primary.withValues(alpha: 0.15) : Colors.grey.shade100)),
                    ),
                    child: Row(children: [
                      _td2('${i + 1}', 44, center: true, color: isExpanded ? _primary : (i < 3 ? Colors.amber.shade800 : Colors.grey.shade500)),
                      _td2(m.name, null, flex: 14, bold: true),
                      _td2(phone.isNotEmpty ? phone : '---', null, flex: 12, center: true, small: true, color: phone.isNotEmpty ? Colors.grey.shade700 : Colors.grey.shade400),
                      _td2('${m.totalStudents}', null, flex: 6, center: true, bold: true),
                      _td2('${m.winnersCount}', null, flex: 6, center: true, bold: true, color: m.winnersCount > 0 ? Colors.amber.shade700 : Colors.grey.shade400),
                      _td2('${m.top3Count}', null, flex: 6, center: true, bold: true, color: m.top3Count > 0 ? Colors.indigo.shade600 : Colors.grey.shade400),
                    ]),
                  ),
                ),
                if (isExpanded && students.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    color: const Color(0xFFF8F9FB),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: Row(children: [
                            _sh('#', 36),
                            _sh('الطالب', null, flex: 3),
                            _sh('المستوى', null, flex: 2),
                            _sh('الترتيب', null, flex: 1, center: true),
                            _sh('الدرجة', 80),
                            _sh('النسبة', 60),
                          ]),
                        ),
                        ...students.asMap().entries.map((se) {
                          final s = se.value;
                          final pctColor = s.percentage >= 95 ? Colors.green : (s.percentage >= 75 ? Colors.blue : (s.percentage >= 50 ? Colors.orange : Colors.red));
                          final rankColor = s.rank == 1 ? Colors.amber.shade800 : (s.rank == 2 ? Colors.blueGrey.shade600 : (s.rank == 3 ? Colors.brown.shade500 : Colors.grey.shade600));
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(border: se.key < students.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null),
                            child: Row(children: [
                              _sd('${se.key + 1}', 36, color: Colors.grey.shade500),
                              _sd(s.studentName, null, flex: 3, bold: true),
                              _sd(s.level, null, flex: 2),
                              _sd('${s.rank}', null, flex: 1, center: true, bold: true, color: rankColor),
                              _sd(s.totalScore != null ? s.totalScore!.toStringAsFixed(0) : '---', 80, color: _primary),
                              _sd('${s.percentage.toStringAsFixed(0)}%', 60, bold: true, color: pctColor),
                            ]),
                          );
                        }),
                      ]),
                    ),
                  ),
              ]);
            }),
          ]),
        ),
      ),
    );
  }

  Color _memRowBg(int index) {
    if (index == 0) return Colors.amber.withValues(alpha: 0.04);
    if (index == 1) return Colors.blueGrey.withValues(alpha: 0.04);
    if (index == 2) return Colors.brown.withValues(alpha: 0.04);
    return index % 2 == 0 ? Colors.white : const Color(0xFFF9FBFF);
  }

  // Main table header cell
  static Widget _mh2(String label, double? width, {int? flex, bool center = false}) {
    final child = Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700));
    if (width != null) return SizedBox(width: width, child: center ? Center(child: child) : child);
    return Expanded(flex: flex ?? 1, child: center ? Center(child: child) : child);
  }

  // Main table data cell
  static Widget _td2(String? text, double? width, {int? flex, bool bold = false, bool small = false, Color? color, Widget? badge, bool center = false}) {
    Widget child;
    if (badge != null) {
      child = badge;
    } else {
      child = Text(text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: center ? TextAlign.center : null, style: TextStyle(fontFamily: 'Cairo', fontSize: small ? 12 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? const Color(0xFF1E293B)));
    }
    if (center) child = Center(child: child);
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }

  // Sub-table header
  static const _shStyle = TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888));
  static Widget _sh(String label, double? width, {int? flex, bool center = false}) {
    final child = Text(label, style: _shStyle, textAlign: center ? TextAlign.center : null);
    if (width != null) return SizedBox(width: width, child: center ? Center(child: child) : child);
    return Expanded(flex: flex ?? 1, child: center ? Center(child: child) : child);
  }

  // Sub-table data
  static Widget _sd(String? text, double? width, {int? flex, bool bold = false, Color? color, Widget? badge, bool center = false}) {
    Widget child;
    if (badge != null) {
      child = badge;
    } else {
      child = Text(text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: center ? TextAlign.center : null, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? const Color(0xFF475569)));
    }
    if (center) child = Center(child: child);
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }

  TableCell _mh(String label, {bool center = false}) {
    return TableCell(
      child: Container(
        alignment: center ? Alignment.center : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  TableCell _mc(Widget child, {bool center = false}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: center ? child : child,
      ),
    );
  }

  Widget _buildMemNumBadge(int count, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fgColor.withValues(alpha: 0.25)),
      ),
      child: Text('$count', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w900, color: count > 0 ? fgColor : Colors.grey.shade300)),
    );
  }

  void _showMemorizerStudents(MemorizerStat m, Map<String, List<_MemorizerStudentDetail>> details, String key) {
    final students = details[key] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) {
            return Column(children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.person_pin_circle_rounded, size: 20, color: Colors.purple.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
                    Text('${students.length} طالب في جميع المستويات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade500)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    color: Colors.grey.shade500,
                  ),
                ]),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: s.rank == 1 ? Colors.amber.shade100 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text('${s.rank}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w900, color: s.rank == 1 ? Colors.amber.shade800 : Colors.grey.shade600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.studentName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF03121C))),
                          Text('${s.level} • ${s.rankTitle}', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                          child: Text(s.totalScore != null ? '${s.totalScore!.toStringAsFixed(0)} نقطة' : '---', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800, color: _primary)),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _buildMemorizerCard(int i, MemorizerStat m) {
    final isTop = i < 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTop ? Colors.amber.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isTop ? Colors.amber.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isTop ? Colors.amber.shade300 : Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: Text('${i + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w900, color: isTop ? Colors.amber.shade800 : const Color(0xFF595959))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.name, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF03121C))),
          if (m.phone != null && m.phone!.isNotEmpty)
            Text('📞 ${m.phone}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500)),
          Text('${m.totalStudents} طالب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _primary.withValues(alpha: 0.5))),
        ])),
        _memorizerBadge('🏆 الأول', m.winnersCount, Colors.amber.shade700, Colors.amber.shade50),
        const SizedBox(width: 6),
        _memorizerBadge('أول 3', m.top3Count, Colors.indigo.shade700, Colors.indigo.shade50),
      ]),
    );
  }

  Widget _memorizerBadge(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Text('$count', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }

  Widget _buildCounterBox(int count, bool isMobile) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count', 
            style: const TextStyle(
              fontFamily: 'Cairo', 
              fontSize: 14, 
              fontWeight: FontWeight.w900, 
              color: _primary
            )
          ),
          if (!isMobile) ...[
            const SizedBox(width: 4),
            Text(
              'متسابق', 
              style: TextStyle(
                fontFamily: 'Cairo', 
                fontSize: 11, 
                color: Colors.grey.shade500, 
                fontWeight: FontWeight.w600
              )
            ),
          ],
        ],
      ),
    );
  }
}
