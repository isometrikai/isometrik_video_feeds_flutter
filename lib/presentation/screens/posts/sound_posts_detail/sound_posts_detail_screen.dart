import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Lists posts that use a sound and offers **Use audio** before opening the camera.
class SoundPostsDetailScreen extends StatefulWidget {
  const SoundPostsDetailScreen({
    super.key,
    required this.sound,
    this.sourcePost,
  });

  final PostSoundInfo sound;
  final TimeLineData? sourcePost;

  @override
  State<SoundPostsDetailScreen> createState() => _SoundPostsDetailScreenState();
}

class _SoundPostsDetailScreenState extends State<SoundPostsDetailScreen> {
  final _bloc = IsmInjectionUtils.getBloc<SoundPostsDetailBloc>();
  final _scrollController = ScrollController();
  final List<TimeLineData> _postsList = [];
  final _displaySound = ValueNotifier<PostSoundInfo?>(null);

  late final AudioPlayer _previewPlayer;
  StreamSubscription<PlayerState>? _playerStateSub;

  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _useAudioLoading = false;

  bool _isSaved = false;
  bool _saveLoading = false;
  bool _savedChecked = false;
  SoundLibraryUseCase? _soundUseCase;

  PostSoundInfo get _sound => _displaySound.value ?? widget.sound;

  bool get _apiSoundsMode => SoundLibraryFeatureUtil.useSoundsApi;

  @override
  void initState() {
    super.initState();
    _displaySound.value = widget.sound;
    _previewPlayer = AudioPlayer();
    _playerStateSub = _previewPlayer.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    if (_apiSoundsMode) {
      _soundUseCase = IsmInjectionUtils.getUseCase<SoundLibraryUseCase>();
      unawaited(_refreshSoundMetadata());
      unawaited(_loadSavedState());
    }
    _loadPosts();
    _setupScrollListener();
  }

  Future<void> _refreshSoundMetadata() async {
    final result = await _soundUseCase!.getSoundTrackById(
      isLoading: false,
      soundId: widget.sound.id,
    );
    final track = result.data;
    if (!mounted || track == null) return;
    _displaySound.value = PostSoundInfo(
      id: widget.sound.id,
      title: track.title,
      artist: track.author,
      previewUrl:
          track.trackUrl.isNotEmpty ? track.trackUrl : widget.sound.previewUrl,
      thumbnailUrl: track.thumbnailUrl.isNotEmpty
          ? track.thumbnailUrl
          : widget.sound.thumbnailUrl,
      durationSeconds: track.duration.inSeconds > 0
          ? track.duration.inSeconds.toDouble()
          : widget.sound.durationSeconds,
      usageCount: widget.sound.usageCount,
      snapshot: widget.sound.snapshot,
    );
    setState(() {});
  }

  Future<void> _loadSavedState() async {
    final result = await _soundUseCase!.checkIsSaved(
      isLoading: false,
      soundId: widget.sound.id,
    );
    if (!mounted) return;
    setState(() {
      _isSaved = result.data == true;
      _savedChecked = true;
    });
  }

