import '../config/env_config.dart';

class AppConstants {
  static String get supabaseUrl =>
      EnvConfig.get('SUPABASE_URL');
  static String get supabaseAnonKey =>
      EnvConfig.get('SUPABASE_ANON_KEY');
  static String get cloudinaryCloudName =>
      EnvConfig.get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryUploadPreset =>
      EnvConfig.get('CLOUDINARY_UPLOAD_PRESET');

  static const String tableName = 'students';
}
