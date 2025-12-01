import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  Size get size => MediaQuery.of(this).size;

  double get height => size.height;

  double get width => size.width;
}

extension emptyExtension on String? {
  bool get isEmptyOrNull {
    final finalString = this?.trim();
    return finalString == null ||
        finalString == ' ' ||
        finalString.isEmpty == true;
  }
}

extension emptyListExtension on List<dynamic>? {
  bool get isEmptyOrNull => this == null || this?.isEmpty == true;
}

extension zeroOrNullExtension on double? {
  bool get isZeroOrNull => this == null || this == 0;
}

extension StringExtension on String {
  String capitalize() => length > 1
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : toUpperCase();
}

extension removeEmptyElementExtension on Map<String, dynamic> {
  Map<String, dynamic> removeEmptyValues() {
    removeWhere((key, value) => value is List
        ? value.isEmpty
        : (value == null || (value is String && value.isEmptyOrNull)));
    return this;
  }
}

extension ColorExt on Color {
  Color applyOpacity(double opacity) => withValues(alpha: opacity);
}

extension MediaTypeExtension on MediaType {
  int get mediaType => switch (this) {
        MediaType.photo => 0,
        MediaType.video => 1,
        MediaType.both => 2,
      };
}

extension ColorExtension on String {
  Color get toHexColor => Color(int.parse('0xFF$this'));
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

extension PercentageWidthExtension on num {
  double get percentWidth => (this / 100).toDouble().sw;
}

extension PercentageHeightExtension on num {
  double get percentHeight => (this / 100).toDouble().sh;
}

extension DimensionExtension on num {
  double get scaledValue => sp;
}

extension HeightExtension on num {
  SizedBox get verticalSpace => this == 0
      ? const SizedBox.shrink()
      : SizedBox(height: toDouble().scaledValue);
}

extension WidthExtension on num {
  SizedBox get horizontalSpace => SizedBox(width: toDouble().scaledValue);
}