  Future<void> _toggleSaved() async {
    if (_saveLoading || !_apiSoundsMode) return;
    setState(() => _saveLoading = true);
    final result = await _soundUseCase!.toggleSaved(
      isLoading: true,
      soundId: widget.sound.id,
      currentlySaved: _isSaved,
    );
    if (!mounted) return;
    setState(() {
      _saveLoading = false;
      if (result.data == true) {
        _isSaved = !_isSaved;
      }
    });
    if (result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error?.message ?? IsrTranslationFile.somethingWentWrong,
          ),
        ),
      );
    }
  }

  void _loadPosts() {
    _bloc.add(GetSoundPostsDetailEvent(soundId: widget.sound.id));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;
      final scrollPercentage = _scrollController.position.pixels / max;
      if (scrollPercentage >= 0.65 && !_isLoadingMore && _hasMoreData) {
        _loadMorePosts();
      }
    });
  }

  void _loadMorePosts() {
    if (!mounted || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _bloc.add(
      GetSoundPostsDetailEvent(
        soundId: widget.sound.id,
        isFromPagination: true,
      ),
    );
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    unawaited(_previewPlayer.dispose());
    _scrollController.dispose();
    _displaySound.dispose();
    // Drop grid bitmaps so returning to reels doesn't keep a second image heap.
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  Future<void> _togglePreviewPlayback() async {
    final url = (_sound.previewUrl ?? '').trim();
    if (url.isEmpty) {
      Utility.showToastMessage(IsrTranslationFile.soundPreviewUnavailable);
      return;
    }
    try {
      if (_previewPlayer.state == PlayerState.playing) {
        await _previewPlayer.pause();
      } else {
        await _previewPlayer.play(audioSourceFromUrlOrPath(url));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(IsrTranslationFile.soundPreviewPlayFailed)),
        );
      }
    }
  }

  Future<void> _onUseAudio() async {
    if (_useAudioLoading) return;
    setState(() => _useAudioLoading = true);
    await _previewPlayer.pause();
    IsrVideoReelConfig.suppressPlayback();
    try {
      await UseSoundCaptureCoordinator.startFromPostSound(context, _sound);
    } finally {
      if (mounted) {
        setState(() => _useAudioLoading = false);
        IsrVideoReelConfig.releasePlaybackSuppression();
      }
    }
  }

  String _formatDurationLabel() {
    final seconds = (_sound.durationSeconds ?? 0).round();
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatReelsCount(int count) {
    if (count >= 1000000) {
      final v = count / 1000000;
      return '${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final v = count / 1000;
      return '${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _reelsMetaLabel() {
    final count = _sound.usageCount ?? _postsList.length;
    final reelsLabel = count == 1
        ? IsrTranslationFile.soundDetailReelSingular
        : IsrTranslationFile.soundDetailReelsPlural;
    return '${_formatDurationLabel()} · ${_formatReelsCount(count)} $reelsLabel';
  }

  String _titleLabel() {
    final t = (_sound.title ?? '').trim();
    if (t.isNotEmpty) return t;
    return IsrTranslationFile.soundDetailUntitled;
  }

  String _artistLabel() {
    final a = (_sound.artist ?? '').trim();
    if (a.isNotEmpty) return a;
    return IsrTranslationFile.soundDetailUnknownArtist;
  }

  String _thumbnailUrl() {
    final thumb = (_sound.thumbnailUrl ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    final post = widget.sourcePost;
    if (post?.media?.isNotEmpty == true) {
      final media = post!.media!.first;
      return (media.previewUrl ?? media.url ?? '').toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final playing = _previewPlayer.state == PlayerState.playing;
    final thumbUrl = _thumbnailUrl();

    return Scaffold(
      backgroundColor: IsrColors.white,
      appBar: AppBar(
        backgroundColor: IsrColors.white,
        elevation: 0,
        foregroundColor: IsrColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            await _previewPlayer.pause();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        actions: [
          if (_apiSoundsMode)
            _saveLoading
                ? Padding(
                    padding: EdgeInsets.all(12.responsiveDimension),
                    child: SizedBox(
                      width: 22.responsiveDimension,
                      height: 22.responsiveDimension,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _savedChecked && _isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: _toggleSaved,
                  ),
          // IconButton(
          //   icon: const Icon(Icons.ios_share_outlined),
          //   onPressed: () {
          //     Utility.showToastMessage(IsrTranslationFile.soundDetailShareSoon);
          //   },
          // ),
        ],
      ),
      body: BlocConsumer<SoundPostsDetailBloc, SoundPostsDetailState>(
        bloc: _bloc,
        listener: (context, state) {
          if (!mounted) return;
          if (state is SoundPostsDetailLoadedState ||
              state is SoundPostsDetailErrorState) {
            if (_isLoadingMore) {
              setState(() => _isLoadingMore = false);
            }
            if (state is SoundPostsDetailLoadedState) {
              _hasMoreData = state.hasMoreData;
              _postsList
                ..clear()
                ..addAll(state.posts);
              final count = state.totalPosts ??
                  _sound.usageCount ??
                  (_postsList.isNotEmpty ? _postsList.length : null);
              if (count != null && count != _sound.usageCount) {
                _displaySound.value = PostSoundInfo(
                  id: _sound.id,
                  title: _sound.title,
                  artist: _sound.artist,
                  album: _sound.album,
                  type: _sound.type,
                  usageCount: count,
                  previewUrl: _sound.previewUrl,
                  thumbnailUrl: _sound.thumbnailUrl,
                  durationSeconds: _sound.durationSeconds,
                  snapshot: _sound.snapshot,
                );
              }
            }
          }
        },
        builder: (context, state) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16.responsiveDimension,
                  4.responsiveDimension,
                  16.responsiveDimension,
                  12.responsiveDimension,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildArtwork(thumbUrl, playing),
                    SizedBox(width: 14.responsiveDimension),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleLabel(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: IsrColors.black,
                              fontSize: 17.responsiveDimension,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.responsiveDimension),
                          Text(
                            _artistLabel(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: IsrColors.black.applyOpacity(0.65),
                              fontSize: 14.responsiveDimension,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6.responsiveDimension),
                          Text(
                            _reelsMetaLabel(),
                            style: TextStyle(
                              color: IsrColors.color9B9B9B,
                              fontSize: 13.responsiveDimension,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.responsiveDimension,
                  vertical: 8.responsiveDimension,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.responsiveDimension,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: IsrColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.responsiveDimension),
                      ),
                    ),
                    onPressed: _useAudioLoading ? null : _onUseAudio,
                    child: _useAudioLoading
                        ? SizedBox(
                            width: 22.responsiveDimension,
                            height: 22.responsiveDimension,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: IsrColors.white,
                            ),
                          )
                        : Text(
                            IsrTranslationFile.useAudio,
                            style: TextStyle(
                              fontSize: 15.responsiveDimension,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            _buildPostsContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(String thumbUrl, bool playing) {
    const size = 72.0;
    final artworkSize = size.responsiveDimension;
    return TapHandler(
      onTap: _togglePreviewPlayback,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.responsiveDimension),
        child: SizedBox(
          width: artworkSize,
          height: artworkSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl.isNotEmpty)
                Builder(
                  builder: (context) {
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    final mem = (artworkSize * dpr).round().clamp(64, 256);
                    return AppImage.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      width: artworkSize,
                      height: artworkSize,
                      memCacheWidth: mem,
                      memCacheHeight: mem,
                      filterQuality: FilterQuality.low,
                    );
                  },
                )
              else
                ColoredBox(
                  color: IsrColors.colorF5F5F5,
                  child: Icon(
                    Icons.music_note,
                    color: IsrColors.color9B9B9B,
                    size: 32.responsiveDimension,
                  ),
                ),
              ColoredBox(color: Colors.black.applyOpacity(0.25)),
              Center(
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: IsrColors.white,
                  size: 28.responsiveDimension,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsContent(SoundPostsDetailState state) {
    if (state is SoundPostsDetailLoadingState && state.isLoading) {
      return SliverFillRemaining(
        child: Center(child: Utility.loaderWidget(isAdaptive: false)),
      );
    }
    if (state is SoundPostsDetailErrorState) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.responsiveDimension),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  IsrTranslationFile.somethingWentWrong,
                  style: TextStyle(
                    fontSize: 16.responsiveDimension,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.responsiveDimension),
                TextButton(
                  onPressed: _loadPosts,
                  child: Text(IsrTranslationFile.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_postsList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            IsrTranslationFile.soundDetailNoPosts,
            style: TextStyle(
              color: IsrColors.color9B9B9B,
              fontSize: 15.responsiveDimension,
            ),
          ),
        ),
      );
    }
    return _buildPostsSliverGrid(_postsList);
  }

  Widget _buildPostsSliverGrid(List<TimeLineData> postList) => SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 9 / 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == postList.length) {
              return _isLoadingMore
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Utility.loaderWidget(isAdaptive: false),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            final post = postList[index];
            return TapHandler(
              key: ValueKey('sound_post_${post.id}'),
              onTap: () {
                IsrAppNavigator.navigateToReelsPlayer(
                  context,
                  postDataList: postList,
                  startingPostIndex: index,
                  postSectionType: PostSectionType.singlePost,
                  postId: post.id ?? '',
                );
              },
              child: _buildPostTile(post),
            );
          },
          childCount: postList.length + (_isLoadingMore ? 1 : 0),
          addAutomaticKeepAlives: false,
        ),
      );

  Widget _buildPostTile(TimeLineData post) {
    var coverUrl = '';
    final previews = post.previews;
    if (previews != null && previews.isNotEmpty) {
      coverUrl = previews.first.url ?? '';
    }
    final mediaList = post.media;
    if (coverUrl.isEmptyOrNull && mediaList != null && mediaList.isNotEmpty) {
      final media = mediaList.first;
      coverUrl = media.mediaType?.mediaType == MediaType.video
          ? (media.previewUrl?.toString() ?? '')
          : media.url?.toString() ?? '';
    }

    final isVideo = mediaList != null &&
        mediaList.isNotEmpty &&
        mediaList.first.mediaType?.mediaType == MediaType.video;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // 3-column 9:16 grid — decode at cell size only (not full-res stills).
        final memW =
            (constraints.maxWidth * dpr).round().clamp(64, 360);
        final memH =
            (constraints.maxHeight * dpr).round().clamp(64, 640);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl.isNotEmpty)
              AppImage.network(
                coverUrl,
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                memCacheWidth: memW,
                memCacheHeight: memH,
                filterQuality: FilterQuality.low,
              )
            else
              const ColoredBox(
                color: IsrColors.colorF5F5F5,
                child: Icon(Icons.image, color: IsrColors.color9B9B9B),
              ),
            if (isVideo)
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.videocam,
                  color: IsrColors.white,
                  size: 16.responsiveDimension,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
