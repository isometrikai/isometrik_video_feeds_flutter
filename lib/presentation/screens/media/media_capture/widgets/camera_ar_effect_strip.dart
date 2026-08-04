import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/models/ar_filter_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Horizontal strip of DeepAR effects. Shown only when AR mode is active.
class CameraArEffectStrip extends StatelessWidget {
  const CameraArEffectStrip({
    super.key,
    required this.cameraBloc,
  });

  final CameraBloc cameraBloc;

  static const _noneId = '';

  @override
  Widget build(BuildContext context) {
    if (!cameraBloc.isUsingAr) {
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
          current is CameraSwitchedState,
      builder: (context, state) {
        final selectedId = cameraBloc.selectedArEffectId;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: 150.responsiveDimension),
              child: SizedBox(
                height: 84.responsiveDimension,
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
                      return _EffectChip(
                        label: 'None',
                        selected: selectedId.isEmpty,
                        onTap: () => cameraBloc.add(
                          CameraApplyArEffectEvent(
                            effectId: _noneId,
                            pathOrUrl: null,
                          ),
                        ),
                        child: Icon(
                          Icons.block,
                          color: selectedId.isEmpty
                              ? IsrColors.black
                              : IsrColors.white,
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
                      child: _EffectThumbnail(effect: effect),
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.responsiveDimension,
              height: 56.responsiveDimension,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? IsrColors.white
                    : IsrColors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: selected ? IsrColors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
            SizedBox(height: IsrDimens.four),
            SizedBox(
              width: 64.responsiveDimension,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: IsrStyles.white12.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
}

class _EffectThumbnail extends StatelessWidget {
  const _EffectThumbnail({required this.effect});

  final ArEffectItem effect;

  @override
  Widget build(BuildContext context) {
    final thumb = effect.thumbnailUrl?.trim() ?? '';
    if (thumb.isEmpty) {
      return Center(
        child: Text(
          effect.name.isNotEmpty ? effect.name[0].toUpperCase() : 'A',
          style: IsrStyles.white16.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }

    if (thumb.startsWith('http://') || thumb.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Icon(
          Icons.auto_awesome,
          color: IsrColors.white,
          size: 22.responsiveDimension,
        ),
      );
    }

    return Image.asset(
      thumb,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.auto_awesome,
        color: IsrColors.white,
        size: 22.responsiveDimension,
      ),
    );
  }
}
