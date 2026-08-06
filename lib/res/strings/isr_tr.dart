import 'package:easy_localization/easy_localization.dart';
import 'package:ism_video_reel_player/res/strings/isr_tr_fallback.dart';

/// Resolves an SDK UI string from the host [EasyLocalization] catalog.
///
/// Host apps should keep the matching keys in their own translation JSON
/// (e.g. `assets/translations/{locale}.json`). When EasyLocalization is
/// unavailable or a key is missing, [kIsrTrFallback] English is used.
String isrTr(
  String key, {
  List<String>? args,
  Map<String, String>? namedArgs,
}) {
  final fallback = kIsrTrFallback[key] ?? key;
  try {
    final translated = tr(key, args: args, namedArgs: namedArgs);
    if (translated.isEmpty || translated == key) {
      return _applyArgs(fallback, args: args, namedArgs: namedArgs);
    }
    return translated;
  } catch (_) {
    return _applyArgs(fallback, args: args, namedArgs: namedArgs);
  }
}

String _applyArgs(
  String value, {
  List<String>? args,
  Map<String, String>? namedArgs,
}) {
  var result = value;
  if (namedArgs != null) {
    namedArgs.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
  }
  if (args != null) {
    for (final arg in args) {
      result = result.replaceFirst('{}', arg);
    }
  }
  return result;
}
