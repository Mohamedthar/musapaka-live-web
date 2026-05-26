import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _studentColumns = 'id, student_code, ceremony_code, name, phone, national_id, age, gender, level, selected_rewaya, branch_name, memorization_amount, memorizer_name, memorizer_phone, memorizer_address, location, birth_date, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, birth_certificate_url, exam_date, exam_hour, notes, created_at, updated_at';

  Future<List<Student>> getAllStudents({int? limit, int? offset}) async {
    try {
      var query = _client
          .from(AppConstants.tableName)
          .select(_studentColumns)
          .order('created_at', ascending: false);
      if (limit != null) query = query.limit(limit);
      if (offset != null) query = query.range(offset, offset + (limit ?? 1000) - 1);
      final List<dynamic> data = await query;
      return data.map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل في جلب البيانات: $e');
    }
  }

  Future<Student> getStudentById(int id) async {
    try {
      final data = await _client
          .from(AppConstants.tableName)
          .select(_studentColumns)
          .eq('id', id)
          .single();
      return Student.fromJson(data);
    } catch (e) {
      throw Exception('لم يتم العثور على الطالب أو فشل في الجلب: $e');
    }
  }

  Future<bool> checkNationalIdExists(String nationalId, {int? excludeId}) async {
    try {
      var query = _client
          .from(AppConstants.tableName)
          .select('id')
          .eq('national_id', nationalId);
      
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }
      
      final data = await query;
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من الرقم القومي: $e');
    }
  }

  Future<bool> checkNameExists(String name, {int? excludeId}) async {
    try {
      var query = _client
          .from(AppConstants.tableName)
          .select('id')
          .eq('name', name.trim());

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final data = await query;
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من الاسم: $e');
    }
  }

  Future<Student> createStudent(Student student) async {
    try {
      final data = await _client
          .from(AppConstants.tableName)
          .insert(student.toJson())
          .select()
          .single();
      return Student.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.message.contains('المستوى المطلوب ممتلئ')) {
        throw Exception('عذراً، هذا المستوى ممتلئ تماماً بالحد الأقصى للمتسابقين.');
      }
      // Handle unique constraint violations (race condition protection)
      if (e.code == '23505') {
        if (e.message.contains('students_phone_unique')) {
          throw Exception('رقم الهاتف موجود مسبقاً');
        }
        if (e.message.contains('students_national_id_unique')) {
          throw Exception('هذا الرقم القومي مسجّل مسبقاً');
        }
        if (e.message.contains('students_name_unique')) {
          throw Exception('هذا الاسم مسجّل مسبقاً');
        }
        throw Exception('بيانات مكررة - يرجى المحاولة مرة أخرى');
      }
      throw Exception('فشل في انشاء الطالب: $e');
    } catch (e) {
      throw Exception('فشل في انشاء الطالب: $e');
    }
  }

  Future<Student> updateStudent(int id, Student student) async {
    try {
      final data = await _client
          .from(AppConstants.tableName)
          .update(student.toJsonForUpdate())
          .eq('id', id)
          .select()
          .single();
      return Student.fromJson(data);
    } catch (e) {
      throw Exception('فشل في تحديث الطالب: $e');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await _client.from(AppConstants.tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل في حذف الطالب: $e');
    }
  }

  Future<void> deleteStudentsBatch(List<int> ids) async {
    try {
      await _client.from(AppConstants.tableName).delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في الحذف الجماعي: $e');
    }
  }

  Future<void> updateStudentsBatch(List<int> ids, Map<String, dynamic> updates) async {
    try {
      await _client.from(AppConstants.tableName).update(updates).inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في التحديث الجماعي: $e');
    }
  }

  Future<int> getStudentsCountByLevel(String levelTitle) async {
    try {
      final response = await _client
          .from(AppConstants.tableName)
          .select('*')
          .eq('level', levelTitle)
          .limit(0)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('فشل في التحقق من عدد الطلاب: $e');
    }
  }

  Future<bool> checkLevelTitleExists(String title, {int? excludeId}) async {
    try {
      var query = _client
          .from('competition_levels')
          .select('id')
          .eq('title', title.trim());

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final data = await query;
      return (data as List).isNotEmpty;
    } catch (e) {
      throw Exception('فشل في التحقق من اسم المستوى: $e');
    }
  }

  // --- Competition Levels ---

  Future<List<CompetitionLevel>> getLevels() async {
    try {
      final List<dynamic> data = await _client
          .from('competition_levels')
          .select()
          .order('id', ascending: true);
      return data.map((json) => CompetitionLevel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل في جلب المستويات: $e');
    }
  }

  Future<CompetitionLevel> createLevel(CompetitionLevel level) async {
    try {
      final data = await _client
          .from('competition_levels')
          .insert(level.toJson())
          .select()
          .single();
      return CompetitionLevel.fromJson(data);
    } catch (e) {
      throw Exception('فشل في اضافة المستوى: $e');
    }
  }

  Future<CompetitionLevel> updateLevel(int id, CompetitionLevel level) async {
    try {
      final data = level.toJson();
      data.remove('id');
      
      final result = await _client
          .from('competition_levels')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return CompetitionLevel.fromJson(result);
    } catch (e) {
      throw Exception('فشل في تحديث المستوى: $e');
    }
  }

  Future<void> deleteLevel(int id) async {
    try {
      await _client.from('competition_levels').delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل في حذف المستوى: $e');
    }
  }

  Future<void> deleteLevelsBatch(List<int> ids) async {
    try {
      await _client.from('competition_levels').delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في الحذف الجماعي للمستويات: $e');
    }
  }

  Future<void> updateLevelsBatch(List<int> ids, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      await _client.from('competition_levels').update(updates).inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في التحديث الجماعي للمستويات: $e');
    }
  }

  // --- App Settings ---

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      return await _client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
    } catch (e) {
      throw Exception('فشل في جلب الإعدادات: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from('app_settings')
          .update(data)
          .eq('id', 1)
          .select();
    } catch (e) {
      throw Exception('فشل في حفظ الإعدادات: $e');
    }
  }


  // --- Ceremony ---

  Future<void> generateCeremonyCodes() async {
    try {
      await _client.rpc('generate_all_ceremony_codes');
    } catch (e) {
      throw Exception('فشل في توليد أكواد الحفل: $e');
    }
  }

  Future<Map<String, dynamic>?> queryCeremonyAttendance(String nationalId) async {
    try {
      final response = await _client.rpc('query_ceremony_attendance', params: {
        'p_national_id': nationalId,
      });
      if (response != null && (response as List).isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (e.toString().contains('الاستعلام عن حضور الحفل غير متاح')) {
        throw Exception('الاستعلام عن حضور الحفل غير متاح حالياً.');
      }
      throw Exception('فشل في الاستعلام: $e');
    }
  }
}

