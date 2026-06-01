import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMessage {
  final String userMessage;
  final String? technicalDetail;
  final bool canRetry;

  const ErrorMessage({
    required this.userMessage,
    this.technicalDetail,
    this.canRetry = false,
  });
}

class AppErrorHandler {
  static ErrorMessage classify(dynamic error, {String? context}) {
    final errStr = error.toString();

    if (_isNetworkError(error, errStr)) {
      return ErrorMessage(
        userMessage: 'لا يوجد اتصال بالإنترنت\nتأكد من اتصالك وحاول مرة أخرى',
        technicalDetail: errStr,
        canRetry: true,
      );
    }

    if (_isTimeoutError(error, errStr)) {
      return ErrorMessage(
        userMessage: 'انتهت مهلة الاتصال بالخادم\nالإنترنت بطيء جداً، حاول مرة أخرى',
        technicalDetail: errStr,
        canRetry: true,
      );
    }

    if (_isServerError(error, errStr)) {
      return ErrorMessage(
        userMessage: 'الخادم غير متاح حالياً\nيرجى المحاولة بعد قليل',
        technicalDetail: errStr,
        canRetry: true,
      );
    }

    if (_isAuthError(error, errStr)) {
      return ErrorMessage(
        userMessage: 'انتهت صلاحية الجلسة\nيرجى تسجيل الدخول مرة أخرى',
        technicalDetail: errStr,
      );
    }

    if (_isDatabaseError(error, errStr)) {
      return _classifyDbError(errStr);
    }

    if (_isFileSystemError(error, errStr)) {
      return ErrorMessage(
        userMessage: 'تعذر الوصول إلى الملفات\nتأكد من صلاحيات التطبيق',
        technicalDetail: errStr,
      );
    }

    return ErrorMessage(
      userMessage: 'حدث خطأ غير متوقع\n${_truncate(context ?? errStr, 100)}',
      technicalDetail: errStr,
    );
  }

  static bool _isNetworkError(dynamic error, String str) {
    if (error is SocketException) return true;
    if (error is http.ClientException) return true;
    if (str.contains('SocketException')) return true;
    if (str.contains('HttpException')) return true;
    if (str.contains('Connection refused')) return true;
    if (str.contains('Network is unreachable')) return true;
    if (str.contains('No address associated')) return true;
    if (str.contains('Failed host lookup')) return true;
    return false;
  }

  static bool _isTimeoutError(dynamic error, String str) {
    if (error is TimeoutException) return true;
    if (str.contains('TimeoutException')) return true;
    if (str.contains('timed out')) return true;
    if (str.contains('timeout')) return true;
    return false;
  }

  static bool _isServerError(dynamic error, String str) {
    if (error is http.ClientException) return false;
    if (str.contains('500')) return true;
    if (str.contains('502')) return true;
    if (str.contains('503')) return true;
    if (str.contains('504')) return true;
    if (str.contains('Internal Server Error')) return true;
    return false;
  }

  static bool _isAuthError(dynamic error, String str) {
    if (error is AuthException) return true;
    if (str.contains('AuthException')) return true;
    if (str.contains('JWT')) return true;
    if (str.contains('token')) return true;
    if (str.contains('session')) return true;
    if (str.contains('unauthorized')) return true;
    if (str.contains('401')) return true;
    return false;
  }

  static bool _isDatabaseError(dynamic error, String str) {
    if (error is PostgrestException) return true;
    if (str.contains('PostgrestException')) return true;
    if (str.contains('database')) return true;
    if (str.contains('23505')) return true;
    return false;
  }

  static bool _isFileSystemError(dynamic error, String str) {
    if (error is FileSystemException) return true;
    if (str.contains('FileSystemException')) return true;
    if (str.contains('Permission denied')) return true;
    if (str.contains('No such file')) return true;
    return false;
  }

  static ErrorMessage _classifyDbError(String str) {
    if (str.contains('23505')) {
      if (str.contains('name')) {
        return const ErrorMessage(userMessage: 'هذا الاسم مسجل مسبقاً في النظام');
      }
      if (str.contains('phone')) {
        return const ErrorMessage(userMessage: 'رقم الهاتف هذا مسجل مسبقاً');
      }
      if (str.contains('national_id')) {
        return const ErrorMessage(userMessage: 'الرقم القومي مسجل مسبقاً');
      }
      return const ErrorMessage(userMessage: 'هذه البيانات موجودة مسبقاً في النظام');
    }
    return ErrorMessage(
      userMessage: 'خطأ في قاعدة البيانات\nيرجى المحاولة مرة أخرى',
      technicalDetail: str,
      canRetry: true,
    );
  }

  static String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}
