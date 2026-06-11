import 'package:audioplayers/audioplayers.dart';

/// Tracks image-post [AudioPlayer] instances. Only one [owner] may play at a time.
abstract final class IsrImageSoundRegistry {
  static final Set<AudioPlayer> _players = <AudioPlayer>{};
  static Object? _activeOwner;

  static void register(AudioPlayer player) => _players.add(player);

  static void unregister(AudioPlayer player) => _players.remove(player);

  static Future<void> stopAll() async {
    for (final player in _players.toList()) {
      try {
        await player.stop();
      } catch (_) {}
    }
    _activeOwner = null;
  }

  /// Stops every other player and grants [owner] exclusive image-sound playback.
  static Future<bool> beginPlaybackFor(Object owner) async {
    if (!identical(_activeOwner, owner)) {
      await stopAll();
      _activeOwner = owner;
    }
    return identical(_activeOwner, owner);
  }

  static void releaseOwner(Object owner) {
    if (identical(_activeOwner, owner)) {
      _activeOwner = null;
    }
  }

  static bool ownsPlayback(Object owner) => identical(_activeOwner, owner);
}
