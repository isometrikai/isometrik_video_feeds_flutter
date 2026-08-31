import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ism_video_reel_player/core/errors/app_error.dart';
import 'package:ism_video_reel_player/core/errors/error_handler.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/media_compressor.dart';
import 'package:ism_video_reel_player/utils/media_util.dart';
import 'package:ism_video_reel_player/utils/post_review_status_util.dart';
import 'package:ism_video_reel_player/utils/utility.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Progress updates while resubmitting a rejected post from the details sheet.
class RejectedPostResubmitProgress {
  const RejectedPostResubmitProgress({
    required this.phase,
    this.fraction = 0,
    this.message,
  });

  final RejectedPostResubmitPhase phase;
  final double fraction;
  final String? message;
}

enum RejectedPostResubmitPhase {
  uploading,
  creating,
  processing,
  deleting,
  refreshing,
}

class RejectedPostResubmitResult {
  const RejectedPostResubmitResult({
    required this.success,
    this.newPostId,
    this.error,
  });

  final bool success;
  final String? newPostId;
  final AppError? error;
}

/// Uploads replaced media, creates a new post, and deletes the rejected post.
class RejectedPostResubmitService {
  RejectedPostResubmitService({
    CreatePostUseCase? createPostUseCase,
    DeletePostUseCase? deletePostUseCase,
    GoogleCloudStorageUploaderUseCase? uploaderUseCase,
    IsmLocalDataUseCase? localDataUseCase,
    MediaProcessingUseCase? mediaProcessingUseCase,
  })  : _createPostUseCase =
            createPostUseCase ?? IsmInjectionUtils.getUseCase<CreatePostUseCase>(),
        _deletePostUseCase =
            deletePostUseCase ?? IsmInjectionUtils.getUseCase<DeletePostUseCase>(),
        _uploaderUseCase = uploaderUseCase ??
            IsmInjectionUtils.getUseCase<GoogleCloudStorageUploaderUseCase>(),
        _localDataUseCase =
            localDataUseCase ?? IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>(),
        _mediaProcessingUseCase = mediaProcessingUseCase ??
            IsmInjectionUtils.getUseCase<MediaProcessingUseCase>();

  final CreatePostUseCase _createPostUseCase;
  final DeletePostUseCase _deletePostUseCase;
  final GoogleCloudStorageUploaderUseCase _uploaderUseCase;
  final IsmLocalDataUseCase _localDataUseCase;
  final MediaProcessingUseCase _mediaProcessingUseCase;

