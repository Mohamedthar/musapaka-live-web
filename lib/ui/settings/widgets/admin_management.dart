import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/admin.dart';
import '../../../services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class AdminManagementWidget extends StatefulWidget {
  final Color primaryColor;
  final Admin currentAdmin;

  const AdminManagementWidget({
    super.key,
    required this.primaryColor,
    required this.currentAdmin,
  });

  @override
  State<AdminManagementWidget> createState() => _AdminManagementWidgetState();
}

class _AdminManagementWidgetState extends State<AdminManagementWidget> {
  final SupabaseService _service = SupabaseService();
  List<Admin> _admins = [];
  bool _loading = true;
  String? _error;

  Color get _primary => widget.primaryColor;
  static const _textDark = Color(0xFF18181B);
  static const _textMuted = Color(0xFF71717A);
  static const _borderColor = Color(0xFFE4E4E7);
  static const _bgLight = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final admins = await _service.getAdmins();
      if (mounted) setState(() { _admins = admins; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'فشل تحميل قائمة المسؤولين'; _loading = false; });
    }
  }

  // ══════════════════════════════════════════════════════════
  // Force logout banner
  // ══════════════════════════════════════════════════════════
  Widget _buildForceLogoutBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFC2410C), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تسجيل خروج جميع المسؤولين',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: Color(0xFF431407),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سيتم تسجيل خروج جميع المسؤولين من جميع الأجهزة فوراً',
                  style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 11.5,
                    color: const Color(0xFF431407).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _forceLogoutAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC2410C),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
            ),
            child: const Text('تسجيل خروج الجميع',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _forceLogoutAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 26),
            SizedBox(width: 10),
            Expanded(child: Text('تأكيد تسجيل خروج الجميع',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
        content: const Text(
          'سيتم تسجيل خروج جميع المسؤولين فوراً من جميع الأجهزة.\n\n'
          '• كل مسؤول سيحتاج لإدخال رقم الهاتف وكلمة المرور مرة أخرى.\n'
          '• أنت أيضاً سيتم تسجيل خروجك.\n\n'
          'هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('نعم، سجل خروج الجميع',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.forceLogoutAllAdmins();
      if (mounted) {
        AppTheme.showSnack(context, 'تم تسجيل خروج جميع المسؤولين بنجاح');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Delete admin
  // ══════════════════════════════════════════════════════════
  Future<void> _deleteAdmin(Admin admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف المسؤول "${admin.name}"؟\n\nلن يتمكن من الدخول للتطبيق بعد الحذف.',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteAdmin(admin.id);
      if (mounted) {
        AppTheme.showSnack(context, 'تم حذف المسؤول "${admin.name}" بنجاح');
        await _load();
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Edit admin info dialog
  // ══════════════════════════════════════════════════════════
  Future<void> _showEditAdminDialog(Admin admin) async {
    final nameCtrl = TextEditingController(text: admin.name);
    final phoneCtrl = TextEditingController(text: admin.phone);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل بيانات "${admin.name}"',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameCtrl,
                label: 'الاسم الكامل',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 14),
              _buildDialogField(
                controller: phoneCtrl,
                label: 'رقم الهاتف',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                  if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(v.trim())) {
                    return 'رقم هاتف مصري غير صحيح';
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
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _service.updateAdminInfo(admin.id, nameCtrl.text.trim(), phoneCtrl.text.trim());
      if (mounted) {
        AppTheme.showSnack(context, 'تم تحديث بيانات "${admin.name}"');
        await _load();
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Change password for another admin (super_admin only)
  // ══════════════════════════════════════════════════════════
  Future<void> _showChangePasswordDialog(Admin admin) async {
    final pwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تغيير كلمة مرور "${admin.name}"',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('سيتم تعيين كلمة مرور جديدة للمسؤول.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: pwCtrl,
                  label: 'كلمة المرور الجديدة',
                  hint: '6 أحرف على الأقل',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscure,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 6) return '6 أحرف على الأقل';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await _service.updateAdminPassword(admin.id, pwCtrl.text);
      if (mounted) AppTheme.showSnack(context, 'تم تغيير كلمة مرور "${admin.name}" بنجاح');
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Change my own password
  // ══════════════════════════════════════════════════════════
  Future<void> _showChangeMyPasswordDialog() async {
    final oldPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isLoading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تغيير كلمة المرور الخاصة بك',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                  controller: oldPwCtrl,
                  label: 'كلمة المرور الحالية',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscureOld,
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'مطلوبة' : null,
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: newPwCtrl,
                  label: 'كلمة المرور الجديدة',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscureNew,
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'مطلوبة';
                    if (v.length < 6) return '6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: confirmPwCtrl,
                  label: 'تأكيد كلمة المرور الجديدة',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscureNew,
                  validator: (v) {
                    if (v != newPwCtrl.text) return 'كلمتا المرور غير متطابقتين';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isLoading = true);
                try {
                  final admin = await _service.getCurrentAdmin();
                  if (admin == null) throw Exception('تعذر التحقق من الحساب');
                  try {
                    await Supabase.instance.client.auth.signInWithPassword(
                      email: '${admin.phone}@admin.com',
                      password: oldPwCtrl.text,
                    );
                  } on AuthException {
                    throw Exception('كلمة المرور الحالية غير صحيحة');
                  }
                  await _service.changeMyPassword(newPwCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('$e', style: const TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (ctx.mounted) setDialogState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تغيير', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      AppTheme.showSnack(context, 'تم تغيير كلمة المرور بنجاح');
    }
  }

  // ══════════════════════════════════════════════════════════
  // Shared dialog field builder
  // ══════════════════════════════════════════════════════════
  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textMuted),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFA1A1AA)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  // ══════════════════════════════════════════════════════════
  // Change role dialog
  // ══════════════════════════════════════════════════════════
  Future<void> _changeRole(Admin admin) async {
    final roles = ['super_admin', 'admin', 'viewer'];
    final labels = ['مسؤول أعلى', 'مسؤول', 'مشاهد'];
    final descriptions = [
      'تحكم كامل: إدارة المسؤولين، التقييم، الإعدادات',
      'إدارة المتسابقين، التقييم، والمستويات',
      'عرض البيانات فقط بدون تعديل',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? chosen = admin.role;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('صلاحية "${admin.name}"',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(roles.length, (i) {
                final role = roles[i];
                final isSelected = chosen == role;
                return RadioListTile<String>(
                  dense: true,
                  title: Text(labels[i],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? _primary : const Color(0xFF334155),
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(descriptions[i],
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF94A3B8))),
                  value: role,
                  groupValue: chosen,
                  onChanged: (v) => setDialogState(() => chosen = v),
                  activeColor: _primary,
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, chosen),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == admin.role) return;

    try {
      await _service.updateAdminRole(admin.id, selected);
      if (mounted) {
        AppTheme.showSnack(context, 'تم تحديث صلاحية "${admin.name}"');
        await _load();
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }

  // ══════════════════════════════════════════════════════════
  // Role helpers
  // ══════════════════════════════════════════════════════════
  IconData _roleIcon(String role) {
    switch (role) {
      case 'super_admin': return Icons.shield_rounded;
      case 'admin': return Icons.admin_panel_settings_rounded;
      case 'viewer': return Icons.visibility_rounded;
      default: return Icons.person_outline_rounded;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return const Color(0xFF18181B);
      case 'admin': return const Color(0xFF2563EB);
      case 'viewer': return const Color(0xFF71717A);
      default: return Colors.grey;
    }
  }

  String _roleIconLetter(String role) {
    switch (role) {
      case 'super_admin': return 'أ';
      case 'admin': return 'م';
      case 'viewer': return 'مـ';
      default: return '؟';
    }
  }

  // ══════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 56),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline_rounded,
        message: _error!,
        action: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('إعادة المحاولة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            foregroundColor: _primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.currentAdmin.isSuperAdmin) ...[
          _buildForceLogoutBanner(),
          const SizedBox(height: 20),
        ],
        _buildHeader(),
        const SizedBox(height: 14),
        if (_admins.isEmpty)
          _buildEmptyState(
            icon: Icons.people_outline_rounded,
            message: 'لا يوجد مسؤولون',
          )
        else
          _buildAdminsList(),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFD4D4D8)),
          const SizedBox(height: 12),
          Text(message,
            style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w500,
              color: Color(0xFFA1A1AA),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.admin_panel_settings_rounded, size: 19, color: _primary),
        ),
        const SizedBox(width: 12),
        Text(
          '${_admins.length} مسؤول',
          style: const TextStyle(
            fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _showChangeMyPasswordDialog,
          icon: const Icon(Icons.lock_outline_rounded, size: 15),
          label: const Text('كلمة المرور',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w500)),
          style: TextButton.styleFrom(
            foregroundColor: _textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (widget.currentAdmin.isSuperAdmin) ...[
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => _CreateAdminDialog(primaryColor: _primary),
              );
              if (created == true) _load();
            },
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: const Text('إضافة مسؤول',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminsList() {
    return Column(
      children: List.generate(_admins.length, (i) {
        final admin = _admins[i];
        final isCurrentUser = admin.id == widget.currentAdmin.id;

        return Padding(
          padding: EdgeInsets.only(bottom: i < _admins.length - 1 ? 10 : 0),
          child: _buildAdminCard(admin, isCurrentUser: isCurrentUser),
        );
      }),
    );
  }

  Widget _buildAdminCard(
    Admin admin, {
    required bool isCurrentUser,
  }) {
    final roleColor = _roleColor(admin.role);
    // Super admin can manage regular admins & viewers, but NOT other super_admins
    final canManage = widget.currentAdmin.isSuperAdmin && !isCurrentUser && !admin.isSuperAdmin;
    final canChangePassword = canManage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFF4F4F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? _primary.withValues(alpha: 0.1) : _borderColor,
        ),
      ),
      child: Row(
        children: [
          // ── Avatar with role-colored subtle border ──
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: roleColor.withValues(alpha: 0.12), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _roleIconLetter(admin.role),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: roleColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ──
          Expanded(
            child: Row(
              children: [
                // Left: name + phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              admin.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 13.5, fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'أنت',
                                style: TextStyle(
                                  fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700,
                                  color: _primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Phone
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_android_rounded, size: 12, color: const Color(0xFFA1A1AA)),
                          const SizedBox(width: 4),
                          Text(
                            admin.phone,
                            style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 12, color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right: role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        admin.roleLabel,
                        style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Actions ──
          if (canManage)
            _buildMoreMenu(admin, canChangePassword: canChangePassword)
          else if (isCurrentUser)
            _buildMyMenu(),
        ],
      ),
    );
  }

  // ── Popup menu with colored icon containers ──
  Widget _buildMoreMenu(Admin admin, {required bool canChangePassword}) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      padding: EdgeInsets.zero,
      icon: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: _textMuted),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditAdminDialog(admin);
          case 'password':
            _showChangePasswordDialog(admin);
          case 'role':
            _changeRole(admin);
          case 'delete':
            _deleteAdmin(admin);
        }
      },
      itemBuilder: (ctx) => [
        _menuItem('edit', Icons.edit_outlined, 'تعديل البيانات', const Color(0xFF52525B)),
        if (canChangePassword)
          _menuItem('password', Icons.lock_outline_rounded, 'تغيير كلمة المرور', const Color(0xFF2563EB)),
        _menuItem('role', Icons.tune_rounded, 'تغيير الصلاحية', const Color(0xFF7C3AED)),
        const PopupMenuDivider(height: 1),
        _menuItem('delete', Icons.delete_outline_rounded, 'حذف المسؤول', const Color(0xFFDC2626)),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color iconColor) {
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(label,
            style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Self-service menu for current user ──
  Widget _buildMyMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      padding: EdgeInsets.zero,
      icon: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: _textMuted),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit_my_info':
            _showEditMyInfoDialog();
          case 'change_my_password':
            _showChangeMyPasswordDialog();
        }
      },
      itemBuilder: (ctx) => [
        _menuItem('edit_my_info', Icons.edit_outlined, 'تعديل بياناتي', const Color(0xFF52525B)),
        _menuItem('change_my_password', Icons.lock_outline_rounded, 'تغيير كلمة المرور', const Color(0xFF2563EB)),
      ],
    );
  }

  Future<void> _showEditMyInfoDialog() async {
    final admin = widget.currentAdmin;
    final nameCtrl = TextEditingController(text: admin.name);
    final phoneCtrl = TextEditingController(text: admin.phone);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل بياناتي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameCtrl,
                label: 'الاسم الكامل',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 14),
              _buildDialogField(
                controller: phoneCtrl,
                label: 'رقم الهاتف',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                  if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(v.trim())) {
                    return 'رقم هاتف مصري غير صحيح';
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
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _service.updateMyInfo(nameCtrl.text.trim(), phoneCtrl.text.trim());
      if (mounted) {
        AppTheme.showSnack(context, 'تم تحديث بياناتك بنجاح');
        await _load();
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Create Admin Dialog
// ═══════════════════════════════════════════════════════════════
class _CreateAdminDialog extends StatefulWidget {
  final Color primaryColor;
  const _CreateAdminDialog({required this.primaryColor});

  @override
  State<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<_CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'admin';
  bool _isLoading = false;
  bool _obscurePassword = true;
  final SupabaseService _service = SupabaseService();

  static const _textDark = Color(0xFF18181B);
  static const _textMuted = Color(0xFF71717A);
  static const _borderColor = Color(0xFFE4E4E7);
  static const _bgLight = Color(0xFFFAFAFA);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _service.createAdmin(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _selectedRole,
      );
      if (mounted) {
        Navigator.pop(context, true);
        AppTheme.showSnack(context, 'تم إنشاء حساب "${_nameCtrl.text.trim()}" بنجاح');
      }
    } on PostgrestException catch (e) {
      if (mounted) AppTheme.showSnack(context, 'خطأ: ${e.message}', color: Colors.red);
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, '$e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.primaryColor;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: p.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_rounded, color: p, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('إضافة مسؤول جديد',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: _textMuted),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('سيتمكن من الدخول للتطبيق فور إنشاء الحساب',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: _textMuted)),
              const SizedBox(height: 24),

              // Fields
              _field(
                label: 'الاسم الكامل',
                hint: 'أدخل الاسم كاملاً',
                icon: Icons.person_outline_rounded,
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'رقم الهاتف',
                hint: '01xxxxxxxxx',
                icon: Icons.phone_android_rounded,
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                  if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(v.trim())) {
                    return 'رقم هاتف مصري غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                label: 'كلمة المرور',
                hint: '6 أحرف على الأقل',
                icon: Icons.lock_outline_rounded,
                controller: _passwordCtrl,
                obscure: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                  if (v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Role selector
              _buildRoleSelector(),
              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: _textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAdmin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: p,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('إنشاء الحساب',
                              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الصلاحية',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleChip('admin', 'مسؤول', Icons.admin_panel_settings_rounded, const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            _roleChip('viewer', 'مشاهد', Icons.visibility_rounded, const Color(0xFF71717A)),
            const SizedBox(width: 8),
            _roleChip('super_admin', 'مسؤول أعلى', Icons.shield_rounded, const Color(0xFF18181B)),
          ],
        ),
      ],
    );
  }

  Widget _roleChip(String role, String label, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.06) : _bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.25) : _borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : const Color(0xFFA1A1AA)),
              const SizedBox(height: 5),
              Text(label,
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _textMuted),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFFA1A1AA)),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: const Color(0xFFA1A1AA)),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: _bgLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
