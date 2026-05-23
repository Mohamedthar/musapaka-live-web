import 'package:flutter/material.dart';
import '../ui/auth/splash_screen.dart';
import '../ui/auth/admin_login_screen.dart';
import '../ui/auth/create_admin_screen.dart';
import '../ui/dashboard/dashboard_screen.dart';
import '../ui/registration/registration_screen.dart';
import '../ui/dashboard/widgets/student_details_screen.dart';
import '../data/models/student.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String createAdmin = '/create-admin';
  static const String dashboard = '/dashboard';
  static const String registration = '/registration';
  static const String studentDetails = '/student-details';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case createAdmin:
        return MaterialPageRoute(builder: (_) => const CreateAdminScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case registration:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());
      case studentDetails:
        final student = settings.arguments as Student;
        return MaterialPageRoute(
          builder: (_) => StudentDetailsScreen(student: student),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }

  static void goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void goToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, dashboard);
  }

  static void goToCreateAdmin(BuildContext context) {
    Navigator.pushReplacementNamed(context, createAdmin);
  }

  static void goToSplash(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (r) => false,
    );
  }
}
