import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_filter/video_filter_draft.dart';

/// Color matrix and blur for one [VideoFilterDraft].
///
/// The matrix is a Flutter 4×5 color matrix: coefficients multiply the
/// color, and the last column is an offset in 0–255. Apply the matrix
/// first, then [blurSigma]. Export can reuse the same values later.
class VideoFilterLook {
  const VideoFilterLook({
    required this.blurSigma,
    required this.coverScale,
    required this.matrix,
  });

  factory VideoFilterLook.fromDraft(VideoFilterDraft draft) {
    final theme = _scaleTheme(draft);
    final tune = _tuneMatrix(draft);
    return VideoFilterLook(
      matrix: _multiply(tune, theme),
      blurSigma: draft.blur <= 0 ? 0 : draft.blur / 100 * _maxBlurSigma,
      coverScale: 1 + (draft.blur <= 0 ? 0 : draft.blur / 100 * 0.08),
    );
  }

  /// Identity 4×5 matrix.
  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  static const double _maxBlurSigma = 18;

  final double blurSigma;

  /// Scales the frame up so a blur does not leave soft edges.
  final double coverScale;
  final List<double> matrix;

  bool get isIdentity => blurSigma <= 0.01 && _matrixIsIdentity;

  /// FFmpeg `-vf` chain for this look, or null when nothing changes.
  String? get ffmpegVideoFilter {
    if (isIdentity) return null;
    final filters = <String>[];
    if (!_matrixIsIdentity) {
      filters.add(
        'colorchannelmixer='
        'rr=${_n(matrix[0])}:rg=${_n(matrix[1])}:rb=${_n(matrix[2])}:ra=${_n(matrix[3])}:'
        'gr=${_n(matrix[5])}:gg=${_n(matrix[6])}:gb=${_n(matrix[7])}:ga=${_n(matrix[8])}:'
        'br=${_n(matrix[10])}:bg=${_n(matrix[11])}:bb=${_n(matrix[12])}:ba=${_n(matrix[13])}:'
        'ar=${_n(matrix[15])}:ag=${_n(matrix[16])}:ab=${_n(matrix[17])}:aa=${_n(matrix[18])}',
      );
      final red = matrix[4];
      final green = matrix[9];
      final blue = matrix[14];
      if (red.abs() > 0.01 || green.abs() > 0.01 || blue.abs() > 0.01) {
        filters.add(
          'lutrgb='
          'r=\'clip(val+${_n(red)}\\,0\\,255)\':'
          'g=\'clip(val+${_n(green)}\\,0\\,255)\':'
          'b=\'clip(val+${_n(blue)}\\,0\\,255)\'',
        );
      }
    }
    if (blurSigma > 0.01) {
      final scale = coverScale.toStringAsFixed(4);
      filters
        ..add('scale=trunc(iw*$scale/2)*2:trunc(ih*$scale/2)*2')
        ..add('gblur=sigma=${blurSigma.toStringAsFixed(3)}')
        ..add('crop=trunc(iw/$scale/2)*2:trunc(ih/$scale/2)*2');
    }
    filters.add('scale=trunc(iw/2)*2:trunc(ih/2)*2');
    return filters.join(',');
  }

  bool get _matrixIsIdentity {
    for (var index = 0; index < identity.length; index++) {
      if ((matrix[index] - identity[index]).abs() > 0.0001) return false;
    }
    return true;
  }

  static String _n(double value) => value.toStringAsFixed(4);

  static List<double> _scaleTheme(VideoFilterDraft draft) {
    if (draft.theme == VideoFilterTheme.original || draft.level <= 0) {
      return identity;
    }
    return _lerp(identity, _themeMatrix(draft.theme), draft.level / 100);
  }

  static List<double> _themeMatrix(VideoFilterTheme theme) => switch (theme) {
        VideoFilterTheme.original => identity,
        VideoFilterTheme.warm => _multiply(
            _tint(16, 6, -12),
            _multiply(_saturation(1.2), _sepia(0.35)),
          ),
        VideoFilterTheme.cool => _multiply(
            _tint(-14, 4, 18),
            _multiply(_contrast(1.12), _saturation(0.82)),
          ),
        VideoFilterTheme.fade => _multiply(
            _tint(18, 18, 18),
            _multiply(
              _saturation(0.78),
              _multiply(_brightness(1.08), _contrast(0.84)),
            ),
          ),
        VideoFilterTheme.bw => _multiply(_contrast(1.1), _saturation(0)),
        VideoFilterTheme.vivid =>
          _multiply(_contrast(1.08), _saturation(1.5)),
      };

  static List<double> _tuneMatrix(VideoFilterDraft draft) {
    final brightness = 1 + draft.brightness / 200;
    final contrast = 1 + draft.contrast / 200;
    final saturation = 1 + draft.saturation / 100;
    final temp = draft.temp / 100 * 28;
    return _multiply(
      _tint(temp, temp * 0.35, -temp),
      _multiply(
        _saturation(saturation),
        _multiply(_contrast(contrast), _brightness(brightness)),
      ),
    );
  }

  static List<double> _brightness(double factor) => [
        factor, 0, 0, 0, 0, //
        0, factor, 0, 0, 0, //
        0, 0, factor, 0, 0, //
        0, 0, 0, 1, 0,
      ];

  static List<double> _contrast(double factor) {
    final offset = 128 * (1 - factor);
    return [
      factor, 0, 0, 0, offset, //
      0, factor, 0, 0, offset, //
      0, 0, factor, 0, offset, //
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _saturation(double amount) {
    const red = 0.2126;
    const green = 0.7152;
    const blue = 0.0722;
    final rest = 1 - amount;
    return [
      rest * red + amount, rest * green, rest * blue, 0, 0, //
      rest * red, rest * green + amount, rest * blue, 0, 0, //
      rest * red, rest * green, rest * blue + amount, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> _tint(double red, double green, double blue) => [
        1, 0, 0, 0, red, //
        0, 1, 0, 0, green, //
        0, 0, 1, 0, blue, //
        0, 0, 0, 1, 0,
      ];

  static List<double> _sepia(double amount) => _lerp(
        identity,
        const [
          0.393, 0.769, 0.189, 0, 0, //
          0.349, 0.686, 0.168, 0, 0, //
          0.272, 0.534, 0.131, 0, 0, //
          0, 0, 0, 1, 0,
        ],
        amount,
      );

  static List<double> _lerp(List<double> from, List<double> to, double t) =>
      List<double>.generate(20, (index) => from[index] + (to[index] - from[index]) * t);

  /// Applies [outer] after [inner].
  static List<double> _multiply(List<double> outer, List<double> inner) {
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = col == 4 ? outer[row * 5 + 4] : 0.0;
        for (var channel = 0; channel < 4; channel++) {
          sum += outer[row * 5 + channel] * inner[channel * 5 + col];
        }
        out[row * 5 + col] = sum;
      }
    }
    return out;
  }
}
