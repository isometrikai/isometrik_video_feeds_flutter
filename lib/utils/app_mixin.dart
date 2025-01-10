import 'dart:developer';

mixin AppMixin {
  void printLog<T>(
    T classname,
    String message, {
    StackTrace? stackTrace,
  }) {
    if (stackTrace != null) {
      log('$T: $message\nStack Trace = $stackTrace');
    } else {
      log('$T: $message');
    }
  }
}
