import 'package:flutter/material.dart';
import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';
import '../../services/supabase_service.dart';
import '../../core/theme/app_theme.dart';


class ExamsScreen extends StatefulWidget {
  final List<Student> students;
  final List<CompetitionLevel> levels;
  final VoidCallback onRefresh;
  final Color primaryColor;

  const ExamsScreen({
    super.key,
    required this.students,
    required this.levels,
    required this.onRefresh,
    required this.primaryColor,
  });

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String? _selectedLevel;
  String _searchQuery = '';
  final SupabaseService _service = SupabaseService();
  bool _isSaving = false;

  List<Student> get _filteredStudents {
    return widget.students.where((s) {
      if (_selectedLevel != null && s.level != _selectedLevel) return false;
      if (_searchQuery.isNotEmpty) {
        return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
               (s.nationalId?.contains(_searchQuery) ?? false);
      }
      return true;
    }).toList();
  }

  void _showGradeDialog(Student student, CompetitionLevel? level) {
    if (level == null) {
      AppTheme.showSnack(context, 'خطأ: لم يتم العثور على بيانات المستوى لهذا الطالب', color: Colors.red);
      return;
    }

    final scoreCtrl = TextEditingController(text: student.score != null ? AppTheme.formatScore(student.score!) : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: widget.primaryColor, size: 28),
            const SizedBox(width: 12),
            const Text('تقييم المتسابق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المتسابق: ${student.name}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('المستوى: ${level.title}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Text('إجمالي النقاط لهذا المستوى: ${level.totalPoints ?? 100}', 
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: scoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'الدرجة المستحقة',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.star_rounded, color: Colors.amber),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primaryColor, width: 2)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال الدرجة';
                  final score = double.tryParse(val.trim().replaceAll(',', '.'));
                  if (score == null) return 'يجب أن تكون الدرجة رقماً';
                  if (score < 0 || score > (level.totalPoints ?? 100)) {
                    return 'الدرجة يجب أن تكون بين 0 و ${level.totalPoints ?? 100}';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newScore = double.parse(scoreCtrl.text.trim().replaceAll(',', '.'));
                Navigator.pop(ctx);
                _saveScore(student, newScore);
              }
            },
            child: const Text('حفظ التقييم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScore(Student student, double newScore) async {
    setState(() => _isSaving = true);
    try {
      await _service.updateStudent(student.id!, student.copyWith(score: newScore));
      if (!mounted) return;
      AppTheme.showSnack(context, 'تم حفظ الدرجة بنجاح (${student.name}: ${AppTheme.formatScore(newScore)})');
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      AppTheme.showError(context, e, contextLabel: 'حفظ التقييم');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return Column(
      children: [
        // Top Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: widget.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.task_alt_rounded, color: widget.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              const Text('الاختبارات والتقييم', style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_isSaving)
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator()),
            ],
          ),
        ),

        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: const Color(0xFFF5F5F7),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الرقم القومي...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedLevel,
                      isExpanded: true,
                      icon: const Icon(Icons.filter_list_rounded, color: Colors.grey),
                      hint: const Text('المستوى', style: TextStyle(fontFamily: 'Cairo')),
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontWeight: FontWeight.w600),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ...widget.levels.map((l) => DropdownMenuItem(value: l.title, child: Text(l.title))),
                      ],
                      onChanged: (v) => setState(() => _selectedLevel = v),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F7),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rtl_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('لا يوجد متسابقين للاختبار', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: students.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      final level = widget.levels.where((l) => l.title == s.level).firstOrNull;
                      final isGraded = s.score != null;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: isGraded ? Colors.green.withValues(alpha: 0.3) : Colors.transparent),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isGraded ? Colors.green.shade50 : widget.primaryColor.withValues(alpha: 0.1),
                            child: Icon(isGraded ? Icons.check_circle_rounded : Icons.person_rounded, 
                              color: isGraded ? Colors.green : widget.primaryColor),
                          ),
                          title: Text(s.name, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Text(s.level, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                if (isGraded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded, size: 14, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text('${AppTheme.formatScore(s.score!)} / ${level?.totalPoints ?? 100}', 
                                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isGraded ? Colors.white : widget.primaryColor,
                              foregroundColor: isGraded ? widget.primaryColor : Colors.white,
                              side: isGraded ? BorderSide(color: widget.primaryColor) : BorderSide.none,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isGraded ? Icons.edit_note_rounded : Icons.add_task_rounded, size: 18),
                            label: Text(isGraded ? 'تعديل التقييم' : 'تقييم', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                            onPressed: () => _showGradeDialog(s, level),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
