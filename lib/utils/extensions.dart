import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_compress/video_compress.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  Size get size => MediaQuery.of(this).size;

  double get height => size.height;

  double get width => size.width;
}

extension MaterialStateExtension on Set<WidgetState> {
  bool get isDisabled => any((e) => [WidgetState.disabled].contains(e));
}

extension DateExtension on DateTime {
  String get formatDate => DateFormat('dd MMM yyyy').format(this);

  String get formatTime => DateFormat.jm().format(this);

  bool isSameDay(DateTime other) => isSameMonth(other) && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  String messageDate() {
    var now = DateTime.now();
    if (now.isSameDay(this)) {
      return 'Today';
    }
    if (now.isSameMonth(this)) {
      if (now.day - day == 1) {
        return 'Yesterday';
      }
      if (now.difference(this) < const Duration(days: 8)) {
        return weekday.weekDayString;
      }
      return formatDate;
    }
    return formatDate;
  }
}

extension IntExtension on int {
  String get weekDayString {
    if (this > 7 || this < 1) {
      throw IsrAppException('Value should be between 1 & 7');
    }
    var weekDays = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return weekDays[this]!;
  }
}

extension EmptyExtension on String? {
  bool get isStringEmptyOrNull {
    final finalString = this?.trim();
    return finalString == null ||
        finalString == ' ' ||
        finalString == 'null' ||
        finalString.isEmpty == true;
  }
}

extension EmptyListExtension on List<dynamic>? {
  bool get isListEmptyOrNull => this == null || this?.isEmpty == true;
  bool get isEmptyOrNull => this == null || this?.isEmpty == true;
}

extension ZeroOrNullExtension on double? {
  bool get isZeroOrNull => this == null || this == 0;
}

extension StringExtension on String {
  String capitalize() => length > 1
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : toUpperCase();
}

extension DurationExtension on Duration {
  String get formatTime {
    final h = inHours.toString().padLeft(2, '0');
    final m = (inMinutes % 60).toString().padLeft(2, '0');
    final s = (inSeconds % 60).toString().padLeft(2, '0');
    return [if (h != '00') h, m, s].join(':');
  }

  String get formatDuration {
    var h = inHours.toString().padLeft(2, '0');
    var m = (inMinutes % 60).toString().padLeft(2, '0');
    var s = (inSeconds % 60).toString().padLeft(2, '0');
    if (h != '00') {
      h = '$h Hours';
    }
    if (m != '00') {
      m = '$m Mins';
    }
    if (s != '00') {
      s = '$s Secs';
    }
    return [h, m, s].where((e) => e != '00').join(' ');
  }
}

extension RemoveEmptyElementExtension on Map<String, dynamic> {
  Map<String, dynamic> removeEmptyValues() {
    removeWhere((key, value) => value is List
        ? value.isEmpty
        : (value == null || (value is String && value.isStringEmptyOrNull)));
    return this;
  }
}

extension ColorExt on Color {
  Color changeOpacity(double opacity) => withValues(alpha: opacity);
  Color applyOpacity(double opacity) => withValues(alpha: opacity);
}

extension PercentageWidthExtension on num {
  double get percentWidth => (this / 100).toDouble().sw;
}

extension PercentageHeightExtension on num {
  double get percentHeight => (this / 100).toDouble().sh;
}

extension DimensionExtension on num {
  double get responsiveDimension => sp;
}

extension HeightExtension on num {
  SizedBox get responsiveVerticalSpace => this == 0
      ? const SizedBox.shrink()
      : SizedBox(height: toDouble().responsiveDimension);
}

extension WidthExtension on num {
  SizedBox get responsiveHorizontalSpace =>
      SizedBox(width: toDouble().responsiveDimension);
}

extension MediaPathCheck on String {
  bool get isVideoFile {
    final ext = toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm');
  }

  bool get isImageFile {
    final ext = toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }
}

extension emptyExtension on String? {
  bool get isEmptyOrNull {
    final finalString = this?.trim();
    return finalString == null || finalString == ' ' || finalString.isEmpty == true;
  }
}

extension MediaQualityCheck on String {
  /// Checks if file meets the minimum width & height requirement.
  Future<bool> hasMinResolution({int minWidth = 240, int minHeight = 240}) async {
    final info = await VideoCompress.getMediaInfo(this);
    final width = info.width ?? 0;
    final height = info.height ?? 0;
    return width >= minWidth && height >= minHeight;
  }
}

extension MediaTypeValue on MediaType {
  int get value => switch (this) {
        MediaType.photo => 0,
        MediaType.video => 1,
        MediaType.both => 2,
        MediaType.unknown => 0,
      };
}

extension MediaTypeStringExtension on MediaType {
  String get mediaTypeString => switch (this) {
    MediaType.photo => 'image',
    MediaType.video => 'video',
    MediaType.both => 'carousel',
    MediaType.unknown => 'unknown',
  };
}

