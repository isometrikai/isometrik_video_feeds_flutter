import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';

/// Single sound from `/api/v1/sounds/*` (trending, recommended, saved, etc.).
class SoundData {
  const SoundData({
    required this.id,
    this.title,
    this.artist,
    this.album,
    this.durationSeconds,
    this.url,
    this.previewUrl,
    this.waveformUrl,
    this.type,
    this.status,
    this.categoryIds = const [],
    this.userId,
    this.usageCount,
    this.isSaved,
    this.createdAt,
  });

  factory SoundData.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['category_ids'];
    final categories = rawCategories is List
        ? rawCategories.map((e) => e.toString()).toList()
        : const <String>[];

    final duration = map['duration'];
    double? durationSeconds;
    if (duration is num) {
      durationSeconds = duration.toDouble();
    } else if (duration is String) {
      durationSeconds = double.tryParse(duration);
    }

    final album = map['album'] as String?;
    final categoryIds = categories.isNotEmpty
        ? categories
        : (album != null && album.trim().isNotEmpty)
            ? <String>[album.trim()]
            : const <String>[];

    return SoundData(
      id: (map['id'] ?? map['sound_id'] ?? '').toString(),
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: album,
      durationSeconds: durationSeconds,
      url: map['url'] as String?,
      previewUrl: map['preview_url'] as String?,
      waveformUrl: map['waveform_url'] as String?,
      type: map['type'] as String?,
      status: map['status'] as String?,
      categoryIds: categoryIds,
      userId: map['user_id']?.toString(),
      usageCount: map['usage_count'] as num?,
      isSaved: map['is_saved'] as bool? ?? map['saved'] as bool?,
      createdAt: map['created_at'] as String?,
    );
  }

  final String id;
  final String? title;
  final String? artist;
  final String? album;
  final double? durationSeconds;
  final String? url;
  final String? previewUrl;
  final String? waveformUrl;
  final String? type;
  final String? status;
  final List<String> categoryIds;
  final String? userId;
  final num? usageCount;
  final bool? isSaved;
  final String? createdAt;

  SoundTrack toSoundTrack({String fallbackPreviewUrl = ''}) {
    final preview = (previewUrl ?? '').trim();
    final full = (url ?? '').trim();
    final thumb = (waveformUrl ?? preview).trim();
    final trackUrl = preview.isNotEmpty ? preview : full;
    final seconds = durationSeconds ?? 0;
    return SoundTrack(
      id: id,
      thumbnailUrl: thumb.isNotEmpty
          ? thumb
          : 'https://picsum.photos/seed/sound$id/300/300',
      trackUrl: trackUrl.isNotEmpty ? trackUrl : fallbackPreviewUrl,
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Untitled',
      author:
          artist?.trim().isNotEmpty == true ? artist!.trim() : 'Unknown artist',
      duration: Duration(
        milliseconds: (seconds * 1000).round().clamp(0, 86400000),
      ),
      categoryIds: categoryIds,
      originalStatus: status?.trim().isNotEmpty == true ? status!.trim() : null,
    );
  }
}

/// Pagination fields returned alongside list endpoints.
class SoundsPagination {
  const SoundsPagination({
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  factory SoundsPagination.fromMap(Map<String, dynamic> map) => SoundsPagination(
        total: _asInt(map['total']),
        page: _asInt(map['page']),
        pageSize: _asInt(map['page_size']),
        totalPages: _asInt(map['total_pages']),
      );

  final int? total;
  final int? page;
  final int? pageSize;
  final int? totalPages;
}

/// Wrapper for list responses:
/// `{ status, message, status_code, code, data, total, page, page_size, total_pages }`
class SoundsListResponse {
  const SoundsListResponse({
    this.status,
    this.message,
    this.statusCode,
    this.code,
    this.sounds = const [],
    this.pagination,
  });

  factory SoundsListResponse.fromMap(Map<String, dynamic> map) {
    final sounds = parseSoundDataList(map['data']);
    return SoundsListResponse(
      status: map['status'] as String?,
      message: map['message'] as String?,
      statusCode: _asInt(map['status_code']),
      code: map['code']?.toString(),
      sounds: sounds,
      pagination: SoundsPagination.fromMap(map),
    );
  }

  final String? status;
  final String? message;
  final int? statusCode;
  final String? code;
  final List<SoundData> sounds;
  final SoundsPagination? pagination;

  bool get isSuccess =>
      status == 'success' || statusCode == 200 || code == '2000';
}

List<SoundData> soundDataListFromResponseBody(Map<String, dynamic> jsonData) =>
    SoundsListResponse.fromMap(jsonData).sounds;

SoundData? soundDataFromResponseBody(Map<String, dynamic> jsonData) {
  final dynamic data = jsonData['data'];
  if (data is Map<String, dynamic>) {
    return SoundData.fromMap(data);
  }
  if (data is Map) {
    return SoundData.fromMap(Map<String, dynamic>.from(data));
  }
  final list = parseSoundDataList(data);
  return list.isNotEmpty ? list.first : null;
}

bool isSoundSavedFromResponseBody(Map<String, dynamic> jsonData) {
  final dynamic data = jsonData['data'];
  if (data is bool) return data;
  if (data is Map) {
    return data['is_saved'] == true ||
        data['saved'] == true ||
        data['isSaved'] == true;
  }
  return jsonData['is_saved'] == true || jsonData['saved'] == true;
}

/// Parses `data` from trending (flat list) or recommended (nested `[[sounds], n]`).
List<SoundData> parseSoundDataList(dynamic data) {
  final rawList = _extractRawSoundList(data);
  if (rawList == null || rawList.isEmpty) return [];

  return rawList
      .map(_mapToSoundData)
      .whereType<SoundData>()
      .where((s) => s.id.isNotEmpty)
      .toList();
}

List<dynamic>? _extractRawSoundList(dynamic data) {
  if (data == null) return null;

  if (data is List) {
    if (data.isEmpty) return [];

    // Recommended: data = [[{sound}, ...], 10]
    if (data.first is List) {
      final nested = data.first as List;
      if (nested.isNotEmpty && _isSoundMap(nested.first)) {
        return nested;
      }
    }

    // Trending / search: data = [{sound}, ...]
    if (_isSoundMap(data.first)) {
      return data;
    }

    // Fallback: first child list that looks like sounds
    for (final item in data) {
      if (item is List && item.isNotEmpty && _isSoundMap(item.first)) {
        return item;
      }
    }
    return data;
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['sounds', 'items', 'results', 'data']) {
      final nested = map[key];
      final extracted = _extractRawSoundList(nested);
      if (extracted != null && extracted.isNotEmpty) {
        return extracted;
      }
    }
  }

  return null;
}

bool _isSoundMap(dynamic value) {
  if (value is! Map) return false;
  final map = Map<String, dynamic>.from(value);
  return (map['id'] ?? map['sound_id']) != null;
}

SoundData? _mapToSoundData(dynamic value) {
  if (value is Map<String, dynamic>) {
    return SoundData.fromMap(value);
  }
  if (value is Map) {
    return SoundData.fromMap(Map<String, dynamic>.from(value));
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
