import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:video_compress/video_compress.dart';

/// Story cubit handling story feed and highlight CRUD/action calls.
class StoryCubit extends Cubit<StoryState> {
  StoryCubit(
    this._storyUseCase,
    this._localDataUseCase,
    this._googleCloudStorageUploaderUseCase,
  )
      : super(const StoryInitial());

  final StoryUseCase _storyUseCase;
  final IsmLocalDataUseCase _localDataUseCase;
  final GoogleCloudStorageUploaderUseCase _googleCloudStorageUploaderUseCase;

  String? _nextCursor;
  String _currentUserId = '';
  final List<StoryGroup> _unViewed = [];
  final List<StoryGroup> _viewed = [];

  List<StoryGroup> get cachedStoryGroups => [..._unViewed, ..._viewed];
  String get currentUserId => _currentUserId;

  bool get _usesBackgroundStoryUi =>
      IsrVideoReelConfig.storyConfig?.storyCallbackConfig
          .onBackgroundStoryOperation !=
      null;

  StoryUploadPayload? _lastStoryPayloadForRetry;

  void _retryBackgroundStory() {
    final payload = _lastStoryPayloadForRetry;
    if (payload != null) {
      unawaited(createStoryFromPayload(payload));
    }
  }

  void _notifyBackgroundStory(BackgroundStoryOperationUpdate update) {
    IsrVideoReelConfig.storyConfig?.storyCallbackConfig
        .onBackgroundStoryOperation
        ?.call(update);
  }

  void _notifyBackgroundStoryUpload({
    required double percent,
    String? fileName,
    bool isError = false,
    String? errorMessage,
  }) {
    _notifyBackgroundStory(
      BackgroundStoryOperationUpdate(
        phase: isError
            ? BackgroundStoryOperationPhase.failure
            : BackgroundStoryOperationPhase.uploading,
        overallProgressPercent: percent.clamp(0, 100),
        title: isError ? null : 'Uploading story',
        subtitle: fileName,
        currentFileIndex: 1,
        totalFiles: 1,
        currentFileName: fileName,
        isUploadError: isError,
        failureKind:
            isError ? BackgroundStoryFailureKind.upload : null,
        failureMessage: errorMessage,
        retry: isError ? _retryBackgroundStory : null,
      ),
    );
  }

  void _notifyBackgroundStoryCreating() {
    _notifyBackgroundStory(
      BackgroundStoryOperationUpdate(
        phase: BackgroundStoryOperationPhase.creatingStory,
        overallProgressPercent: 100,
        title: 'Publishing story',
        retry: _retryBackgroundStory,
      ),
    );
  }

  void _notifyBackgroundStoryProcessing() {
    _notifyBackgroundStory(
      BackgroundStoryOperationUpdate(
        phase: BackgroundStoryOperationPhase.processingMedia,
        overallProgressPercent: 0,
        title: 'Processing story',
        retry: _retryBackgroundStory,
      ),
    );
  }

  void _notifyBackgroundStorySuccess({String? storyId}) {
    _notifyBackgroundStory(
      BackgroundStoryOperationUpdate(
        phase: BackgroundStoryOperationPhase.success,
        overallProgressPercent: 100,
        storyId: storyId,
        successTitle: 'Story posted',
        successMessage: 'Your story is live.',
      ),
    );
  }

  void _notifyBackgroundStoryFailure(
    String message, {
    BackgroundStoryFailureKind kind = BackgroundStoryFailureKind.upload,
  }) {
    _notifyBackgroundStory(
      BackgroundStoryOperationUpdate(
        phase: BackgroundStoryOperationPhase.failure,
        failureKind: kind,
        failureMessage: message,
        retry: _retryBackgroundStory,
      ),
    );
  }

  void _emitStoryError(String message) {
    if (_usesBackgroundStoryUi) {
      _notifyBackgroundStoryFailure(message);
    } else {
      emit(StoryError(message));
    }
  }

