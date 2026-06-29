import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../data/models/admin.dart';
import '../core/constants/app_constants.dart';
import '../core/error/error_handler.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _studentColumns = 'id, student_code, ceremony_code, name, phone, national_id, age, gender, level, level_id, selected_rewaya, branch_name, memorization_amount, memorizer_name, memorizer_phone, memorizer_address, location, birth_date, score, rewaya_score, tajweed_score, voice_score, meaning_score, profile_image_url, birth_certificate_url, exam_date, exam_hour, follow_up_status, notes, created_at, updated_at';

  /// Fetches all students with optional pagination.
  /// When neither [limit] nor [offset] are provided, all students are fetched
  /// by paginating through the entire table (PostgREST caps single queries at 1000 rows).
  Future<List<Student>> getAllStudents({int? limit, int? offset}) async {
    try {
      if (limit != null || offset != null) {
        // Explicit pagination requested – execute a single range query.
        var query = _client
            .from(AppConstants.tableName)
            .select(_studentColumns)
            .order('created_at', ascending: false);
        final effectiveLimit = limit ?? 100;
        final start = offset ?? 0;
        query = query.range(start, start + effectiveLimit - 1);
        final List<dynamic> data = await query;
        return data.map((json) => Student.fromJson(json)).toList();
      }

      // No limit/offset – fetch all rows by paginating.
      const int pageSize = 1000;
      final List<Student> all = [];
      int rangeStart = 0;

      while (true) {
        final data = await _client
            .from(AppConstants.tableName)
            .select(_studentColumns)
            .order('created_at', ascending: false)
            .range(rangeStart, rangeStart + pageSize - 1);

        final batch = (data as List<dynamic>).map((json) => Student.fromJson(json)).toList();
        all.addAll(batch);

        if (batch.length < pageSize) break; // last page reached
        rangeStart += pageSize;
      }

      return all;
    } catch (e) {
      throw Exception('فشل في جلب البيانات: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<int> getStudentsCount() async {
    try {
      final response = await _client
          .from(AppConstants.tableName)
          .select('id')
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('فشل في عد الطلاب: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  static const String _studentListColumns = 'id, student_code, ceremony_code, name, phone, national_id, age, gender, level, level_id, selected_rewaya, branch_name, memorization_amount, memorizer_name, memorizer_phone, location, score, rewaya_score, tajweed_score, voice_score, meaning_score, exam_date, exam_hour, follow_up_status, notes, created_at, updated_at';

  Future<List<Student>> getStudentsPage({required int offset, int limit = 50}) async {
    try {
      if (limit < 1 || limit > 200) limit = 50;
      if (offset < 0) offset = 0;
      final data = await _client
          .from(AppConstants.tableName)
          .select(_studentListColumns)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List<dynamic>).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل في جلب صفحة الطلاب: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('لم يتم العثور على الطالب أو فشل في الجلب: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في التحقق من الرقم القومي: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في التحقق من الاسم: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في انشاء الطالب: ${AppErrorHandler.extractMessage(e)}');
    } catch (e) {
      throw Exception('فشل في انشاء الطالب: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في تحديث الطالب: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await _client.from(AppConstants.tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل في حذف الطالب: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> toggleFollowUpStatus(int id, int status) async {
    try {
      await _client
          .from(AppConstants.tableName)
          .update({'follow_up_status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw Exception('فشل في تحديث حالة المتابعة: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> deleteStudentsBatch(List<int> ids) async {
    try {
      await _client.from(AppConstants.tableName).delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في الحذف الجماعي: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> updateStudentsBatch(List<int> ids, Map<String, dynamic> updates) async {
    try {
      await _client.from(AppConstants.tableName).update(updates).inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في التحديث الجماعي: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<int> getStudentsCountByLevel(String levelTitle) async {
    try {
      final response = await _client
          .from(AppConstants.tableName)
          .select('id')
          .eq('level', levelTitle)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('فشل في التحقق من عدد الطلاب: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<Map<String, int>> getStudentsCountPerLevel() async {
    try {
      final response = await _client
          .from(AppConstants.tableName)
          .select('level');
      final counts = <String, int>{};
      for (final row in response) {
        final level = row['level'] as String?;
        if (level != null) {
          counts[level] = (counts[level] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      throw Exception('فشل في جلب عدد الطلاب لكل مستوى: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في التحقق من اسم المستوى: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في جلب المستويات: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في اضافة المستوى: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في تحديث المستوى: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> deleteLevel(int id) async {
    try {
      await _client.from('competition_levels').delete().eq('id', id);
    } catch (e) {
      throw Exception('فشل في حذف المستوى: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> deleteLevelsBatch(List<int> ids) async {
    try {
      await _client.from('competition_levels').delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في الحذف الجماعي للمستويات: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> updateLevelsBatch(List<int> ids, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      await _client.from('competition_levels').update(updates).inFilter('id', ids);
    } catch (e) {
      throw Exception('فشل في التحديث الجماعي للمستويات: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  // --- App Settings ---

  Future<Map<String, dynamic>?> getSettings() async {
    try {
      return await _client
          .from('app_settings')
          .select()
          .limit(1)
          .maybeSingle();
    } catch (e) {
      throw Exception('فشل في جلب الإعدادات: ${AppErrorHandler.extractMessage(e)}');
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
      throw Exception('فشل في حفظ الإعدادات: ${AppErrorHandler.extractMessage(e)}');
    }
  }


  // --- Ceremony ---

  Future<void> generateCeremonyCodes() async {
    try {
      await _client.rpc('generate_all_ceremony_codes');
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('فشل في توليد أكواد الحفل');
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
      throw Exception('فشل في الاستعلام: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  // --- Slot Availability ---

  /// Returns the availability of every exam slot (date + hour) defined in the
  /// exam schedule.  Each row contains: exam_date, exam_hour, start_hour,
  /// end_hour, students_per_hour, current_count, is_available.
  /// Pass [excludeStudentId] when editing a student so their own slot
  /// doesn't count against availability.
  Future<List<Map<String, dynamic>>> getSlotAvailability({int? excludeStudentId}) async {
    try {
      final data = await _client.rpc('get_slot_availability', params: {
        if (excludeStudentId != null) 'p_exclude_student_id': excludeStudentId,
      });
      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('فشل في جلب المواعيد المتاحة: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  // --- Admin Management ---

  Future<List<Admin>> getAdmins() async {
    try {
      final data = await _client.rpc('list_admins');
      return (data as List<dynamic>).map((json) => Admin.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل في جلب قائمة المسؤولين: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<Admin?> getCurrentAdmin() async {
    try {
      final data = await _client.rpc('get_current_admin');
      if (data != null && (data as List).isNotEmpty) {
        return Admin.fromJson(data.first);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات المسؤول الحالي: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  // --- Auth Admin API helpers ---
  Map<String, String> get _adminAuthHeaders => {
    'Authorization': 'Bearer ${AppConstants.supabaseServiceRoleKey}',
    'apikey': AppConstants.supabaseServiceRoleKey,
    'Content-Type': 'application/json',
  };

  String get _authAdminBaseUrl => '${AppConstants.supabaseUrl}/auth/v1/admin';

  Future<Map<String, dynamic>> _authAdminPost(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_authAdminBaseUrl/$path');
    final res = await http.post(uri, headers: _adminAuthHeaders, body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Auth API error (${res.statusCode}): ${res.body}');
  }

  Future<void> _authAdminPut(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_authAdminBaseUrl/$path');
    final res = await http.put(uri, headers: _adminAuthHeaders, body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Auth API error (${res.statusCode}): ${res.body}');
  }

  Future<void> _authAdminDelete(String path) async {
    final uri = Uri.parse('$_authAdminBaseUrl/$path');
    final res = await http.delete(uri, headers: _adminAuthHeaders);
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Auth API error (${res.statusCode}): ${res.body}');
  }

  Future<void> deleteAdmin(String adminId) async {
    try {
      // Delete auth user via Admin API
      await _authAdminDelete('users/$adminId');
      // Clean up admins record
      try {
        await _client.from('admins').delete().eq('id', adminId);
      } catch (_) {}
    } catch (e) {
      throw Exception('فشل في حذف المسؤول: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> updateAdminRole(String adminId, String role) async {
    try {
      await _client.rpc('update_admin_role', params: {
        'p_admin_id': adminId,
        'p_role': role,
      });
    } catch (e) {
      throw Exception('فشل في تحديث صلاحية المسؤول: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<Admin> createAdmin({
    required String name,
    required String phone,
    required String password,
    String role = 'admin',
  }) async {
    try {
      final email = '$phone@admin.com';
      // Create auth user via Admin API
      final authUser = await _authAdminPost('users', {
        'email': email,
        'password': password,
        'email_confirm': true,
        'user_metadata': {'name': name, 'phone': phone},
      });
      final userId = authUser['id'] as String;
      // Insert into admins table
      await _client.from('admins').insert({
        'id': userId,
        'name': name,
        'phone': phone,
        'role': role,
      });
      return Admin(id: userId, name: name, phone: phone, role: role);
    } catch (e) {
      throw Exception('فشل في إنشاء المسؤول: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<int> forceLogoutAllAdmins() async {
    try {
      final version = await _client.rpc('force_logout_all_admins') as int;
      return version;
    } catch (e) {
      throw Exception('فشل في تسجيل خروج المسؤولين: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<int> getAuthVersion() async {
    try {
      return await _client.rpc('get_auth_version') as int? ?? 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> updateAdminPassword(String adminId, String newPassword) async {
    try {
      await _authAdminPut('users/$adminId', {'password': newPassword});
    } catch (e) {
      throw Exception('فشل في تغيير كلمة المرور: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> changeMyPassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('فشل في تغيير كلمة المرور: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> updateAdminInfo(String adminId, String name, String phone) async {
    try {
      await _client.rpc('update_admin_info', params: {
        'p_admin_id': adminId,
        'p_name': name,
        'p_phone': phone,
      });
    } catch (e) {
      throw Exception('فشل في تحديث بيانات المسؤول: ${AppErrorHandler.extractMessage(e)}');
    }
  }

  Future<void> updateMyInfo(String name, String phone) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('يجب تسجيل الدخول أولاً');
      await _client.from('admins').update({
        'name': name,
        'phone': phone,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('فشل في تحديث بياناتك: ${AppErrorHandler.extractMessage(e)}');
    }
  }
}

