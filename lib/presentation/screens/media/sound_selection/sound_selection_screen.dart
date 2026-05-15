import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_library_mock_data.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_theme.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_track_detail_screen.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Sound picker: search, categories, recent / trending / recommended / saved.
class SoundSelectionScreen extends StatefulWidget {
  const SoundSelectionScreen({
    super.key,
    required this.cameraBloc,
    this.restrictedTracks,
  });

  final CameraBloc cameraBloc;
  /// When non-null, only these tracks are shown (e.g. one extracted dub stem).
  final List<SoundTrack>? restrictedTracks;

  @override
  State<SoundSelectionScreen> createState() => _SoundSelectionScreenState();
}

class _SoundSelectionScreenState extends State<SoundSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(SoundTrack t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        t.author.toLowerCase().contains(q) ||
        (t.lyricsSnippet?.toLowerCase().contains(q) ?? false);
  }

  bool _matchesCategory(SoundTrack t) {
    if (_categoryId == null) return true;
    return t.categoryIds.contains(_categoryId);
  }

  List<SoundTrack> _filter(List<SoundTrack> list) =>
      list.where((t) => _matchesQuery(t) && _matchesCategory(t)).toList();

  Future<void> _openDetail(SoundTrack track) async {
    final used = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SoundTrackDetailScreen(
          track: track,
          cameraBloc: widget.cameraBloc,
        ),
      ),
    );
    if (used == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final restricted = widget.restrictedTracks;
    if (restricted != null && restricted.isNotEmpty) {
      return _RestrictedSoundPickerBody(
        tracks: restricted,
        cameraBloc: widget.cameraBloc,
      );
    }

    final padTop = MediaQuery.paddingOf(context).top;
    final st = SoundPickerTheme.of(context);
    final recent = _filter(SoundLibraryMockData.recent);
    final trending = _filter(SoundLibraryMockData.trending);
    final recommended = _filter(SoundLibraryMockData.recommended);
    final saved = _filter(SoundLibraryMockData.saved);

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
              onChanged: (v) => setState(() => _query = v.trim()),
              style: TextStyle(
                color: st.onSurface,
                fontSize: 15.responsiveDimension,
              ),
              cursorColor: st.cursor,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search sounds, artists, lyrics',
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
            child: ListView(
              padding: EdgeInsets.only(bottom: 24.responsiveDimension),
              children: [
                _SectionTitle(title: 'Categories'),
                SizedBox(
                  height: 100.responsiveDimension,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.responsiveDimension,
                    ),
                    itemCount: SoundLibraryMockData.categories.length + 1,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: 12.responsiveDimension),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final selected = _categoryId == null;
                        return _CategoryChip(
                          title: 'All',
                          thumbnailUrl: null,
                          selected: selected,
                          onTap: () => setState(() => _categoryId = null),
                        );
                      }
                      final c =
                          SoundLibraryMockData.categories[index - 1];
                      final selected = _categoryId == c.id;
                      return _CategoryChip(
                        title: c.title,
                        thumbnailUrl: c.thumbnailUrl,
                        selected: selected,
                        onTap: () =>
                            setState(() => _categoryId = selected ? null : c.id),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8.responsiveDimension),
                _SoundRowSection(
                  title: 'Recent',
                  tracks: recent,
                  onTapTrack: _openDetail,
                ),
                _SoundRowSection(
                  title: 'Trending',
                  tracks: trending,
                  onTapTrack: _openDetail,
                ),
                _SoundRowSection(
                  title: 'Recommended',
                  tracks: recommended,
                  onTapTrack: _openDetail,
                ),
                _SoundRowSection(
                  title: 'Saved',
                  tracks: saved,
                  onTapTrack: _openDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final st = SoundPickerTheme.of(context);
    return Padding(
        padding: EdgeInsets.fromLTRB(
          16.responsiveDimension,
          16.responsiveDimension,
          16.responsiveDimension,
          10.responsiveDimension,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: st.onSurface,
            fontSize: 17.responsiveDimension,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.selected,
    required this.onTap,
    this.thumbnailUrl,
  });

  final String title;
  final String? thumbnailUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = SoundPickerTheme.of(context);
    return TapHandler(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.responsiveDimension,
              height: 64.responsiveDimension,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.responsiveDimension),
                border: Border.all(
                  color: selected
                      ? st.selectionAccent
                      : st.chipBorderUnselected,
                  width: selected ? 2 : 1,
                ),
                color: st.chipSurface,
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnailUrl == null
                  ? Icon(
                      Icons.grid_view_rounded,
                      color: st.onSurfaceSecondary,
                      size: 28.responsiveDimension,
                    )
                  : AppImage.network(
                      thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
            SizedBox(height: 6.responsiveDimension),
            SizedBox(
              width: 72.responsiveDimension,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? st.selectionAccent : st.onSurfaceSecondary,
                  fontSize: 12.responsiveDimension,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _SoundRowSection extends StatelessWidget {
  const _SoundRowSection({
    required this.title,
    required this.tracks,
    required this.onTapTrack,
  });

  final String title;
  final List<SoundTrack> tracks;
  final Future<void> Function(SoundTrack) onTapTrack;

  String _formatDuration(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final st = SoundPickerTheme.of(context);
    if (tracks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.responsiveDimension),
            child: Text(
              'No sounds match your filters.',
              style: TextStyle(
                color: st.onSurfaceHint,
                fontSize: 13.responsiveDimension,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        SizedBox(
          height: 198.responsiveDimension,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.responsiveDimension),
            itemCount: tracks.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: 12.responsiveDimension),
            itemBuilder: (context, i) {
              final t = tracks[i];
              return TapHandler(
                onTap: () => onTapTrack(t),
                child: SizedBox(
                  width: 118.responsiveDimension,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 118.responsiveDimension,
                        height: 118.responsiveDimension,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            10.responsiveDimension,
                          ),
                          child: AppImage.network(
                            t.thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.responsiveDimension),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: st.onSurface,
                          fontSize: 13.responsiveDimension,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        t.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: st.onSurfaceSecondary,
                          fontSize: 12.responsiveDimension,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        _formatDuration(t.duration),
                        style: TextStyle(
                          color: st.onSurfaceTertiary,
                          fontSize: 11.responsiveDimension,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Single-track (or short list) picker used when dubbing with extracted reel audio.
class _RestrictedSoundPickerBody extends StatelessWidget {
  const _RestrictedSoundPickerBody({
    required this.tracks,
    required this.cameraBloc,
  });

  final List<SoundTrack> tracks;
  final CameraBloc cameraBloc;

  Future<void> _openDetail(BuildContext context, SoundTrack track) async {
    final used = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SoundTrackDetailScreen(
          track: track,
          cameraBloc: cameraBloc,
        ),
      ),
    );
    if (used == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    final st = SoundPickerTheme.of(context);
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
                    'Sound',
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
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(16.responsiveDimension),
              itemCount: tracks.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: 12.responsiveDimension),
              itemBuilder: (context, i) {
                final t = tracks[i];
                return TapHandler(
                  onTap: () => _openDetail(context, t),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8.responsiveDimension),
                      child: AppImage.network(
                        t.thumbnailUrl,
                        width: 48.responsiveDimension,
                        height: 48.responsiveDimension,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        color: st.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      t.author,
                      style: TextStyle(color: st.onSurfaceSecondary),
                    ),
                    trailing: Icon(Icons.chevron_right, color: st.onSurface),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