  Future<void> loadStoryFeed({
    bool isLoading = false,
    bool isPagination = false,
    int limit = 50,
  }) async {
    if (!isPagination) {
      emit(const StoryLoading());
    }
    final result = await _storyUseCase.executeGetStoryFeed(
      isLoading: isLoading,
      limit: limit,
      cursor: isPagination ? _nextCursor : null,
    );
    if (result.isSuccess && result.data != null) {
      if (!isPagination) {
        _unViewed
          ..clear()
          ..addAll(result.data?.unViewed ?? []);
        _viewed
          ..clear()
          ..addAll(result.data?.viewed ?? []);
      } else {
        _unViewed.addAll(result.data?.unViewed ?? []);
        _viewed.addAll(result.data?.viewed ?? []);
      }
      _nextCursor = result.data?.nextCursor;

      final userId = await _localDataUseCase.getUserId();
      _currentUserId = userId;
      if (userId.isNotEmpty) {
        final mine = await _storyUseCase.executeGetStories(
          isLoading: false,
          userId: userId,
        );
        if (mine.isSuccess &&
            mine.data != null &&
            mine.data!.isNotEmpty) {
          await _mergeCurrentUserStoryRing(
            userId: userId,
            stories: mine.data!,
          );
        }
      }

      emit(
        StoryFeedLoaded(
          unViewed: _unViewed.toList(),
          viewed: _viewed.toList(),
          nextCursor: _nextCursor,
        ),
      );
      IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryFeedLoaded
          ?.call([..._unViewed, ..._viewed]);
      return;
    }
    final message = result.error?.message ?? 'Unable to load story feed.';
    emit(StoryError(message));
    IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError
        ?.call('load_story_feed', message);
  }

  Future<void> createStory(CreateStoryRequest request) async {
    if (!_usesBackgroundStoryUi) {
      emit(const StoryLoading());
    } else {
      _notifyBackgroundStoryCreating();
    }
    final createResult = await _storyUseCase.executeCreateStory(
      isLoading: false,
      request: request,
    );
    final responseMap = createResult.data?.decode();
    final storyId = responseMap?['data']?['id']?.toString() ?? '';
    if (createResult.isSuccess && storyId.isNotEmpty) {
      if (_usesBackgroundStoryUi) {
        _notifyBackgroundStoryProcessing();
      }
      final processResult = await _storyUseCase.executeStartStoryProcessing(
        isLoading: false,
        storyId: storyId,
      );
      if (processResult.isSuccess) {
        if (_usesBackgroundStoryUi) {
          _notifyBackgroundStorySuccess(storyId: storyId);
          unawaited(loadStoryFeed(isLoading: false));
          return;
        }
        emit(const StoryActionSuccess('create_story'));
        unawaited(loadStoryFeed());
        return;
      }
      final message =
          processResult.error?.message ?? 'Story created but processing failed.';
      if (_usesBackgroundStoryUi) {
        _notifyBackgroundStoryFailure(
          message,
          kind: BackgroundStoryFailureKind.mediaProcessing,
        );
      } else {
        emit(StoryError(message));
      }
      return;
    }
    final message =
        createResult.error?.message ?? 'Unable to create story.';
    if (_usesBackgroundStoryUi) {
      _notifyBackgroundStoryFailure(
        message,
        kind: BackgroundStoryFailureKind.createApi,
      );
    } else {
      emit(StoryError(message));
    }
  }

  Future<void> handleCreateStoryTap() async {
    final storyConfig = IsrVideoReelConfig.storyConfig;
    final callbackConfig = IsrVideoReelConfig.storyConfig?.storyCallbackConfig;
    await callbackConfig?.onCreateStoryTap?.call();
    final customCreateNavigator = callbackConfig?.navigateToCreateStory;
    if (customCreateNavigator != null) {
      final context = IsrVideoReelConfig.getBuildContext?.call() ??
          IsrVideoReelConfig.buildContext;
      if (context != null) {
        await customCreateNavigator(context);
        return;
      }
    }
    final payload = await callbackConfig?.onRequestStoryUploadPayload?.call();
    if (payload == null) return;
    final uploadMode = storyConfig?.uploadMode ?? callbackConfig?.uploadMode;
    if (uploadMode == StoryUploadMode.sdkManagedGoogleCloud) {
      await _createStoryViaSdkUpload(payload);
      return;
    }
    await createStoryFromPayload(payload);
  }

