import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class SoundLibraryUseCase extends BaseUseCase {
  SoundLibraryUseCase(this._repository, this._localDataUseCase);

  final SoundsRepository _repository;
  final IsmLocalDataUseCase _localDataUseCase;

  Future<ApiResult<SoundLibrarySections>> loadSections({
    required bool isLoading,
    String fallbackPreviewUrl = '',
  }) async =>
      execute(() async {
        final recentR =
            await _repository.listRecentSounds(isLoading: isLoading, limit: 10);
        final trendingR = await _repository.listTrendingSounds(
          isLoading: isLoading,
          page: 1,
          pageSize: 10,
        );
        final recommendedR = await _repository.listRecommendedSounds(
          isLoading: isLoading,
          page: 1,
          pageSize: 10,
        );
        final savedR =
            await _repository.listSavedSounds(isLoading: isLoading, limit: 20);

        List<SoundTrack> map(CustomResponse<List<SoundData>?> r) =>
            (r.data ?? [])
                .map(
                  (s) => s.toSoundTrack(fallbackPreviewUrl: fallbackPreviewUrl),
                )
                .toList();

        return ApiResult(
          data: SoundLibrarySections(
            recent: map(recentR),
            trending: map(trendingR),
            recommended: map(recommendedR),
            saved: map(savedR),
          ),
        );
      });

  Future<ApiResult<List<SoundTrack>>> searchSounds({
    required bool isLoading,
    required String query,
    String? categoryIds,
    String fallbackPreviewUrl = '',
  }) async =>
      execute(() async {
        final response = await _repository.listSounds(
          isLoading: isLoading,
          search: query,
          categoryIds: categoryIds,
          page: 1,
          pageSize: 30,
        );
        final tracks = (response.data ?? [])
            .map((s) => s.toSoundTrack(fallbackPreviewUrl: fallbackPreviewUrl))
            .toList();
        return ApiResult(data: tracks);
      });

  Future<ApiResult<bool>> toggleSaved({
    required bool isLoading,
    required String soundId,
    required bool currentlySaved,
  }) async =>
      execute(() async {
        if (currentlySaved) {
          final response =
              await _repository.unsaveSound(isLoading: isLoading, soundId: soundId);
          return ApiResult(data: response.data == true);
        }
        final userId = await _localDataUseCase.getUserId();
        final response = await _repository.saveSound(
          isLoading: isLoading,
          soundId: soundId,
          userId: userId,
        );
        return ApiResult(data: response.data == true);
      });

  Future<ApiResult<bool>> checkIsSaved({
    required bool isLoading,
    required String soundId,
  }) async =>
      execute(() async {
        final response = await _repository.isSoundSaved(
          isLoading: isLoading,
          soundId: soundId,
        );
        return ApiResult(data: response.data == true);
      });

  Future<ApiResult<SoundTrack?>> getSoundTrackById({
    required bool isLoading,
    required String soundId,
    String fallbackPreviewUrl = '',
  }) async =>
      execute(() async {
        final response = await _repository.getSoundDetails(
          isLoading: isLoading,
          soundId: soundId,
        );
        final track = response.data
            ?.toSoundTrack(fallbackPreviewUrl: fallbackPreviewUrl);
        return ApiResult(data: track);
      });
}

class SoundLibrarySections {
  const SoundLibrarySections({
    required this.recent,
    required this.trending,
    required this.recommended,
    required this.saved,
  });

  final List<SoundTrack> recent;
  final List<SoundTrack> trending;
  final List<SoundTrack> recommended;
  final List<SoundTrack> saved;

  List<SoundCategory> deriveCategories() {
    final ids = <String>{};
    for (final list in [recent, trending, recommended, saved]) {
      for (final t in list) {
        ids.addAll(t.categoryIds);
      }
    }
    return ids
        .map(
          (id) => SoundCategory(
            id: id,
            title: _humanizeCategoryId(id),
            thumbnailUrl:
                'https://picsum.photos/seed/cat$id/200/200',
          ),
        )
        .toList();
  }
}

String _humanizeCategoryId(String id) {
  final cleaned = id.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (cleaned.isEmpty) return id;
  return cleaned.split(' ').map((w) {
    if (w.isEmpty) return w;
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}
