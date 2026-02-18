import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class IsmAudioPlayer {
  IsmAudioPlayer() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  String? _url;
  String? get url => _url;


  final _listenerController =
  BehaviorSubject<IsmAudioPlayerListener>();

  /// 🔹 Common Listener Stream
  Stream<IsmAudioPlayerListener> get listenerStream =>
      _listenerController.stream;

  /// ------------------------
  /// Controls
  /// ------------------------

  Future<void> setUrl(String url) async {
    _url = url;
    await _player.setUrl(url);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) =>
      _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    _url = null;
    _emitState(IsmAudioPlayerState.stopped);
  }

  Future<void> dispose() async {
    await _listenerController.close();
    await _player.dispose();
  }

  /// ------------------------
  /// Internal logic
  /// ------------------------

  void _init() {
    /// Combine everything into ONE stream
    Rx.combineLatest3<Duration, Duration?, PlayerState,
        IsmAudioPlayerListener>(
      _player.positionStream,
      _player.durationStream,
      _player.playerStateStream,
          (position, duration, playerState) {
        final total = duration ?? Duration.zero;
        final progress = total.inMilliseconds == 0
            ? 0.0
            : position.inMilliseconds /
            total.inMilliseconds;

        return IsmAudioPlayerListener(
          state: _mapState(playerState),
          currentDuration: position,
          totalDuration: total,
          progress: progress.clamp(0.0, 1.0),
          url: url,
        );
      },
    ).listen(_listenerController.add);
  }

  IsmAudioPlayerState _mapState(PlayerState state) {
    if (state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering) {
      return IsmAudioPlayerState.buffering;
    }

    if (state.processingState ==
        ProcessingState.completed) {
      return IsmAudioPlayerState.stopped;
    }

    if (state.playing) {
      return IsmAudioPlayerState.playing;
    }

    return IsmAudioPlayerState.paused;
  }

  void _emitState(IsmAudioPlayerState state) {
    _listenerController.add(
      IsmAudioPlayerListener(
        state: state,
        currentDuration: _player.position,
        totalDuration:
        _player.duration ?? Duration.zero,
        url: url,
        progress: _player.duration == null ||
            _player.duration!.inMilliseconds == 0
            ? 0.0
            : _player.position.inMilliseconds /
            _player.duration!.inMilliseconds,
      ),
    );
  }
}

enum IsmAudioPlayerState {
  playing,
  paused,
  stopped,
  buffering,
}

class IsmAudioPlayerListener {

  // ---------- fromJson ----------
  factory IsmAudioPlayerListener.fromJson(Map<String, dynamic> json) => IsmAudioPlayerListener(
      state: IsmAudioPlayerState.values.firstWhere(
            (e) => e.name == json.getString('state'),
        orElse: () => IsmAudioPlayerState.stopped,
      ),
      currentDuration: Duration(
        milliseconds: json.getInt('currentDuration'),
      ),
      totalDuration: Duration(
        milliseconds: json.getInt('totalDuration'),
      ),
      progress: json.getDouble('progress'),
      url: json.getString('url'),
    );
  // 0.0 → 1.0
  const IsmAudioPlayerListener({
    required this.state,
    required this.currentDuration,
    required this.totalDuration,
    required this.progress,
    required this.url,
  });

  final IsmAudioPlayerState state;
  final Duration currentDuration;
  final Duration totalDuration;
  final double progress;
  final String? url;

  // ---------- toJson ----------
  Map<String, dynamic> toJson() => {
      'state': state.name,
      'currentDuration': currentDuration.inMilliseconds,
      'totalDuration': totalDuration.inMilliseconds,
      'progress': progress,
      'url': url,
    };
}
