import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_theme.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_track_detail_screen.dart';
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

  String _query = '';
  String? _categoryId;
  bool _loading = true;
  String? _error;

  List<SoundTrack> _recent = [];
  List<SoundTrack> _trending = [];
  List<SoundTrack> _recommended = [];
  List<SoundTrack> _saved = [];
  List<SoundTrack> _searchResults = [];
  List<SoundCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _useCase = IsmInjectionUtils.getUseCase<SoundLibraryUseCase>();
    unawaited(_loadSections());
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _openDetail(SoundTrack track) async {
    final pickerOnly = widget.onTrackSelected != null;
    final used = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SoundTrackDetailScreen(
          track: track,
          cameraBloc: widget.cameraBloc,
          useSoundsApi: true,
          pickerOnly: pickerOnly,
        ),
      ),
    );
    if (used == true && mounted) {
      if (pickerOnly) {
        widget.onTrackSelected!(track);
      }
      Navigator.of(context).pop();
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

    return Scaffold(
      backgroundColor: st.scaffoldBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: padTop + 8.responsiveDimension),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.responsiveDimension),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: st.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Sounds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: st.onSurface,
                      fontSize: 18.responsiveDimension,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 48.responsiveDimension),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.responsiveDimension,
              12.responsiveDimension,
              16.responsiveDimension,
              8.responsiveDimension,
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
                prefixIcon: Icon(
                  Icons.search,
                  color: st.onSurfaceSecondary,
                  size: 22.responsiveDimension,
                ),
                filled: true,
                fillColor: st.searchFieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.responsiveDimension),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.responsiveDimension,
                  horizontal: 4.responsiveDimension,
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
                        padding:
                            EdgeInsets.only(bottom: 24.responsiveDimension),
                        children: [
                          if (_categories.isNotEmpty && !searching) ...[
                            const SoundSectionTitle(title: 'Categories'),
                            SizedBox(
                              height: 100.responsiveDimension,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.responsiveDimension,
                                ),
                                itemCount: _categories.length + 1,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 12.responsiveDimension),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final selected = _categoryId == null;
                                    return SoundCategoryChip(
                                      title: 'All',
                                      thumbnailUrl: null,
                                      selected: selected,
                                      onTap: () {
                                      setState(() => _categoryId = null);
                                      if (_query.isNotEmpty) {
                                        unawaited(_runSearch(_query));
                                      }
                                    },
                                    );
                                  }
                                  final c = _categories[index - 1];
                                  final selected = _categoryId == c.id;
                                  return SoundCategoryChip(
                                    title: c.title,
                                    thumbnailUrl: c.thumbnailUrl,
                                    selected: selected,
                                    onTap: () {
                                      setState(
                                        () => _categoryId =
                                            selected ? null : c.id,
                                      );
                                      if (_query.isNotEmpty) {
                                        unawaited(_runSearch(_query));
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8.responsiveDimension),
                          ],
                          if (searching)
                            SoundRowSection(
                              title: 'Results',
                              tracks: recent,
                              onTapTrack: _openDetail,
                            )
                          else ...[
                            SoundRowSection(
                              title: 'Recent',
                              tracks: recent,
                              onTapTrack: _openDetail,
                            ),
                            SoundRowSection(
                              title: 'Trending',
                              tracks: trending,
                              onTapTrack: _openDetail,
                            ),
                            SoundRowSection(
                              title: 'Recommended',
                              tracks: recommended,
                              onTapTrack: _openDetail,
                            ),
                            SoundRowSection(
                              title: 'Saved',
                              tracks: saved,
                              onTapTrack: _openDetail,
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

