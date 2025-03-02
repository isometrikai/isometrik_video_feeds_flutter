import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

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

  bool isSameMonth(DateTime other) => year == other.year && month == other.month;

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
  bool get isEmptyOrNull {
    final finalString = this?.trim();
    return finalString == null || finalString == ' ' || finalString.isEmpty == true;
  }
}

extension EmptyListExtension on List<dynamic>? {
  bool get isEmptyOrNull => this == null || this?.isEmpty == true;
}

extension ZeroOrNullExtension on double? {
  bool get isZeroOrNull => this == null || this == 0;
}

extension StringExtension on String {
  String capitalize() => length > 1 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : toUpperCase();
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
    removeWhere(
        (key, value) => value is List ? value.isEmpty : (value == null || (value is String && value.isEmptyOrNull)));
    return this;
  }
}

extension ColorExt on Color {
  Color applyOpacity(double opacity) => withValues(alpha: opacity);
}
