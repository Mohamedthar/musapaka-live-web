import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/env_config.dart';
import 'core/utils/app_logger.dart';
import 'core/error/connectivity_service.dart';
import 'services/backup_service.dart';
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await AppLogger.init();

  final supabaseUrl = AppConstants.supabaseUrl;
  final supabaseAnonKey = AppConstants.supabaseAnonKey;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('مفاتيح Supabase غير موجودة في ملف البيئة. تأكد من إعداد SUPABASE_URL و SUPABASE_ANON_KEY');
  }

  if (!supabaseUrl.startsWith('https://')) {
    throw Exception('يجب استخدام HTTPS في SUPABASE_URL لتأمين الاتصال');
  }

  AppLogger.info('بدء تشغيل التطبيق', tag: 'init');
  ConnectivityService().start();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  BackupService().autoBackupIfNeeded();

  runApp(const QuranContestApp());
}

class QuranContestApp extends StatelessWidget {
  const QuranContestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسابقة القرآن',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.pageUp): const DoNothingAndStopPropagationIntent(),
              LogicalKeySet(LogicalKeyboardKey.pageDown): const DoNothingAndStopPropagationIntent(),
            },
            child: child!,
          ),
        );
      },
    );
  }
}