  Future<void> createStoryFromPayload(StoryUploadPayload payload) async {
    _lastStoryPayloadForRetry = payload;
    if (_usesBackgroundStoryUi) {
      unawaited(_runCreateStoryFromPayload(payload));
      return;
    }
    await _runCreateStoryFromPayload(payload);
  }

  Future<void> _runCreateStoryFromPayload(StoryUploadPayload payload) async {
    final mediaUrl = payload.mediaUrl?.trim() ?? '';
    if (mediaUrl.isNotEmpty) {
      final request = await _createStoryRequest(mediaUrl, payload);
      await createStory(request);
      return;
    }
    final storyConfig = IsrVideoReelConfig.storyConfig;
    final callbackConfig = storyConfig?.storyCallbackConfig;
    final socialUpload = IsrVideoReelConfig
        .socialConfig.socialCallBackConfig?.uploadMediaToCloud;
    if (storyConfig?.uploadMediaToCloud != null ||
        callbackConfig?.uploadMediaToCloud != null ||
        socialUpload != null) {
      await _createStoryViaHostUploadCallback(payload);
      return;
    }
    final uploadMode = storyConfig?.uploadMode ??
        callbackConfig?.uploadMode ??
        StoryUploadMode.hostProvidedUrl;
    if (uploadMode == StoryUploadMode.sdkManagedGoogleCloud) {
      await _createStoryViaSdkUpload(payload);
      return;
    }
    final gcs = IsrVideoReelConfig.socialConfig.googleCloudUpload;
    if (payload.file != null &&
        gcs != null &&
        gcs.bucketName.isNotEmpty &&
        gcs.credentialsJsonPath.isNotEmpty) {
      await _createStoryViaSdkUpload(payload);
      return;
    }
    _emitStoryError(
      'Provide mediaUrl or configure upload callback/upload mode for story creation.',
    );
  }

  Future<void> _createStoryViaSdkUpload(StoryUploadPayload payload) async {
    final file = payload.file;
    if (file == null) {
      _emitStoryError(
        'Host must provide file for sdkManagedGoogleCloud upload mode.',
      );
      return;
    }
    final filePath = file.path;
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex > 0 ? fileName.substring(dotIndex + 1) : 'jpg';
    if (_usesBackgroundStoryUi) {
      _notifyBackgroundStoryUpload(percent: 0, fileName: fileName);
    }
    final userId = await _localDataUseCase.getUserId();
    final uploadedUrl =
        await _googleCloudStorageUploaderUseCase.executeGoogleCloudStorageUploader(
      file: File(filePath),
      fileName: fileName,
      userId: userId,
      fileExtension: extension,
      cloudFolderName: 'stories',
    );
    if ((uploadedUrl ?? '').trim().isEmpty) {
      if (_usesBackgroundStoryUi) {
        _notifyBackgroundStoryUpload(
          percent: 0,
          fileName: fileName,
          isError: true,
          errorMessage: 'Failed to upload story media.',
        );
      } else {
        _emitStoryError('Failed to upload story media.');
      }
      return;
    }
    if (_usesBackgroundStoryUi) {
      _notifyBackgroundStoryUpload(percent: 100, fileName: fileName);
    }
    final request = await _createStoryRequest(uploadedUrl!.trim(), payload);
    await createStory(request);
  }

