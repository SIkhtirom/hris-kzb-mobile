import 'dart:async';

class RequestGuard {
  RequestGuard._();

  static const Duration timeout = Duration(seconds: 10);

  static Future<T> withTimeout<T>(Future<T> future) {
    return future.timeout(timeout);
  }
}
