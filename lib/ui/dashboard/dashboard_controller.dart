import 'package:flutter/foundation.dart';
import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';
import '../../services/supabase_service.dart';
import '../../core/error/error_handler.dart';

class DashboardController extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Student> _students = [];
  List<CompetitionLevel> _levels = [];
  bool _isLoading = true;
  String? _error;

  List<Student> get students => _students;
  List<CompetitionLevel> get levels => _levels;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isReady => !_isLoading && _error == null;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getAllStudents(),
        _service.getLevels(),
      ]);
      _students = results[0] as List<Student>;
      _levels = results[1] as List<CompetitionLevel>;
    } catch (e) {
      _error = AppErrorHandler.classify(e, context: 'تحميل البيانات').userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStudents() async {
    try {
      _students = await _service.getAllStudents();
      notifyListeners();
    } catch (e) {
      _error = AppErrorHandler.classify(e, context: 'تحديث الطلاب').userMessage;
      notifyListeners();
    }
  }

  Future<void> refreshLevels() async {
    try {
      _levels = await _service.getLevels();
      notifyListeners();
    } catch (e) {
      _error = AppErrorHandler.classify(e, context: 'تحديث المستويات').userMessage;
      notifyListeners();
    }
  }

  void addStudent(Student student) {
    _students.insert(0, student);
    notifyListeners();
  }

  void updateStudent(int id, Student updated) {
    final index = _students.indexWhere((s) => s.id == id);
    if (index != -1) {
      _students[index] = updated;
      notifyListeners();
    }
  }

  void removeStudent(int id) {
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void removeStudentsBatch(List<int> ids) {
    _students.removeWhere((s) => s.id != null && ids.contains(s.id!));
    notifyListeners();
  }

  void addLevel(CompetitionLevel level) {
    _levels.add(level);
    notifyListeners();
  }

  void updateLevel(int id, CompetitionLevel updated) {
    final index = _levels.indexWhere((l) => l.id == id);
    if (index != -1) {
      _levels[index] = updated;
      notifyListeners();
    }
  }

  void removeLevel(int id) {
    _levels.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