  Future<void> _createStoryViaHostUploadCallback(StoryUploadPayload payload) async {
    final file = payload.file;
    if (file == null) {
      _emitStoryError('File is required for host upload callback.');
      return;
    }
    final callback = IsrVideoReelConfig.storyConfig?.uploadMediaToCloud ??
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.uploadMediaToCloud ??
        IsrVideoReelConfig.socialConfig.socialCallBackConfig?.uploadMediaToCloud;
    if (callback == null) {
      _emitStoryError('Story upload callback is not configured.');
      return;
    }
    final filePath = file.path;
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex > 0 ? fileName.substring(dotIndex + 1) : 'jpg';
    final mediaType = payload.mediaType.toLowerCase().contains('video')
        ? MediaType.video
        : MediaType.photo;
    if (_usesBackgroundStoryUi) {
      _notifyBackgroundStoryUpload(percent: 0, fileName: fileName);
    }
    try {
      final uploadedUrl = await callback(
        File(filePath),
        fileName,
        mediaType,
        (progress) {
          if (_usesBackgroundStoryUi) {
            _notifyBackgroundStoryUpload(
              percent: progress.clamp(0, 100),
              fileName: fileName,
            );
          }
        },
        'stories',
        extension,
      );
      if (uploadedUrl.trim().isEmpty) {
        if (_usesBackgroundStoryUi) {
          _notifyBackgroundStoryUpload(
            percent: 0,
            fileName: fileName,
            isError: true,
            errorMessage: 'Host upload callback returned empty URL.',
          );
        } else {
          _emitStoryError('Host upload callback returned empty URL.');
        }
        return;
      }
      if (_usesBackgroundStoryUi) {
        _notifyBackgroundStoryUpload(percent: 100, fileName: fileName);
      }
      final request = await _createStoryRequest(uploadedUrl.trim(), payload);
      await createStory(request);
    } catch (e) {
      if (_usesBackgroundStoryUi) {
        _notifyBackgroundStoryUpload(
          percent: 0,
          fileName: fileName,
          isError: true,
          errorMessage: e.toString(),
        );
      } else {
        _emitStoryError(e.toString());
      }
    }
  }

  /// Uploads a local image and returns a public URL for a highlight cover.
  /// Uses the same upload configuration as story media (host callback or GCS).
  /// Does not emit [StoryState] so callers can handle failures in UI.
  Future<String?> uploadHighlightCoverFile(File file) async {
    final filePath = file.path;
    if (filePath.isEmpty) return null;

    final storyConfig = IsrVideoReelConfig.storyConfig;
    final callbackConfig = storyConfig?.storyCallbackConfig;
    final socialUpload = IsrVideoReelConfig
        .socialConfig.socialCallBackConfig?.uploadMediaToCloud;
    final callback = storyConfig?.uploadMediaToCloud ??
        callbackConfig?.uploadMediaToCloud ??
        socialUpload;

    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex > 0 ? fileName.substring(dotIndex + 1) : 'jpg';

    if (callback != null) {
      try {
        final uploadedUrl = await callback(
          File(filePath),
          fileName,
          MediaType.photo,
          (_) {},
          'highlights',
          extension,
        );
        final url = uploadedUrl.trim();
        return url.isEmpty ? null : url;
      } catch (_) {
        return null;
      }
    }

    final uploadMode = storyConfig?.uploadMode ??
        callbackConfig?.uploadMode ??
        StoryUploadMode.hostProvidedUrl;
    if (uploadMode == StoryUploadMode.sdkManagedGoogleCloud) {
      final userId = await _localDataUseCase.getUserId();
      final uploadedUrl =
          await _googleCloudStorageUploaderUseCase.executeGoogleCloudStorageUploader(
        file: File(filePath),
        fileName: fileName,
        userId: userId,
        fileExtension: extension,
        cloudFolderName: 'highlights',
      );
      final url = (uploadedUrl ?? '').trim();
      return url.isEmpty ? null : url;
    }

    final gcs = IsrVideoReelConfig.socialConfig.googleCloudUpload;
    if (gcs != null &&
        gcs.bucketName.isNotEmpty &&
        gcs.credentialsJsonPath.isNotEmpty) {
      final userId = await _localDataUseCase.getUserId();
      final uploadedUrl =
          await _googleCloudStorageUploaderUseCase.executeGoogleCloudStorageUploader(
        file: File(filePath),
        fileName: fileName,
        userId: userId,
        fileExtension: extension,
        cloudFolderName: 'highlights',
      );
      final url = (uploadedUrl ?? '').trim();
      return url.isEmpty ? null : url;
    }

    return null;
  }

