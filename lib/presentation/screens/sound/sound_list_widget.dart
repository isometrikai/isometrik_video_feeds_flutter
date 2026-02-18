import 'dart:async';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' as flutter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/bloc/sound/sound_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Common stateful widget for displaying a list of sounds by [SoundListTypes].
/// Used in both tab view and search results.
class SoundListWidget extends StatefulWidget {
  const SoundListWidget({
    super.key,
    required this.soundListTypes,
    this.search,
    this.onSoundSelected,
  });

  final SoundListTypes soundListTypes;
  final String? search;
  final ValueChanged<SoundData>? onSoundSelected;

  @override
  State<SoundListWidget> createState() => _SoundListWidgetState();
}

class _SoundListWidgetState extends State<SoundListWidget> {
  static const int _pageSize = 20;
  Timer? _searchDebounce;
  late SoundBloc _soundBloc;
  final List<SoundData> _soundList = [];

  @override
  void initState() {
    super.initState();
    _soundList.clear();
    _soundBloc = context.getOrCreateBloc();
    _loadSounds();
  }

  @override
  void didUpdateWidget(SoundListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.soundListTypes != widget.soundListTypes) {
      _loadSounds();
    } else if (oldWidget.search != widget.search) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 400), _loadSounds);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSounds() async {
    final completer = Completer<void>();
    _soundList.clear();
    _soundBloc.add(
      GetSoundListEvent(
        soundListTypes: widget.soundListTypes,
        page: 1,
        pageSize: _pageSize,
        search: widget.search?.trim().isEmpty == true ? null : widget.search,
        onComplete: completer.complete,
      ),
    );
    await completer.future;
  }

  String _formatDuration(num? duration) {
    if (duration == null) return '0:00';
    final minutes = (duration.toDouble() / 60).floor();
    final seconds = (duration.toDouble() % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => context.attachBlocIfNeeded(
        bloc: _soundBloc,
        child: BlocConsumer<SoundBloc, SoundState>(
          buildWhen: (prev, curr) {
            if (curr is SoundListState) {
              return curr.soundListTypes == widget.soundListTypes &&
                  curr.search == widget.search;
            }
            return false;
          },
          listenWhen: (prev, curr) {
            if (curr is SoundListState) {
              return curr.soundListTypes == widget.soundListTypes &&
                  curr.search == widget.search;
            }
            return false;
          },
          listener: (context, state) {
            if (state is SoundListErrorState) {
              _soundList.clear();
            } else if (state is SoundListLoadedState) {
              if (state.page == 1) {
                _soundList.clear();
              }
              _soundList.addAll(state.sounds);
            }
          },
          builder: (context, state) {
            if (_soundList.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: _loadSounds,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: IsrDimens.edgeInsetsSymmetric(
                      horizontal: IsrDimens.sixteen),
                  itemCount: _soundList.length,
                  itemBuilder: (context, index) {
                    final sound = _soundList[index];
                    return _SoundListItem(
                      sound: sound,
                      onTap: () => widget.onSoundSelected?.call(sound),
                      formatDuration: _formatDuration,
                      soundBloc: _soundBloc,
                    );
                  },
                ),
              );
            } else if (state is SoundListLoadingState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is SoundListErrorState) {
              return Center(
                child: Padding(
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
                  child: Text(
                    state.error,
                    style: IsrStyles.primaryText14.copyWith(
                      color: IsrColors.color9B9B9B,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else if (state is SoundListLoadedState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: IsrDimens.fortyEight,
                      color: IsrColors.color9B9B9B,
                    ),
                    IsrDimens.boxHeight(IsrDimens.sixteen),
                    Text(
                      widget.search != null && widget.search!.isNotEmpty
                          ? 'No sounds found'
                          : 'No sounds available',
                      style: IsrStyles.primaryText14.copyWith(
                        color: IsrColors.color9B9B9B,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
}

class _SoundListItem extends StatefulWidget {
  const _SoundListItem({
    required this.sound,
    required this.onTap,
    required this.formatDuration,
    this.soundBloc,
  });

  final SoundData sound;
  final VoidCallback onTap;
  final SoundBloc? soundBloc;
  final String Function(num?) formatDuration;

  @override
  State<_SoundListItem> createState() => _SoundListItemState();
}

class _SoundListItemState extends State<_SoundListItem> {
  @override
  void initState() {
    super.initState();
  }

  SoundBloc get _soundBloc => widget.soundBloc ?? context.getOrCreateBloc();

  @override
  Widget build(BuildContext context) => TapHandler(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: IsrDimens.eight),
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.sixteen,
            vertical: IsrDimens.twelve,
          ),
          child: Row(
            children: [
              SizedBox(
                width: IsrDimens.fortyEight,
                height: IsrDimens.fortyEight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(IsrDimens.eight),
                  child: Stack(
                    children: [
                      _buildPreviewImage(),
                      _buildPlayerView(),
                    ],
                  ),
                ),
              ),
              IsrDimens.boxWidth(IsrDimens.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sound.title ?? 'Unknown Title',
                      style: IsrStyles.primaryText14.copyWith(
                        fontWeight: FontWeight.w500,
                        color: IsrColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    IsrDimens.boxHeight(IsrDimens.four),
                    Text(
                      '${widget.sound.artist ?? 'Unknown Artist'} • '
                      '${widget.formatDuration(widget.sound.duration)}',
                      style: IsrStyles.primaryText12.copyWith(
                        color: IsrColors.color9B9B9B,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlayerView() => Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black.applyOpacity(0.3),
        child: StreamBuilder<IsmAudioPlayerListener?>(
          stream: _soundBloc.audioStream,
          builder: (_, snapshot) {
            final data = snapshot.data;
            if (data != null &&
                data.url == widget.sound.url &&
                (data.state == IsmAudioPlayerState.playing ||
                    data.state == IsmAudioPlayerState.buffering)) {
              return TapHandler(
                onTap: () => _soundBloc.add(
                  SoundPlayerStopEvent(widget.sound.url ?? ''),
                ),
                child: Padding(
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.four),
                  child: Stack(
                    children: [
                      Center(
                        child: CircularProgressIndicator(
                          value: data.state == IsmAudioPlayerState.buffering
                              ? null
                              : data.progress,
                          color: IsrColors.white,
                          strokeWidth: IsrDimens.two,
                        ),
                      ),
                      if (data.state == IsmAudioPlayerState.playing)
                        const Center(child: Icon(Icons.stop)),
                    ],
                  ),
                ),
              );
            } else {
              return TapHandler(
                onTap: () => _soundBloc.add(
                  SoundPlayerPlayEvent(widget.sound.url ?? ''),
                ),
                child: Padding(
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.four),
                  child: const Icon(Icons.play_arrow),
                ),
              );
            }
          },
        ),
      );

  Widget _buildPreviewImage() =>
      widget.sound.previewUrl != null && widget.sound.previewUrl!.isNotEmpty
          ? flutter.Image.network(
              widget.sound.previewUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderThumbnail(),
            )
          : _placeholderThumbnail();

  Widget _placeholderThumbnail() => Container(
        width: IsrDimens.fortyEight,
        height: IsrDimens.fortyEight,
        color: IsrColors.appColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.music_note,
          color: IsrColors.appColor,
          size: IsrDimens.twentyFour,
        ),
      );
}
