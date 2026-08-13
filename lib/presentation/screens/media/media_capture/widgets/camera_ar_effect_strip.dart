import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/models/ar_filter_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Horizontal strip of DeepAR effects.
/// Shown when AR is available (host licensed) — DeepAR itself starts lazily
/// on the first effect tap.
class CameraArEffectStrip extends StatelessWidget {
  const CameraArEffectStrip({
    super.key,
    required this.cameraBloc,
  });

  final CameraBloc cameraBloc;

  static const _noneId = '';

  @override
  Widget build(BuildContext context) {
    if (!cameraBloc.isArAvailable) {
      return const SizedBox.shrink();
    }

    final effects = cameraBloc.arFilterConfig.effects;
    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CameraBloc, CameraState>(
      bloc: cameraBloc,
      buildWhen: (previous, current) =>
          current is CameraArEffectAppliedState ||
          current is CameraInitializedState ||
          current is CameraSwitchedState ||
          current is CameraLoadingState,
      builder: (context, state) {
        final selectedId = cameraBloc.selectedArEffectId;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              // Keep strip above shutter / flash / flip controls.
              padding: EdgeInsets.only(bottom: 168.responsiveDimension),
              child: SizedBox(
                // Circle + gap + label must fit without clipping.
                height: 96.responsiveDimension,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: IsrDimens.sixteen,
                  ),
                  itemCount: effects.length + 1,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: IsrDimens.twelve),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final selected = selectedId.isEmpty;
                      return _EffectChip(
                        label: 'None',
                        selected: selected,
                        onTap: () => cameraBloc.add(
                          CameraApplyArEffectEvent(
                            effectId: _noneId,
                            pathOrUrl: null,
                          ),
                        ),
                        child: Icon(
                          Icons.block,
                          color: IsrColors.white,
                          size: 22.responsiveDimension,
                        ),
                      );
                    }

                    final effect = effects[index - 1];
                    final selected = selectedId == effect.id;
                    return _EffectChip(
                      label: effect.name,
                      selected: selected,
                      onTap: () => cameraBloc.add(
                        CameraApplyArEffectEvent(
                          effectId: effect.id,
                          pathOrUrl: effect.pathOrUrl,
                        ),
                      ),
                      child: _EffectThumbnail(
                        effect: effect,
                        selected: selected,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 52.responsiveDimension;
    final ringPad = selected ? 3.responsiveDimension : 0.0;
    final outerSize = avatarSize + (ringPad * 2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72.responsiveDimension,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection uses an outer ring so the thumbnail / letter stays visible.
            Container(
              width: outerSize,
              height: outerSize,
              padding: EdgeInsets.all(ringPad),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: IsrColors.white, width: 2)
                    : null,
              ),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: IsrColors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: IsrColors.white.withValues(
                      alpha: selected ? 0.9 : 0.35,
                    ),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
            SizedBox(height: 6.responsiveDimension),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: IsrStyles.white12.copyWith(
                fontSize: 11.responsiveDimension,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectThumbnail extends StatelessWidget {
  const _EffectThumbnail({
    required this.effect,
    required this.selected,
  });

  final ArEffectItem effect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final thumb = effect.thumbnailUrl?.trim() ?? '';
    if (thumb.isEmpty) {
      return _LetterFallback(effect: effect, selected: selected);
    }

    if (thumb.startsWith('http://') || thumb.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (_, __, ___) =>
            _LetterFallback(effect: effect, selected: selected),
      );
    }

    return Image.asset(
      thumb,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) =>
          _LetterFallback(effect: effect, selected: selected),
    );
  }
}

/// Letter avatar when [ArEffectItem.thumbnailUrl] is not configured.
class _LetterFallback extends StatelessWidget {
  const _LetterFallback({
    required this.effect,
    required this.selected,
  });

  final ArEffectItem effect;
  final bool selected;

  Color _toneFor(String seed) {
    const palette = <Color>[
      Color(0xFF5B8DEF),
      Color(0xFF7C5CFC),
      Color(0xFF2BB673),
      Color(0xFFE67E22),
      Color(0xFFE74C3C),
      Color(0xFF1ABC9C),
      Color(0xFF9B59B6),
      Color(0xFF3498DB),
    ];
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final letter =
        effect.name.isNotEmpty ? effect.name[0].toUpperCase() : 'A';
    final tone = _toneFor(effect.id.isNotEmpty ? effect.id : effect.name);

    return ColoredBox(
      color: tone.withValues(alpha: selected ? 0.95 : 0.75),
      child: Center(
        child: Text(
          letter,
          style: IsrStyles.white16.copyWith(
            fontWeight: FontWeight.w700,
            color: IsrColors.white,
          ),
        ),
      ),
    );
  }
}