  Future<void> _mergeCurrentUserStoryRing({
    required String userId,
    required List<StoryData> stories,
  }) async {
    if (stories.isEmpty) return;
    _unViewed.removeWhere((g) => g.userId == userId);
    _viewed.removeWhere((g) => g.userId == userId);
    final username = await _localDataUseCase.getUserName();
    final avatarUrl = await _localDataUseCase.getProfilePic();
    final existingById = <String, StoryData>{};
    for (final g in [..._unViewed, ..._viewed]) {
      if (g.userId != userId) continue;
      for (final s in g.stories) {
        existingById[s.id] = s;
      }
    }

    StoryData mergeWithFeed(StoryData s) {
      final base =
          s.userId.isEmpty ? s.copyWith(userId: userId) : s;
      final existing = existingById[base.id];
      if (existing == null) return base;
      return base.copyWith(
        viewCount: base.viewCount > 0 ? base.viewCount : existing.viewCount,
        caption: base.caption.isNotEmpty ? base.caption : existing.caption,
        username:
            base.username.isNotEmpty ? base.username : existing.username,
        fullName: base.fullName.isNotEmpty ? base.fullName : existing.fullName,
        avatarUrl:
            base.avatarUrl.isNotEmpty ? base.avatarUrl : existing.avatarUrl,
        isReacted: base.isReacted || existing.isReacted,
      );
    }

    final normalized = stories.map(mergeWithFeed).toList();
    _unViewed.insert(
      0,
      StoryGroup(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        stories: normalized,
      ),
    );
  }

  Future<CreateStoryRequest> _createStoryRequest(
    String mediaUrl,
    StoryUploadPayload payload,
  ) async {
    var videoDurationSeconds = payload.videoDurationSeconds;
    if (payload.mediaType.toLowerCase().contains('video') &&
        (videoDurationSeconds == null || videoDurationSeconds <= 0) &&
        payload.file != null) {
      try {
        final info = await VideoCompress.getMediaInfo(payload.file!.path);
        final seconds = ((info.duration ?? 0) / 1000).round();
        videoDurationSeconds = seconds > 0 ? seconds : 1;
      } catch (_) {
        videoDurationSeconds = 1;
      }
    }
    return CreateStoryRequest(
        mediaUrl: mediaUrl,
        mediaType: payload.mediaType,
        caption: payload.caption,
        expiresInHours: payload.expiresInHours,
        mediaPosition: payload.mediaPosition,
        assetId: payload.assetId,
        description: payload.description,
        extraData: payload.extraData,
        privacy: payload.privacy,
        soundId: payload.soundId,
        soundSnapshot: payload.soundSnapshot,
        tags: payload.tags,
        textFormatting: payload.textFormatting,
        videoDurationSeconds: videoDurationSeconds,
      );
  }

  void _emitFeedIfCached() {
    if (_unViewed.isEmpty && _viewed.isEmpty) return;
    emit(
      StoryFeedLoaded(
        unViewed: _unViewed.toList(),
        viewed: _viewed.toList(),
        nextCursor: _nextCursor,
      ),
    );
  }

  void _markStoryViewedLocally(String storyId) {
    StoryData viewedCopy(StoryData s) =>
        s.id == storyId ? s.copyWith(isViewed: true) : s;

    StoryGroup mapGroup(StoryGroup g) {
      final nextStories = g.stories.map(viewedCopy).toList();
      final allDone =
          nextStories.isNotEmpty && nextStories.every((x) => x.isViewed);
      return StoryGroup(
        userId: g.userId,
        username: g.username,
        avatarUrl: g.avatarUrl,
        stories: nextStories,
        isViewed: allDone,
      );
    }

    final nu = _unViewed.map(mapGroup).toList();
    final nv = _viewed.map(mapGroup).toList();
    _unViewed
      ..clear()
      ..addAll(nu);
    _viewed
      ..clear()
      ..addAll(nv);
  }

  Future<void> markStoryViewed(String storyId) async {
    final result = await _storyUseCase.executeMarkStoryViewed(
      isLoading: false,
      storyId: storyId,
    );
    if (_unViewed.isNotEmpty || _viewed.isNotEmpty) {
      if (result.isSuccess) {
        _markStoryViewedLocally(storyId);
      }
      _emitFeedIfCached();
      if (!result.isSuccess) {
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError
            ?.call(
          'mark_story_viewed',
          result.error?.message ?? 'Unable to mark story viewed.',
        );
      }
      return;
    }
    if (result.isSuccess) {
      emit(const StoryActionSuccess('mark_story_viewed'));
    } else {
      emit(StoryError(
          result.error?.message ?? 'Unable to mark story viewed.'));
    }
  }

