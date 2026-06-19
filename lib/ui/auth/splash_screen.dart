import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/error_handler.dart';
import '../../core/utils/app_logger.dart';
import 'admin_login_screen.dart';
import 'create_admin_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminStatus());
  }

  Future<void> _checkAdminStatus() async {
    // Start the check immediately, with a minimum 1s for splash animation
    final checkFuture = _performCheck();
    await Future.any([checkFuture, Future.delayed(const Duration(seconds: 1))]);
    await checkFuture;
  }

  Future<void> _performCheck() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if user is already logged in
      final session = supabase.auth.currentSession;
      if (session != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        return;
      }

      // Check if any admin exists using SECURITY DEFINER RPC (bypasses RLS)
      final hasAdmins = await supabase.rpc('has_admins');

      if (!mounted) return;

      if (hasAdmins == false || hasAdmins == null) {
        // No admin found, navigate to Create Admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateAdminScreen()),
        );
      } else {
        // Admin exists, navigate to Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    } catch (e) {
      AppLogger.error('فشل التحقق من حالة الأدمن', tag: 'splash', error: e);
      if (!mounted) return;

      final classified = AppErrorHandler.classify(e, context: 'splash_init');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classified.userMessage,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.right,
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          width: 380,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_musapaka.jpeg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'منصة مسابقة القرآن',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لوحة تحكم الإدارة',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
