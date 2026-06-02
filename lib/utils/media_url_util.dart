bool isLikelyImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return false;
  }
  final path = uri.path.toLowerCase();
  const blockedMediaExt = [
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.ogg',
    '.flac',
    '.mp4',
    '.mov',
    '.mkv',
    '.webm',
    '.m3u8',
  ];
  return !blockedMediaExt.any(path.endsWith);
}
