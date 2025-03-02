import 'package:flutter/material.dart';
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
    return finalString == null || finalString == ' ' || finalString.isEmpty == true;
  }
}

extension emptyListExtension on List<dynamic>? {
  bool get isEmptyOrNull => this == null || this?.isEmpty == true;
}

extension zeroOrNullExtension on double? {
  bool get isZeroOrNull => this == null || this == 0;
}

extension StringExtension on String {
  String capitalize() => length > 1 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : toUpperCase();
}

extension removeEmptyElementExtension on Map<String, dynamic> {
  Map<String, dynamic> removeEmptyValues() {
    removeWhere(
        (key, value) => value is List ? value.isEmpty : (value == null || (value is String && value.isEmptyOrNull)));
    return this;
  }
}

extension ColorExt on Color {
  Color applyOpacity(double opacity) => withValues(alpha: opacity);
}

extension MediaTypeExtension on MediaType {
  int get mediaType => switch (this) {
        MediaType.photo => 1,
        MediaType.video => 2,
        MediaType.both => 3,
      };
}