  Future<bool> addReaction({
    required String storyId,
    required String reactionType,
  }) async {
    final result = await _storyUseCase.executeAddStoryReaction(
      isLoading: false,
      storyId: storyId,
      reactionType: reactionType,
    );
    if (_unViewed.isNotEmpty || _viewed.isNotEmpty) {
      _emitFeedIfCached();
      if (!result.isSuccess) {
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError
            ?.call(
          'add_story_reaction',
          result.error?.message ?? 'Unable to add reaction.',
        );
      }
      return result.isSuccess;
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('add_story_reaction')
        : StoryError(result.error?.message ?? 'Unable to add reaction.'));
    return result.isSuccess;
  }

  Future<bool> removeReaction(String storyId) async {
    final result = await _storyUseCase.executeRemoveStoryReaction(
      isLoading: false,
      storyId: storyId,
    );
    if (_unViewed.isNotEmpty || _viewed.isNotEmpty) {
      _emitFeedIfCached();
      if (!result.isSuccess) {
        IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onStoryActionError
            ?.call(
          'remove_story_reaction',
          result.error?.message ?? 'Unable to remove reaction.',
        );
      }
      return result.isSuccess;
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('remove_story_reaction')
        : StoryError(result.error?.message ?? 'Unable to remove reaction.'));
    return result.isSuccess;
  }

  Future<void> loadHighlights({String? userId}) async {
    emit(const StoryLoading());
    final targetUserId = userId ?? await _localDataUseCase.getUserId();
    final result = await _storyUseCase.executeGetStoryHighlights(
      isLoading: false,
      userId: targetUserId,
    );
    if (result.isSuccess) {
      emit(StoryHighlightsLoaded(result.data ?? const []));
    } else {
      emit(StoryError(result.error?.message ?? 'Unable to load highlights.'));
    }
  }

  Future<void> createHighlight(CreateStoryHighlightRequest request) async {
    final result = await _storyUseCase.executeCreateStoryHighlight(
      isLoading: true,
      request: request,
    );
    if (result.isSuccess) {
      _notifyHostHighlightsChanged();
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('create_highlight')
        : StoryError(result.error?.message ?? 'Unable to create highlight.'));
  }

  Future<bool> createHighlightWithStories({
    required String title,
    required List<String> storyIds,
    String? coverUrl,
    int? sortOrder,
  }) async {
    final result = await _storyUseCase.executeCreateStoryHighlight(
      isLoading: true,
      request: CreateStoryHighlightRequest(
        title: title,
        coverUrl: coverUrl,
        sortOrder: sortOrder,
        storyIds: storyIds,
      ),
    );
    if (!result.isSuccess) {
      emit(StoryError(result.error?.message ?? 'Unable to create highlight.'));
      return false;
    }
    _notifyHostHighlightsChanged();
    emit(const StoryActionSuccess('create_highlight'));
    return true;
  }

  Future<void> updateHighlight({
    required String highlightId,
    required UpdateStoryHighlightRequest request,
  }) async {
    final result = await _storyUseCase.executeUpdateStoryHighlight(
      isLoading: false,
      highlightId: highlightId,
      request: request,
    );
    if (result.isSuccess) {
      _notifyHostHighlightsChanged();
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('update_highlight')
        : StoryError(result.error?.message ?? 'Unable to update highlight.'));
  }

  Future<bool> deleteHighlight(String highlightId) async {
    final result = await _storyUseCase.executeDeleteStoryHighlight(
      isLoading: false,
      highlightId: highlightId,
    );
    if (result.isSuccess) {
      _notifyHostHighlightsChanged();
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('delete_highlight')
        : StoryError(result.error?.message ?? 'Unable to delete highlight.'));
    return result.isSuccess;
  }

  Future<bool> addStoriesToHighlight({
    required String highlightId,
    required List<String> storyIds,
  }) async {
    final result = await _storyUseCase.executeAddStoriesToHighlight(
      isLoading: false,
      highlightId: highlightId,
      request: AddStoriesToHighlightRequest(storyIds: storyIds),
    );
    if (result.isSuccess) {
      await getStoryHighlightById(highlightId);
      _notifyHostHighlightsChanged();
      emit(const StoryActionSuccess('add_stories_to_highlight'));
      return true;
    }
    emit(StoryError(
        result.error?.message ?? 'Unable to update highlight stories.'));
    return false;
  }