extension ColorExtension on String {
  Color get color => Color(int.parse('0xFF${replaceFirst('#', '')}'));
}

extension MediaTypeExtensionOnString on String {
  MediaType get mediaType => switch (this) {
        'photo' || 'image' => MediaType.photo,
        'video' => MediaType.video,
        String() => MediaType.both,
      };
}

extension PlatformExtension on num {
  String get platformText => switch (this) {
        1 => 'android',
        2 => 'ios',
        int() => 'android',
        double() => 'android',
      };
}

extension HexColor on String {
  Color toColor() {
    final hexString = replaceFirst('#', '');
    return Color(int.parse(hexString, radix: 16) | 0xFF000000);
  }
}

extension StringCasingExtension on String {
  String capitalizeEachWord() {
    if (trim().isEmpty) return this;
    return split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String? takeIfNotEmpty() => trim().isNotEmpty ? this : null;
}

extension MediaQueryExtensions on BuildContext {
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get totalBottomNavSpace =>
      kBottomNavigationBarHeight + MediaQuery.of(this).padding.bottom;
}

extension ScopeFunctions<T> on T {
  /// Calls the given function [op] with `this` value and returns the result.
  /// Like Kotlin's `let`.
  R let<R>(R Function(T it) op) => op(this);

  /// Calls the given function [op] with `this` value and returns `this`.
  /// Like Kotlin's `also`.
  T also(void Function(T it) op) {
    op(this);
    return this;
  }

  /// Calls the given function [block] and returns the result.
  /// Like Kotlin's `run`.
  R run<R>(R Function(T it) block) => block(this);

  /// Returns `this` if it satisfies the [predicate], otherwise `null`.
  /// Like Kotlin's `takeIf`.
  T? takeIf(bool Function(T it) predicate) => predicate(this) ? this : null;

  /// Returns `this` if it does NOT satisfy the [predicate], otherwise `null`.
  /// Like Kotlin's `takeUnless`.
  T? takeUnless(bool Function(T it) predicate) =>
      !predicate(this) ? this : null;
}

extension MapSafeGetters on Map<String, dynamic> {
  // ----------------- OrNull versions (core logic) -----------------

  num? _numOrNull(String key) {
    final value = this[key];
    return value is num
        ? value
        : (value is String ? num.tryParse(value) : null);
  }

  int? _intOrNull(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }

  double? _doubleOrNull(String key) {
    final value = this[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool? _boolOrNull(String key) {
    final value = this[key];
    if (value is bool) return value;

    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }

    if (value is num) return value != 0;

    return null;
  }

  String? _stringOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    return value.toString();
  }

  List<T>? _listOrNull<T>(String key) {
    final value = this[key];
    if (value is List) return value.whereType<T>().toList();
    return null;
  }

  Map<String, dynamic>? _mapOrNull(String key) {
    final value = this[key];
    return value is Map<String, dynamic> ? value : null;
  }

  /// Generic safe object parser.
  /// [factory] should accept a Map<String,dynamic> and return T.
  T? objectOrNull<T>(String key, T Function(Map<String, dynamic>) factory) {
    final value = this[key];

    if (value == null) return null;

    // Already of type T
    if (value is T) return value;

    // Map → T
    if (value is Map<String, dynamic>) {
      return factory(value);
    }

    // String (JSON) → T
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return factory(decoded);
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Generic safe object parser with default value
  T getObject<T>(
    String key,
    T Function(Map<String, dynamic>) factory, {
    required T defaultValue,
  }) =>
      objectOrNull<T>(key, factory) ?? defaultValue;

  // ----------------- Public OrNull versions -----------------

  num? numOrNull(String key) => _numOrNull(key);

  int? intOrNull(String key) => _intOrNull(key);

  double? doubleOrNull(String key) => _doubleOrNull(key);

  bool? boolOrNull(String key) => _boolOrNull(key);

  String? stringOrNull(String key) => _stringOrNull(key);

  List<T>? listOrNull<T>(String key) => _listOrNull<T>(key);

  Map<String, dynamic>? mapOrNull(String key) => _mapOrNull(key);

  // ----------------- Public versions with defaults -----------------

  num getNum(String key, [num defaultValue = 0]) =>
      _numOrNull(key) ?? defaultValue;

  int getInt(String key, [int defaultValue = 0]) =>
      _intOrNull(key) ?? defaultValue;

  double getDouble(String key, [double defaultValue = 0.0]) =>
      _doubleOrNull(key) ?? defaultValue;

  bool getBool(String key, [bool defaultValue = false]) =>
      _boolOrNull(key) ?? defaultValue;

  String getString(String key, [String defaultValue = '']) =>
      _stringOrNull(key) ?? defaultValue;

  List<T> getList<T>(String key, [List<T> defaultValue = const []]) =>
      _listOrNull<T>(key) ?? defaultValue;

  Map<String, dynamic> getMap(String key,
          [Map<String, dynamic> defaultValue = const {}]) =>
      _mapOrNull(key) ?? defaultValue;
}
