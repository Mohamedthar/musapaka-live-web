import 'dart:async';
import '../../core/error/error_handler.dart';

class RetryPolicy {
  final int maxAttempts;
  final Duration baseDelay;
  final bool Function(dynamic error)? shouldRetry;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.shouldRetry,
  });

  Future<T> execute<T>(Future<T> Function() operation, {String? context}) async {
    dynamic lastError;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;

        if (attempt == maxAttempts - 1) break;

        final msg = AppErrorHandler.classify(error, context: context);
        if (!msg.canRetry && shouldRetry?.call(error) != true) {
          break;
        }

        final delay = baseDelay * (attempt + 1);
        await Future.delayed(delay);
      }
    }

    throw lastError;
  }

  static const standard = RetryPolicy();
}
