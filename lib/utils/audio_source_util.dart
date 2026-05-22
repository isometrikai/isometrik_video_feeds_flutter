import 'package:audioplayers/audioplayers.dart';

/// Maps a remote URL or local file path to the correct [Source] for audioplayers.
Source audioSourceFromUrlOrPath(String urlOrPath) {
  final t = urlOrPath.trim();
  if (t.isEmpty) {
    throw ArgumentError.value(urlOrPath, 'urlOrPath', 'must be non-empty');
  }
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return UrlSource(t);
  }
  var filePath = t;
  if (filePath.startsWith('file://')) {
    filePath = Uri.parse(filePath).toFilePath();
  }
  return DeviceFileSource(filePath);
}