  Future<RejectedPostResubmitResult> submit({
    required TimeLineData sourcePost,
    required List<PostReviewMediaItem> mediaItems,
    String? caption,
    Tags? tags,
    Settings? settings,
    void Function(RejectedPostResubmitProgress progress)? onProgress,
  }) async {
    final oldPostId = sourcePost.id ?? '';
    if (oldPostId.isEmpty) {
      return const RejectedPostResubmitResult(success: false);
    }

    final included = mediaItems
        .where((item) => item.isApproved || item.isReplaced)
        .toList()
      ..sort((a, b) => a.mediaNumber.compareTo(b.mediaNumber));
    if (included.isEmpty) {
      return const RejectedPostResubmitResult(success: false);
    }

    final sourceMedia = sourcePost.media ?? [];
    final uploadsNeeded = included
        .where((item) => item.isReplaced && item.replacementLocalPath?.isNotEmpty == true)
        .length;
    var completedUploads = 0;
    var hasNewUploads = false;

    void reportUpload(String name, {double fraction = 0}) {
      onProgress?.call(
        RejectedPostResubmitProgress(
          phase: RejectedPostResubmitPhase.uploading,
          fraction: uploadsNeeded == 0
              ? 1
              : (completedUploads + fraction).clamp(0.0, 1.0) / uploadsNeeded,
          message: name,
        ),
      );
    }

    final builtMedia = <MediaData>[];
    final positionMap = <int, int>{};
    var newPosition = 1;

    for (final item in included) {
      if (item.isReplaced) {
        final localPath = item.replacementLocalPath?.trim();
        if (localPath == null || localPath.isEmpty) {
          return RejectedPostResubmitResult(
            success: false,
            error: AppError(IsrTranslationFile.somethingWentWrong),
          );
        }
        if (!await File(localPath).exists()) {
          return RejectedPostResubmitResult(
            success: false,
            error: AppError(IsrTranslationFile.somethingWentWrong),
          );
        }

        reportUpload(
          item.isVideo
              ? IsrTranslationFile.uploadingVideo
              : IsrTranslationFile.uploadingImage,
        );
        final uploaded = await _uploadReplacement(
          localPath: localPath,
          isVideo: item.isVideo,
          index: item.sourceIndex,
          onBytesProgress: (progress) => reportUpload(
            item.isVideo
                ? IsrTranslationFile.uploadingVideo
                : IsrTranslationFile.uploadingImage,
            fraction: progress,
          ),
        );
        if (uploaded == null || !_isRemoteMediaUrl(uploaded.url)) {
          return RejectedPostResubmitResult(
            success: false,
            error: AppError(IsrTranslationFile.somethingWentWrong),
          );
        }
        if (item.isVideo && !_isRemoteMediaUrl(uploaded.previewUrl)) {
          return RejectedPostResubmitResult(
            success: false,
            error: AppError(IsrTranslationFile.somethingWentWrong),
          );
        }

        completedUploads++;
        hasNewUploads = true;
        positionMap[item.mediaNumber] = newPosition;
        builtMedia.add(
          MediaData(
            mediaType: item.isVideo ? 'video' : 'image',
            position: newPosition,
            url: uploaded.url,
            previewUrl: uploaded.previewUrl ?? uploaded.url,
            width: uploaded.width,
            height: uploaded.height,
            duration: uploaded.duration,
          ),
        );
        newPosition++;
        continue;
      }

      if (!item.isApproved ||
          item.sourceIndex < 0 ||
          item.sourceIndex >= sourceMedia.length) {
        continue;
      }

      final source = sourceMedia[item.sourceIndex];
      if (!PostReviewStatusUtil.isMediaApprovedForResubmit(source, sourcePost)) {
        continue;
      }
      if (!_isRemoteMediaUrl(source.url)) {
        return RejectedPostResubmitResult(
          success: false,
          error: AppError(IsrTranslationFile.somethingWentWrong),
        );
      }
      if (_isVideoMedia(source) && !_isRemoteMediaUrl(source.previewUrl)) {
        return RejectedPostResubmitResult(
          success: false,
          error: AppError(IsrTranslationFile.somethingWentWrong),
        );
      }

      positionMap[item.mediaNumber] = newPosition;
      builtMedia.add(_copyApprovedMedia(source, newPosition));
      newPosition++;
    }

    if (builtMedia.isEmpty) {
      return const RejectedPostResubmitResult(success: false);
    }

    for (final media in builtMedia) {
      if (!_isRemoteMediaUrl(media.url)) {
        return RejectedPostResubmitResult(
          success: false,
          error: AppError(IsrTranslationFile.somethingWentWrong),
        );
      }
      if (_isVideoMedia(media) && !_isRemoteMediaUrl(media.previewUrl)) {
        return RejectedPostResubmitResult(
          success: false,
          error: AppError(IsrTranslationFile.somethingWentWrong),
        );
      }
    }

    onProgress?.call(
      const RejectedPostResubmitProgress(
        phase: RejectedPostResubmitPhase.creating,
        fraction: 1,
      ),
    );

    final payload = _buildCreatePayload(
      sourcePost: sourcePost,
      media: builtMedia,
      positionMap: positionMap,
      hasNewUploads: hasNewUploads,
      caption: caption,
      tags: tags,
      settings: settings,
    );

    final createResult = await _createPostUseCase.executeCreatePost(
      isLoading: true,
      createPostRequest: payload,
    );
    if (!createResult.isSuccess) {
      return RejectedPostResubmitResult(
        success: false,
        error: createResult.error,
      );
    }

    final newPostId = createResult.data?.data?.id ?? '';

    if (hasNewUploads && newPostId.isNotEmpty) {
      onProgress?.call(
        const RejectedPostResubmitProgress(
          phase: RejectedPostResubmitPhase.processing,
          fraction: 1,
        ),
      );
      final processResult = await _mediaProcessingUseCase.executeMediaProcessing(
        isLoading: false,
        postId: newPostId,
      );
      if (!processResult.isSuccess) {
        ErrorHandler.showAppError(
          appError: processResult.error,
          isNeedToShowError: true,
        );
      }
    }

    onProgress?.call(
      const RejectedPostResubmitProgress(
        phase: RejectedPostResubmitPhase.deleting,
        fraction: 1,
      ),
    );

    final deleteResult = await _deletePostUseCase.executeDeletePost(
      isLoading: false,
      postId: oldPostId,
    );
    if (!deleteResult.isSuccess) {
      ErrorHandler.showAppError(
        appError: deleteResult.error,
        isNeedToShowError: true,
      );
    } else {
      IsrVideoReelConfig.socialActionCubit.onPostDeleted(postId: oldPostId);
    }

    onProgress?.call(
      const RejectedPostResubmitProgress(
        phase: RejectedPostResubmitPhase.refreshing,
        fraction: 1,
      ),
    );

    final userId = await _localDataUseCase.getUserId();
    if (userId.isNotEmpty) {
      await IsrVideoReelConfig.socialActionCubit.refreshCurrentUserPosts(
        userId: userId,
        isLoading: false,
      );
    }

    IsrVideoReelConfig.socialActionCubit.onPostCreated(postId: newPostId);

    return RejectedPostResubmitResult(
      success: true,
      newPostId: newPostId,
    );
  }

