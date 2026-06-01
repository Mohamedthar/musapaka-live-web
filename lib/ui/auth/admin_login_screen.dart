import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../shared/widgets/hero_branding.dart';
import '../dashboard/dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _primary = Color(0xFF03121C);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      await _authRepo.signInWithPhone(phone, password);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('Invalid login credentials')
            ? 'رقم الهاتف أو كلمة المرور غير صحيحة'
            : e.message.contains('Email not confirmed')
                ? 'الحساب غير مؤكد. عطّل "Confirm email" في إعدادات Supabase Auth.'
                : 'خطأ: ${e.message}';
      });
    } catch (e) {
      AppLogger.error('Login failed', tag: 'auth', error: e);
      setState(() => _errorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // جانب الاستمارة
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
                        // لوجو حقيقي
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
                          'تسجيل الدخول',
                          style: TextStyle(fontFamily: 'Cairo', 
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أدخل بياناتك للوصول إلى لوحة التحكم',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 40),

                        // رسالة الخطأ
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

                        // رقم الهاتف
                        const Text('رقم الهاتف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: _primary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '01xxxxxxxxx',
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.phone_android_outlined, size: 20),
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
                          validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 24),

                        // كلمة المرور
                        const Text('كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 14, color: _primary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
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
                          validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 36),

                        // زر الدخول
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : const Text(
                                    'دخول',
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

          // الجانب الجمالي
          if (isWide) const HeroBranding(),
        ],
      ),
    );
  }
}