  /// Current user's past stories for the highlight composer picker.
  /// Returns `null` when the API call fails.
  Future<List<StoryData>?> getMyStories() async {
    final result = await _storyUseCase.executeGetMyStories(isLoading: false);
    if (!result.isSuccess) return null;
    return result.data ?? const [];
  }

  Future<List<StoryHighlightData>> getHighlightsForCurrentUser() async {
    final targetUserId = await _localDataUseCase.getUserId();
    if (targetUserId.isEmpty) return const [];
    final result = await _storyUseCase.executeGetStoryHighlights(
      isLoading: false,
      userId: targetUserId,
    );
    return result.isSuccess ? (result.data ?? const []) : const [];
  }

  Future<StoryHighlightData?> getStoryHighlightById(String highlightId) async {
    try {
      final result = await _storyUseCase.executeGetStoryHighlightById(
        isLoading: false,
        highlightId: highlightId,
      );
      return result.isSuccess ? result.data : null;
    } catch (_) {
      return null;
    }
  }

  Future<StoryData?> getStoryDetailById(String storyId) async {
    try {
      final result = await _storyUseCase.executeGetStoryDetail(
        isLoading: false,
        storyId: storyId,
      );
      return result.isSuccess ? result.data : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StoryData>> getStoriesByUserId(String userId) async {
    try {
      final result = await _storyUseCase.executeGetStories(
        isLoading: false,
        userId: userId,
      );
      return result.isSuccess ? (result.data ?? const []) : const [];
    } catch (_) {
      return const [];
    }
  }

  Future<StoryHighlightData?> addStoryToHighlight({
    required String highlightId,
    required String storyId,
  }) async {
    final result = await _storyUseCase.executeAddStoriesToHighlight(
      isLoading: false,
      highlightId: highlightId,
      request: AddStoriesToHighlightRequest(storyIds: [storyId]),
    );
    if (result.isSuccess) {
      final fresh = await getStoryHighlightById(highlightId);
      _notifyHostHighlightsChanged();
      emit(const StoryActionSuccess('add_story_to_highlight'));
      return fresh;
    }
    emit(StoryError(
        result.error?.message ?? 'Unable to add story to highlight.'));
    return null;
  }

  Future<void> deleteStory(String storyId) async {
    final result = await _storyUseCase.executeDeleteStory(
      isLoading: false,
      storyId: storyId,
    );
    if (!result.isSuccess) {
      emit(StoryError(result.error?.message ?? 'Unable to delete story.'));
      return;
    }
    _removeStoryLocally(storyId);
    _emitFeedIfCached();
    emit(const StoryActionSuccess('delete_story'));
  }

  Future<void> removeStoryFromHighlight({
    required String highlightId,
    required String storyId,
  }) async {
    final result = await _storyUseCase.executeRemoveStoryFromHighlight(
      isLoading: false,
      highlightId: highlightId,
      storyId: storyId,
    );
    if (result.isSuccess) {
      _notifyHostHighlightsChanged();
    }
    emit(result.isSuccess
        ? const StoryActionSuccess('remove_story_from_highlight')
        : StoryError(result.error?.message ?? 'Unable to remove story from highlight.'));
  }

  void _notifyHostHighlightsChanged() {
    IsrVideoReelConfig.storyConfig?.storyCallbackConfig.onHighlightsChanged
        ?.call();
  }

  void _removeStoryLocally(String storyId) {
    List<StoryGroup> nextGroups(List<StoryGroup> groups) => groups
        .map((group) => StoryGroup(
              userId: group.userId,
              username: group.username,
              avatarUrl: group.avatarUrl,
              isViewed: group.isViewed,
              stories: group.stories.where((story) => story.id != storyId).toList(),
            ))
        .where((group) => group.stories.isNotEmpty)
        .toList();

    final nextUnViewed = nextGroups(_unViewed);
    final nextViewed = nextGroups(_viewed);

    _unViewed
      ..clear()
      ..addAll(nextUnViewed);
    _viewed
      ..clear()
      ..addAll(nextViewed);
  }
}
