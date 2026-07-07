import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_theme.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Live sounds library backed by `/api/v1/sounds/*` (dub / add-sound features).
class SoundSelectionApiBody extends StatefulWidget {
  const SoundSelectionApiBody({
    super.key,
    this.cameraBloc,
    this.onTrackSelected,
  }) : assert(
          cameraBloc != null || onTrackSelected != null,
          'Provide cameraBloc or onTrackSelected',
        );

  final CameraBloc? cameraBloc;
  final void Function(SoundTrack track)? onTrackSelected;

  @override
  State<SoundSelectionApiBody> createState() => _SoundSelectionApiBodyState();
}

class _SoundSelectionApiBodyState extends State<SoundSelectionApiBody> {
  final _searchController = TextEditingController();
  final _debouncer = DeBouncer(duration: const Duration(milliseconds: 400));
  late final SoundLibraryUseCase _useCase;
  AudioPlayer? _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSub;

  String _query = '';
  String? _categoryId;
  String _activeSection = 'all';
  SoundTrack? _activeTrack;
  bool _isPlaying = false;
  bool _loading = true;
  String? _error;

  List<SoundTrack> _recent = [];
  List<SoundTrack> _trending = [];
  List<SoundTrack> _recommended = [];
  List<SoundTrack> _saved = [];
  List<SoundTrack> _searchResults = [];
  List<SoundCategory> _categories = [];
  final Set<String> _savedTrackIds = <String>{};
  final Set<String> _savingTrackIds = <String>{};
  final _listScrollController = ScrollController();
  final _listAnchorKey = GlobalKey();

  int _recentPage = 1;
  int _trendingPage = 1;
  int _recommendedPage = 1;
  int _savedPage = 1;
  bool _recentHasMore = true;
  bool _trendingHasMore = true;
  bool _recommendedHasMore = true;
  bool _savedHasMore = true;
  bool _loadingMore = false;

  Widget _musicThumb(double size) => SoundMusicThumbnail(size: size);

  AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    _playerStateSub ??= _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    return _audioPlayer!;
  }

  @override
  void initState() {
    super.initState();
    _useCase = IsmInjectionUtils.getUseCase<SoundLibraryUseCase>();
    _listScrollController.addListener(_onListScroll);
    // Lazy-create player on first interaction to avoid late-init edge cases.
    unawaited(_loadSections());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    _playerStateSub?.cancel();
    final player = _audioPlayer;
    if (player != null) {
      unawaited(player.dispose());
    }
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _useCase.loadSections(isLoading: false);
    if (!mounted) return;
    if (result.error != null) {
      setState(() {
        _loading = false;
        _error = result.error?.message ?? 'Could not load sounds';
      });
      return;
    }
    final sections = result.data!;
    setState(() {
      _loading = false;
      _recent = sections.recent;
      _trending = sections.trending;
      _recommended = sections.recommended;
      _saved = sections.saved;
      _categories = sections.deriveCategories();
      _savedTrackIds
        ..clear()
        ..addAll(_saved.map((e) => e.id));
      _recentPage = 1;
      _trendingPage = 1;
      _recommendedPage = 1;
      _savedPage = 1;
      _recentHasMore = _recent.length >= 20;
      _trendingHasMore = _trending.length >= 10;
      _recommendedHasMore = _recommended.length >= 10;
      _savedHasMore = _saved.length >= 20;
      _loadingMore = false;
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final categoryIds = _categoryId;
    final result = await _useCase.searchSounds(
      isLoading: false,
      query: query,
      categoryIds: categoryIds,
    );
    if (!mounted) return;
    setState(() => _searchResults = result.data ?? []);
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    _debouncer.run(() => _runSearch(trimmed));
  }

  bool _matchesCategory(SoundTrack t) {
    if (_categoryId == null) return true;
    return t.categoryIds.contains(_categoryId);
  }

  List<SoundTrack> _filter(List<SoundTrack> list) =>
      list.where(_matchesCategory).toList();

  Future<void> _toggleTrackPreview(SoundTrack track) async {
    final previewUrl = track.trackUrl.trim();
    if (previewUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview unavailable for this sound')),
      );
      return;
    }

    if (_activeTrack?.id == track.id) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      return;
    }

    setState(() {
      _activeTrack = track;
      _isPlaying = false;
    });
    try {
      final uri = Uri.tryParse(previewUrl);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        throw FormatException('Invalid preview URL: $previewUrl');
      }
      await _player.stop();
      await _player.setSourceUrl(uri.toString());
      await _player.resume();
    } catch (error, stackTrace) {
      debugPrint('Sound preview failed for $previewUrl');
      debugPrint('Preview error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play preview: $error')),
      );
    }
  }

  Future<void> _switchToSectionAndScroll(String section) async {
    setState(() => _activeSection = section);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final anchorContext = _listAnchorKey.currentContext;
    if (anchorContext != null) {
      await Scrollable.ensureVisible(
        anchorContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  bool _sectionHasMore(String section) => switch (section) {
        'recent' => _recentHasMore,
        'trending' => _trendingHasMore,
        'recommended' => _recommendedHasMore,
        'saved' => _savedHasMore,
        _ => false,
      };

  Future<void> _loadMoreForSection() async {
    final section = _activeSection;
    if (section == 'all' || _loadingMore || !_sectionHasMore(section)) return;
    setState(() => _loadingMore = true);
    const pageSize = 20;
    final nextPage = switch (section) {
      'recent' => _recentPage + 1,
      'trending' => _trendingPage + 1,
      'recommended' => _recommendedPage + 1,
      'saved' => _savedPage + 1,
      _ => 1,
    };
    final result = await _useCase.loadSectionPage(
      isLoading: false,
      section: section,
      page: nextPage,
      pageSize: pageSize,
    );
    if (!mounted) return;
    if (result.error != null) {
      setState(() => _loadingMore = false);
      return;
    }
    final items = result.data ?? const <SoundTrack>[];
    setState(() {
      if (section == 'trending') {
        _trendingPage = nextPage;
        _trendingHasMore = items.length >= pageSize;
        _trending = [..._trending, ...items];
      } else if (section == 'recommended') {
        _recommendedPage = nextPage;
        _recommendedHasMore = items.length >= pageSize;
        _recommended = [..._recommended, ...items];
      } else if (section == 'recent') {
        _recentPage = nextPage;
        _recentHasMore = items.length >= nextPage * pageSize;
        _recent = items;
      } else if (section == 'saved') {
        _savedPage = nextPage;
        _savedHasMore = items.length >= nextPage * pageSize;
        _saved = items;
        _savedTrackIds
          ..clear()
          ..addAll(_saved.map((e) => e.id));
      }
      _loadingMore = false;
    });
  }

  void _onListScroll() {
    if (!_listScrollController.hasClients) return;
    final searching = _query.isNotEmpty;
    if (searching || _activeSection == 'all') return;
    final position = _listScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180.responsiveDimension) {
      unawaited(_loadMoreForSection());
    }
  }

  Widget _buildFullScreenEmptyState(SoundPickerTheme st) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.responsiveDimension),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_off_rounded,
                color: st.onSurfaceSecondary,
                size: 34.responsiveDimension,
              ),
              SizedBox(height: 10.responsiveDimension),
              Text(
                'No sounds found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: st.onSurface,
                  fontSize: 16.responsiveDimension,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.responsiveDimension),
              Text(
                'Try a different tab, category, or search keyword.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: st.onSurfaceSecondary,
                  fontSize: 13.responsiveDimension,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _toggleMiniPlayerPlayback() async {
    if (_activeTrack == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _useSelectedSound() async {
    final track = _activeTrack;
    if (track == null) return;
    await _player.pause();
    if (!mounted) return;
    if (widget.onTrackSelected != null) {
      // Caller owns navigation (e.g. [SoundLibraryPickerScreen] pops with result).
      widget.onTrackSelected!(track);
      return;
    }
    widget.cameraBloc?.add(
      CameraSetMusicEvent(
        musicId: track.id,
        musicName: track.title,
        musicArtist: track.author,
        musicThumbnailUrl: track.thumbnailUrl,
        musicDurationSeconds: track.duration.inSeconds,
        musicPreviewUrl: track.trackUrl,
      ),
    );
    Navigator.of(context).pop();
  }

  bool _isTrackSaved(String trackId) => _savedTrackIds.contains(trackId);

  bool _isTrackSaveLoading(String trackId) => _savingTrackIds.contains(trackId);

  Future<void> _toggleSavedTrack(SoundTrack track) async {
    if (_savingTrackIds.contains(track.id)) return;
    final currentlySaved = _savedTrackIds.contains(track.id);
    setState(() => _savingTrackIds.add(track.id));
    final result = await _useCase.toggleSaved(
      isLoading: false,
      soundId: track.id,
      currentlySaved: currentlySaved,
    );
    if (!mounted) return;
    setState(() {
      _savingTrackIds.remove(track.id);
      if (result.data == true) {
        if (currentlySaved) {
          _savedTrackIds.remove(track.id);
          _saved.removeWhere((s) => s.id == track.id);
        } else {
          _savedTrackIds.add(track.id);
          if (!_saved.any((s) => s.id == track.id)) {
            _saved = [track, ..._saved];
          }
        }
      }
    });
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.error?.message ?? 'Could not update saved sound'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    final st = SoundPickerTheme.of(context);
    final searching = _query.isNotEmpty;

    final recent = searching ? _filter(_searchResults) : _filter(_recent);
    final trending = searching ? <SoundTrack>[] : _filter(_trending);
    final recommended = searching ? <SoundTrack>[] : _filter(_recommended);
    final saved = searching ? <SoundTrack>[] : _filter(_saved);
    final showRecentInAll = _activeSection == 'all' && recent.isNotEmpty;
    final showTrendingInAll = _activeSection == 'all' && trending.isNotEmpty;
    final showRecommendedInAll =
        _activeSection == 'all' && recommended.isNotEmpty;
    final showSavedInAll = _activeSection == 'all' && saved.isNotEmpty;
    final anySectionVisibleInAll = showRecentInAll ||
        showTrendingInAll ||
        showRecommendedInAll ||
        showSavedInAll;
    final selectedTabTracks = switch (_activeSection) {
      'recent' => recent,
      'trending' => trending,
      'recommended' => recommended,
      'saved' => saved,
      _ => const <SoundTrack>[],
    };
    final showFullScreenEmpty = searching
        ? recent.isEmpty
        : (_activeSection == 'all'
            ? !anySectionVisibleInAll
            : selectedTabTracks.isEmpty);

    return Scaffold(
      backgroundColor: st.scaffoldBackground,
      bottomNavigationBar: _activeTrack == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16.responsiveDimension,
                  6.responsiveDimension,
                  16.responsiveDimension,
                  8.responsiveDimension,
                ),
                child: Container(
                  height: 58.responsiveDimension,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.responsiveDimension),
                  decoration: BoxDecoration(
                    color: st.selectionAccent,
                    borderRadius: BorderRadius.circular(14.responsiveDimension),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8.responsiveDimension),
                        child: isLikelyImageUrl(_activeTrack!.thumbnailUrl)
                            ? AppImage.network(
                                _activeTrack!.thumbnailUrl,
                                width: 36.responsiveDimension,
                                height: 36.responsiveDimension,
                                fit: BoxFit.cover,
                                placeHolderWidget: (_, __) =>
                                    _musicThumb(36.responsiveDimension),
                              )
                            : _musicThumb(36.responsiveDimension),
                      ),
                      SizedBox(width: 8.responsiveDimension),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeTrack!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.responsiveDimension,
                              ),
                            ),
                            Text(
                              '${_activeTrack!.author} \u00b7 ${_activeTrack!.duration.inMinutes}:${(_activeTrack!.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13.responsiveDimension,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleMiniPlayerPlayback,
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22.responsiveDimension,
                        ),
                      ),
                      TapHandler(
                        onTap: _useSelectedSound,
                        child: CircleAvatar(
                          radius: 16.responsiveDimension,
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: st.selectionAccent,
                            size: 20.responsiveDimension,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: padTop + 8.responsiveDimension),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.responsiveDimension),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: st.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 2.responsiveDimension),
                Expanded(
                  child: Text(
                    'Music',
                    style: TextStyle(
                      color: st.onSurface,
                      fontSize: 18.responsiveDimension,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.responsiveDimension,
              12.responsiveDimension,
              16.responsiveDimension,
              12.responsiveDimension,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: st.onSurface,
                fontSize: 15.responsiveDimension,
              ),
              cursorColor: st.cursor,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search sounds, artists, albums',
                hintStyle: TextStyle(
                  color: st.onSurfaceHint,
                  fontSize: 15.responsiveDimension,
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  color: st.onSurfaceSecondary,
                  size: 20.responsiveDimension,
                ),
                filled: true,
                fillColor: st.searchFieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.responsiveDimension),
                  borderSide: BorderSide(color: st.chipBorderUnselected),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.responsiveDimension),
                  borderSide: BorderSide(color: st.chipBorderUnselected),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.responsiveDimension),
                  borderSide: BorderSide(color: st.selectionAccent),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 11.responsiveDimension,
                  horizontal: 14.responsiveDimension,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: st.selectionAccent),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.responsiveDimension),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: st.onSurfaceSecondary),
                              ),
                              SizedBox(height: 16.responsiveDimension),
                              TextButton(
                                onPressed: _loadSections,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        controller: _listScrollController,
                        padding:
                            EdgeInsets.only(bottom: 24.responsiveDimension),
                        children: [
                          if (_categories.isNotEmpty && !searching) ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                16.responsiveDimension,
                                2.responsiveDimension,
                                16.responsiveDimension,
                                10.responsiveDimension,
                              ),
                              child: Text(
                                'BROWSE CATEGORIES',
                                style: TextStyle(
                                  color: st.onSurfaceSecondary,
                                  fontSize: 11.responsiveDimension,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SoundCategoriesStrip(
                              categories: _categories,
                              selectedCategoryId: _categoryId,
                              onTapCategory: (c) {
                                final selected = _categoryId == c.id;
                                setState(
                                    () => _categoryId = selected ? null : c.id);
                                if (_query.isNotEmpty) {
                                  unawaited(_runSearch(_query));
                                }
                              },
                            ),
                            SizedBox(height: 10.responsiveDimension),
                            SizedBox(
                              height: 34.responsiveDimension,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.responsiveDimension,
                                ),
                                itemBuilder: (context, i) {
                                  final item = [
                                    'all',
                                    'saved',
                                    'recent',
                                    'trending',
                                    'recommended',
                                  ][i];
                                  final label = [
                                    'All',
                                    'Saved',
                                    'Recent',
                                    'Trending',
                                    'Recommended',
                                  ][i];
                                  return SoundFilterChip(
                                    title: label,
                                    selected: _activeSection == item,
                                    onTap: () =>
                                        setState(() => _activeSection = item),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 8.responsiveDimension),
                                itemCount: 5,
                              ),
                            ),
                            SizedBox(height: 8.responsiveDimension),
                          ],
                          SizedBox(key: _listAnchorKey),
                          if (showFullScreenEmpty)
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.42,
                              child: _buildFullScreenEmptyState(st),
                            ),
                          if (searching)
                            if (!showFullScreenEmpty)
                              SoundListSection(
                                title: 'Results',
                                tracks: recent,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                              ),
                          if (!searching) ...[
                            if (showRecentInAll && !showFullScreenEmpty)
                              SoundListSection(
                                title: 'Recent',
                                tracks: recent,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                                collapsedLimit:
                                    _activeSection == 'all' ? 3 : null,
                                onViewAll: _activeSection == 'all'
                                    ? () => _switchToSectionAndScroll('recent')
                                    : null,
                              ),
                            if (showTrendingInAll && !showFullScreenEmpty)
                              SoundListSection(
                                title: 'Trending Songs',
                                tracks: trending,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                                collapsedLimit:
                                    _activeSection == 'all' ? 3 : null,
                                onViewAll: _activeSection == 'all'
                                    ? () =>
                                        _switchToSectionAndScroll('trending')
                                    : null,
                              ),
                            if (showRecommendedInAll && !showFullScreenEmpty)
                              SoundListSection(
                                title: 'Recommended',
                                tracks: recommended,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                                collapsedLimit:
                                    _activeSection == 'all' ? 3 : null,
                                onViewAll: _activeSection == 'all'
                                    ? () =>
                                        _switchToSectionAndScroll('recommended')
                                    : null,
                              ),
                            if (showSavedInAll && !showFullScreenEmpty)
                              SoundListSection(
                                title: 'Saved',
                                tracks: saved,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                                collapsedLimit:
                                    _activeSection == 'all' ? 3 : null,
                                onViewAll: _activeSection == 'all'
                                    ? () => _switchToSectionAndScroll('saved')
                                    : null,
                              ),
                            if (_activeSection != 'all' &&
                                !showFullScreenEmpty &&
                                selectedTabTracks.isNotEmpty)
                              SoundListSection(
                                title: _activeSection == 'recent'
                                    ? 'Recent'
                                    : _activeSection == 'trending'
                                        ? 'Trending Songs'
                                        : _activeSection == 'recommended'
                                            ? 'Recommended'
                                            : 'Saved',
                                tracks: selectedTabTracks,
                                onTapTrack: _toggleTrackPreview,
                                isTrackSaved: _isTrackSaved,
                                isTrackSaveLoading: _isTrackSaveLoading,
                                onToggleSave: _toggleSavedTrack,
                                activeTrackId: _activeTrack?.id,
                              ),
                            if (_activeSection != 'all' && _loadingMore)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16.responsiveDimension,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 22.responsiveDimension,
                                    height: 22.responsiveDimension,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: st.selectionAccent,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
