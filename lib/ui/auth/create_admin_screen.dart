import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/utils/app_logger.dart';
import '../shared/widgets/hero_branding.dart';
import '../dashboard/dashboard_screen.dart';
import '../../core/utils/validators.dart';
import 'admin_login_screen.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _isChecking = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _primary = Color(0xFF03121C);

  @override
  void initState() {
    super.initState();
    _checkExistingAdmins();
  }

  Future<void> _checkExistingAdmins() async {
    try {
      final hasAdmins = await _authRepo.hasAdmins();
      if (!mounted) return;
      if (hasAdmins) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      } else {
        setState(() => _isChecking = false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check existing admins', error: e, stack: stackTrace);
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      await _authRepo.signUp(phone, password, name);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message.contains('Email not confirmed')
          ? 'البريد الإلكتروني غير مؤكد. عطّل "Confirm email" في إعدادات Supabase Auth.'
          : 'خطأ: ${e.message}');
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during admin creation', error: e, stack: stackTrace);
      setState(() => _errorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool hasToggle = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: _primary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: hasToggle
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
          ),
          validator: validator ?? ((v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: isWide ? 60 : 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logo_musapaka.jpeg',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'إعداد النظام',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 30, fontWeight: FontWeight.w800, color: _primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أنشئ حساب المسؤول الأول لبدء إدارة المسابقة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 40),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFFD32F2F), fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        _buildField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          hint: 'أدخل اسمك كاملاً',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          hint: '01xxxxxxxxx',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validator.validatePhone,
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                          hasToggle: true,
                          validator: Validator.validatePassword,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يجب أن تحتوي على 8 أحرف على الأقل، حرف كبير، حرف صغير، رقم، ورمز خاص',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleCreateAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Text(
                                    'إنشاء الحساب',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isWide) const HeroBranding(),
        ],
      ),
    );
  }
}
