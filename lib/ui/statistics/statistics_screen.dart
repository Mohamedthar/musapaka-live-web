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

  static const _primary = Color(0xFF03121C);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
        }
        map[key]!['total'] = map[key]!['total'] + 1;
        if (r.rankNumber == 1) map[key]!['winners'] = map[key]!['winners'] + 1;
        if (r.rankNumber <= 3) map[key]!['top3'] = map[key]!['top3'] + 1;
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

    if (allStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.person_pin_circle_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('لا يوجد محفظين مسجلين', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF595959))),
          ]),
        ),
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
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: allStats.asMap().entries.map((e) => _buildMemorizerCard(e.key, e.value)).toList()),
        ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(children: [
                Expanded(child: _buildCounterBox(totalMemorizers, false)),
              ]),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            Expanded(child: _buildMemorizerTable(allStats)),
          ]),
        ),
      ),
    );
  }

  Widget _buildMemorizerTable(List<MemorizerStat> stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            const SizedBox(width: 40, child: Text('#', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF595959)))),
            const Expanded(flex: 3, child: Text('المحفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF595959)))),
            const Expanded(flex: 2, child: Text('الطلاب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF595959)))),
            const Expanded(flex: 2, child: Text('🏆 المركز الأول', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF595959)))),
            const Expanded(flex: 2, child: Text('أول 3', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF595959)))),
          ]),
        ),
        ...stats.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          final isTop = i < 3;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isTop ? Colors.amber.shade50.withValues(alpha: 0.3) : (i % 2 == 0 ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.3)),
              border: i < stats.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
            ),
            child: Row(children: [
              SizedBox(
                width: 40,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isTop ? Colors.amber.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w900, color: isTop ? Colors.amber.shade800 : const Color(0xFF595959))),
                ),
              ),
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF03121C))),
                if (m.phone != null && m.phone!.isNotEmpty)
                  Text('📞 ${m.phone}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade400)),
              ])),
              Expanded(flex: 2, child: Text('${m.totalStudents}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: _primary))),
              Expanded(flex: 2, child: Text('${m.winnersCount}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: m.winnersCount > 0 ? Colors.amber.shade800 : Colors.grey.shade400))),
              Expanded(flex: 2, child: Text('${m.top3Count}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: m.top3Count > 0 ? Colors.indigo.shade700 : Colors.grey.shade400))),
            ]),
          );
        }),
      ]),
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
