import 'package:url_launcher/url_launcher.dart';

const _defaultMessage = 'السلام عليكم ورحمة الله وبركاته\n'
    'حضرتك سجلت في مسابقة اهل القران الكبري بالديدامون\n'
    'كنت عاوز اسالك حضرتك لو فيه مشكلة واجهتك في التقديم ؟\n'
    'واسال حضرتك هل نزلت الاستمارة علي الهاتف ام حصل مشكلة في تنزيلها؟';

Future<void> openWhatsApp(String phone, {String? message}) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return;

  var formatted = digits;
  if (digits.startsWith('0')) {
    formatted = '20${digits.substring(1)}';
  } else if (digits.length == 11 && digits.startsWith('20')) {
    formatted = digits;
  } else if (digits.length == 10 && !digits.startsWith('20')) {
    formatted = '2$digits';
  }

  final msg = message ?? _defaultMessage;
  final uri = Uri.https('wa.me', '/$formatted', {'text': msg});

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }
}
