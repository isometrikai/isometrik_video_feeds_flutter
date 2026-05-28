import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_api_body.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_theme.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_track_detail_screen.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Sound picker: search, categories, recent / trending / recommended / saved.
class SoundSelectionScreen extends StatelessWidget {
  const SoundSelectionScreen({
    super.key,
    required this.cameraBloc,
    this.restrictedTracks,
  });

  final CameraBloc cameraBloc;
  final List<SoundTrack>? restrictedTracks;

  @override
  Widget build(BuildContext context) {
    final restricted = restrictedTracks;
    if (restricted != null && restricted.isNotEmpty) {
      return _RestrictedSoundPickerBody(
        tracks: restricted,
        cameraBloc: cameraBloc,
      );
    }
    return SoundSelectionApiBody(cameraBloc: cameraBloc);
  }
}

class SoundSectionTitle extends StatelessWidget {
  const SoundSectionTitle({
    required this.title,
    this.actionLabel,
    this.onActionTap,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

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
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: st.onSurface,
                fontSize: 18.responsiveDimension,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            TapHandler(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: st.selectionAccent,
                  fontSize: 13.responsiveDimension,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SoundFilterChip extends StatelessWidget {
  const SoundFilterChip({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = SoundPickerTheme.of(context);
    return TapHandler(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34.responsiveDimension,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 14.responsiveDimension),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17.responsiveDimension),
          color: selected ? st.selectionAccent : st.filterChipBackground,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? st.filterChipOnSelected : st.onSurface,
            fontSize: 13.responsiveDimension,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SoundCategoryChip extends StatelessWidget {
  const SoundCategoryChip({
    super.key,
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
    final cardWidth = 120.responsiveDimension;
    final cardHeight = 80.responsiveDimension;
    final radius = 12.responsiveDimension;
    final borderWidth = 2.0;
    return TapHandler(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected ? st.selectionAccent : Colors.transparent,
                width: borderWidth,
              ),
              color: st.chipSurface,
            ),
            child: Padding(
              // Keep media/overlay inside the stroked rounded border.
              padding: EdgeInsets.all(borderWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius - borderWidth),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl == null)
                      Container(
                        color: st.chipSurface,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.grid_view_rounded,
                          color: st.onSurfaceSecondary,
                          size: 22.responsiveDimension,
                        ),
                      )
                    else
                      AppImage.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5.responsiveDimension,
                      right: 5.responsiveDimension,
                      bottom: 4.responsiveDimension,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5.responsiveDimension,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          shadows: const [
                            Shadow(
                              color: Color(0x99000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoundCategoriesStrip extends StatelessWidget {
  const SoundCategoriesStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onTapCategory,
    super.key,
  });

  final List<SoundCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<SoundCategory> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.responsiveDimension,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.responsiveDimension),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 0),
        itemBuilder: (context, index) {
          final item = categories[index];
          return SoundCategoryChip(
            title: item.title,
            thumbnailUrl: item.thumbnailUrl,
            selected: selectedCategoryId == item.id,
            onTap: () => onTapCategory(item),
          );
        },
      ),
    );
  }
}

class SoundListSection extends StatelessWidget {
  const SoundListSection({
    super.key,
    required this.title,
    required this.tracks,
    required this.onTapTrack,
    required this.isTrackSaved,
    required this.isTrackSaveLoading,
    required this.onToggleSave,
    this.activeTrackId,
    this.collapsedLimit,
    this.onViewAll,
  });

  final String title;
  final List<SoundTrack> tracks;
  final Future<void> Function(SoundTrack) onTapTrack;
  final bool Function(String trackId) isTrackSaved;
  final bool Function(String trackId) isTrackSaveLoading;
  final Future<void> Function(SoundTrack track) onToggleSave;
  final String? activeTrackId;
  final int? collapsedLimit;
  final VoidCallback? onViewAll;

  String _formatDuration(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  Widget _musicThumb(double size) => SvgPicture.asset(
        'assets/icons/ic_music_thumbnail.svg',
        package: 'ism_video_reel_player',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );

  @override
  Widget build(BuildContext context) {
    final st = SoundPickerTheme.of(context);
    if (tracks.isEmpty) return const SizedBox.shrink();
    final visible =
        collapsedLimit == null ? tracks : tracks.take(collapsedLimit!).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoundSectionTitle(
          title: title,
          actionLabel: onViewAll == null ? null : 'View all',
          onActionTap: onViewAll,
        ),
        ...visible.map(
          (t) => TapHandler(
            onTap: () => onTapTrack(t),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.responsiveDimension,
                vertical: 6.responsiveDimension,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.responsiveDimension,
                  vertical: 3.responsiveDimension,
                ),
                decoration: BoxDecoration(
                  color: activeTrackId == t.id
                      ? st.selectionAccent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.responsiveDimension),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8.responsiveDimension),
                      child: isLikelyImageUrl(t.thumbnailUrl)
                          ? AppImage.network(
                              t.thumbnailUrl,
                              width: 42.responsiveDimension,
                              height: 42.responsiveDimension,
                              fit: BoxFit.cover,
                              placeHolderWidget: (_, __) =>
                                  _musicThumb(42.responsiveDimension),
                            )
                          : _musicThumb(42.responsiveDimension),
                    ),
                    SizedBox(width: 10.responsiveDimension),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: st.onSurface,
                              fontSize: 15.responsiveDimension,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${t.author} \u00b7 ${_formatDuration(t.duration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: st.onSurfaceSecondary,
                              fontSize: 13.responsiveDimension,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TapHandler(
                      onTap: () => onToggleSave(t),
                      child: SizedBox(
                        width: 24.responsiveDimension,
                        height: 24.responsiveDimension,
                        child: isTrackSaveLoading(t.id)
                            ? Padding(
                                padding: EdgeInsets.all(3.responsiveDimension),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: st.selectionAccent,
                                ),
                              )
                            : Icon(
                                isTrackSaved(t.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: st.onSurface,
                                size: 21.responsiveDimension,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
          useSoundsApi: SoundLibraryFeatureUtil.useSoundsApi,
          pickerOnly: false,
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
