import 'package:flutter/material.dart';

/// Theme-aware colors for the sound picker flow (defaults follow [ThemeData.brightness]).
class SoundPickerTheme {
  SoundPickerTheme._(this._theme);

  factory SoundPickerTheme.of(BuildContext context) =>
      SoundPickerTheme._(Theme.of(context));

  final ThemeData _theme;

  ColorScheme get _cs => _theme.colorScheme;

  bool get _isDark => _theme.brightness == Brightness.dark;

  Color get scaffoldBackground =>
      _isDark ? const Color(0xFF0B0B0C) : _cs.surface;

  Color get appBarBackground => scaffoldBackground;

  Color get onSurface => _cs.onSurface;

  Color get onSurfaceSecondary =>
      _cs.onSurfaceVariant.withValues(alpha: _isDark ? 0.85 : 0.9);

  Color get onSurfaceTertiary =>
      _cs.onSurfaceVariant.withValues(alpha: _isDark ? 0.65 : 0.72);

  Color get onSurfaceHint =>
      _cs.onSurfaceVariant.withValues(alpha: _isDark ? 0.45 : 0.55);

  Color get searchFieldFill => _isDark
      ? Colors.white.withValues(alpha: 0.08)
      : _cs.surfaceContainerHighest.withValues(alpha: 0.85);

  Color get chipSurface => _isDark
      ? Colors.white.withValues(alpha: 0.06)
      : _cs.surfaceContainerHighest.withValues(alpha: 0.65);

  Color get chipBorderUnselected => _isDark
      ? Colors.white.withValues(alpha: 0.15)
      : _cs.outline.withValues(alpha: 0.35);

  Color get selectionAccent => _cs.primary;

  Color get cursor => _cs.primary;

  Color get playOverlayFill =>
      Colors.black.withValues(alpha: _isDark ? 0.45 : 0.38);

  Color get playIcon => Colors.white;
}