  bool _isRemoteMediaUrl(String? url) {
    final trimmed = (url ?? '').trim();
    return trimmed.isNotEmpty && !Utility.isLocalUrl(trimmed);
  }

  MediaData _copyApprovedMedia(MediaData source, int position) => MediaData(
        mediaType: source.mediaType,
        position: position,
        url: source.url,
        previewUrl: source.previewUrl?.isNotEmpty == true
            ? source.previewUrl
            : source.url,
        width: source.width,
        height: source.height,
        duration: source.duration,
        moderationResult: source.moderationResult,
      );

  Map<String, dynamic> _buildCreatePayload({
    required TimeLineData sourcePost,
    required List<MediaData> media,
    required Map<int, int> positionMap,
    required bool hasNewUploads,
    String? caption,
    Tags? tags,
    Settings? settings,
  }) {
    final resolvedSettings = settings ?? sourcePost.settings;
    final postType = media.length > 1
        ? SocialPostType.carousel
        : _isVideoMedia(media.first)
            ? SocialPostType.video
            : SocialPostType.image;

    final request = CreatePostRequest(
      caption: caption ?? sourcePost.caption,
      media: media,
      tags: _filteredTags(tags ?? sourcePost.tags, positionMap),
      type: postType,
      visibility: SocialPostVisibility.public,
      settings: resolvedSettings == null
          ? null
          : PostSettingModel(
              advanceInterval: resolvedSettings.advanceInterval,
              ageRestriction: resolvedSettings.ageRestriction,
              autoAdvance: resolvedSettings.autoAdvance,
              commentsEnabled: resolvedSettings.commentsEnabled,
              duetEnabled: resolvedSettings.duetEnabled,
              saveEnabled: resolvedSettings.saveEnabled,
              downloadEnabled: resolvedSettings.downloadEnabled,
              stitchEnabled: resolvedSettings.stitchEnabled,
              isPaid: resolvedSettings.isPaid,
              priceAmount: resolvedSettings.priceAmount,
              priceCurrency: resolvedSettings.priceCurrency,
            ),
      previews: _resolvePreviews(sourcePost, media),
    );

    final payload = Map<String, dynamic>.from(request.toJson());
    payload.remove('id');
    payload['visibility'] = SocialPostVisibility.public;

    if (payload['media'] is List) {
      payload['media'] = (payload['media'] as List)
          .map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            map.remove('asset_id');
            if (hasNewUploads) {
              final url = (map['url'] as String?)?.trim() ?? '';
              final isNewUpload = media.any(
                (item) =>
                    item.url?.trim() == url &&
                    (item.assetId == null || item.assetId!.isEmpty),
              );
              if (isNewUpload) {
                map.remove('moderation_result');
              }
            }
            return map;
          })
          .toList();
    }

    final soundId = sourcePost.soundId?.trim();
    if (soundId != null && soundId.isNotEmpty) {
      payload['sound_id'] = soundId;
    }
    final snapshot = sourcePost.soundSnapshot;
    if (snapshot is Map<String, dynamic> && snapshot.isNotEmpty) {
      payload['sound_snapshot'] = Map<String, dynamic>.from(snapshot);
    } else if (snapshot is Map && snapshot.isNotEmpty) {
      payload['sound_snapshot'] = Map<String, dynamic>.from(snapshot);
    }

    return payload;
  }

  Tags? _filteredTags(Tags? tags, Map<int, int> positionMap) {
    if (tags == null) return null;
    final copy = Tags(
      mentions: List<MentionData>.from(tags.mentions ?? []),
      hashtags: List<MentionData>.from(tags.hashtags ?? []),
      places: List<TaggedPlace>.from(tags.places ?? []),
      products: List<SocialProductData>.from(tags.products ?? []),
      links: List<PostLinkData>.from(tags.links ?? []),
    );

    copy.mentions = copy.mentions?.where((mention) {
      final mediaPos = mention.mediaPosition?.position?.toInt();
      if (mediaPos == null || mediaPos <= 0) return true;
      return positionMap.containsKey(mediaPos);
    }).toList();
    for (final mention in copy.mentions ?? <MentionData>[]) {
      final mediaPos = mention.mediaPosition?.position?.toInt();
      if (mediaPos == null || mediaPos <= 0) continue;
      final mapped = positionMap[mediaPos];
      if (mapped != null) {
        mention.mediaPosition!.position = mapped;
      }
    }

    copy.products = copy.products?.where((product) {
      final mediaPos = product.mediaPosition?.mediaPosition?.toInt();
      if (mediaPos == null || mediaPos <= 0) return true;
      return positionMap.containsKey(mediaPos);
    }).toList();
    for (final product in copy.products ?? <SocialProductData>[]) {
      final mediaPos = product.mediaPosition?.mediaPosition?.toInt();
      if (mediaPos == null || mediaPos <= 0) continue;
      final mapped = positionMap[mediaPos];
      if (mapped != null) {
        product.mediaPosition!.mediaPosition = mapped;
      }
    }

    copy.links = copy.links?.where((link) {
      final mediaPos = link.mediaPosition?.position?.toInt();
      if (mediaPos == null || mediaPos <= 0) return true;
      return positionMap.containsKey(mediaPos);
    }).toList();
    for (final link in copy.links ?? <PostLinkData>[]) {
      final mediaPos = link.mediaPosition?.position?.toInt();
      if (mediaPos == null || mediaPos <= 0) continue;
      final mapped = positionMap[mediaPos];
      if (mapped != null) {
        link.mediaPosition!.position = mapped;
      }
    }

    return copy;
  }

  List<PreviewMedia>? _resolvePreviews(TimeLineData sourcePost, List<MediaData> media) {
    final first = media.isNotEmpty ? media.first : null;
    if (first == null) return null;

    final thumb = _isVideoMedia(first)
        ? (first.previewUrl?.isNotEmpty == true ? first.previewUrl : first.url)
        : first.url;
    if (thumb?.isNotEmpty != true) return null;

    return [
      PreviewMedia(
        mediaType: 'image',
        position: 1,
        url: thumb,
      ),
    ];
  }

  bool _isVideoMedia(MediaData media) {
    if ((media.mediaType ?? '').toLowerCase().trim() == 'video') return true;
    return media.postType == PostType.video;
  }

  Future<MediaData?> _uploadReplacement({
    required String localPath,
    required bool isVideo,
    required int index,
    required void Function(double progress) onBytesProgress,
  }) async {
    var file = File(localPath);
    if (!await file.exists()) return null;

    if (IsrAppConstants.isCompressionEnable) {
      final compressed = await MediaCompressor.compressMedia(
        file,
        isVideo: isVideo,
        onProgress: (_) {},
      );
      if (compressed != null) {
        file = compressed;
      }
    }

    final userId = await _localDataUseCase.getUserId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = isVideo ? 'upload_video' : 'upload_image';
    final fileName = '${prefix}_media_${index}_$timestamp';
    final extension = path.extension(localPath);
    final folder = isVideo
        ? IsrAppConstants.cloudinaryVideoFolder
        : IsrAppConstants.cloudinaryImageFolder;

    onBytesProgress(0);
    final uploadedUrl = await _uploadFile(
      file: file,
      fileName: fileName,
      fileExtension: extension,
      userId: userId,
      folderName: folder,
      onProgress: onBytesProgress,
    );
    if (uploadedUrl.isEmpty) return null;

    if (!isVideo) {
      return MediaData(
        mediaType: 'image',
        url: uploadedUrl,
        previewUrl: uploadedUrl,
      );
    }

    final previewUrl = await _uploadVideoThumbnail(
      videoPath: file.path,
      index: index,
      userId: userId,
      onProgress: onBytesProgress,
    );
    if (previewUrl == null || previewUrl.isEmpty) return null;

    return MediaData(
      mediaType: 'video',
      url: uploadedUrl,
      previewUrl: previewUrl,
    );
  }

  Future<String?> _uploadVideoThumbnail({
    required String videoPath,
    required int index,
    required String userId,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await MediaUtil.pickBestVideoThumbnailPath(
        videoPath: videoPath,
        thumbnailPath: tempDir.path,
        quality: 50,
      );
      if (thumbPath == null || thumbPath.isEmpty) return null;

      final thumbFile = File(thumbPath);
      if (!await thumbFile.exists()) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploaded = await _uploadFile(
        file: thumbFile,
        fileName: 'upload_image_thumb_${index}_$timestamp',
        fileExtension: path.extension(thumbPath).isNotEmpty
            ? path.extension(thumbPath)
            : '.jpg',
        userId: userId,
        folderName: IsrAppConstants.cloudinaryImageFolder,
        onProgress: onProgress,
      );
      return uploaded.isEmpty ? null : uploaded;
    } catch (e) {
      debugPrint('RejectedPostResubmitService thumbnail upload error: $e');
      return null;
    }
  }

  Future<String> _uploadFile({
    required File file,
    required String fileName,
    required String fileExtension,
    required String userId,
    required String folderName,
    required void Function(double progress) onProgress,
  }) async {
    final customUpload =
        IsrVideoReelConfig.socialConfig.socialCallBackConfig?.uploadMediaToCloud;
    String result;
    if (customUpload != null) {
      try {
        result = await customUpload(
          file,
          fileName,
          folderName.contains('video') ? MediaType.video : MediaType.photo,
          (value) {
            final normalized = value > 1 ? value / 100 : value;
            onProgress(normalized);
          },
          folderName,
          fileExtension,
        );
      } catch (e) {
        debugPrint('RejectedPostResubmitService custom upload error: $e');
        result = '';
      }
    } else {
      try {
        result = await _uploaderUseCase.executeGoogleCloudStorageUploader(
              file: file,
              fileName: fileName,
              fileExtension: fileExtension,
              userId: userId,
              cloudFolderName: folderName,
              onProgress: (value) => onProgress(value),
            ) ??
            '';
      } catch (e) {
        debugPrint('RejectedPostResubmitService upload error: $e');
        result = '';
      }
    }
    return _applyConvertToGumletUrl(result);
  }

  String _applyConvertToGumletUrl(String mediaUrl) {
    if (mediaUrl.isEmpty) return mediaUrl;
    final convert = IsrVideoReelConfig.socialConfig.socialCallBackConfig?.convertToGumletUrl;
    if (convert == null) return mediaUrl;
    try {
      final converted = convert(mediaUrl);
      if (converted.isNotEmpty) return converted;
    } catch (e) {
      debugPrint('RejectedPostResubmitService convertToGumletUrl error: $e');
    }
    return mediaUrl;
  }
}
