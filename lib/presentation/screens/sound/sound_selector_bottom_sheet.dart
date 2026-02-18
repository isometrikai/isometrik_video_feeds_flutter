import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/bloc/sound/sound_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Bottom sheet for selecting a sound. Shows search bar, tabs (For You, Trending, Recent)
/// when search is not focused, and a single listing when search is focused.
class SoundSelectorBottomSheet extends StatefulWidget {
  const SoundSelectorBottomSheet({
    super.key,
    this.onSoundSelected,
  });

  final ValueChanged<SoundData>? onSoundSelected;

  /// Opens the sound selector bottom sheet and returns the selected [SoundData], or null if dismissed.
  static Future<SoundData?> show(BuildContext context) async => showModalBottomSheet<SoundData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: 80.percentHeight),
        child: BlocProvider<SoundBloc>(
          create: (_) =>
              SoundBloc(IsmInjectionUtils.getUseCase<SoundUseCase>()),
          child: SoundSelectorBottomSheet(
            onSoundSelected: (sound) => ctx.pop(sound),
          ),
        ),
      ),
    );

  @override
  State<SoundSelectorBottomSheet> createState() =>
      _SoundSelectorBottomSheetState();
}

class _SoundSelectorBottomSheetState extends State<SoundSelectorBottomSheet> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  SoundListTypes _selectedTab = SoundListTypes.trending;
  bool _searchHasFocus = false;

  int get _tabIndex {
    switch (_selectedTab) {
      case SoundListTypes.trending:
        return 0;
      case SoundListTypes.saved:
        return 1;
      case SoundListTypes.recent:
        return 2;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (mounted) {
      setState(() => _searchHasFocus = _searchFocusNode.hasFocus);
    }
  }

  void _onSoundSelected(SoundData sound) {
    widget.onSoundSelected?.call(sound);
  }

  @override
  Widget build(BuildContext context) => Container(
      height: 80.percentHeight,
      decoration: BoxDecoration(
        color: IsrColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(IsrDimens.twentyFour),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          if (!_searchHasFocus) _buildTabs(),
          IsrDimens.boxHeight(IsrDimens.sixteen),
          Expanded(
            child: _searchHasFocus
                ? SoundListWidget(
                    soundListTypes: SoundListTypes.sound,
                    search: _searchController.text.trim().isEmpty
                        ? null
                        : _searchController.text.trim(),
                    onSoundSelected: _onSoundSelected,
                  )
                : IndexedStack(
                    index: _tabIndex,
                    children: [
                      SoundListWidget(
                        key: const ValueKey<SoundListTypes>(
                            SoundListTypes.trending),
                        soundListTypes: SoundListTypes.trending,
                        onSoundSelected: _onSoundSelected,
                      ),
                      SoundListWidget(
                        key: const ValueKey<SoundListTypes>(
                            SoundListTypes.saved),
                        soundListTypes: SoundListTypes.saved,
                        onSoundSelected: _onSoundSelected,
                      ),
                      SoundListWidget(
                        key: const ValueKey<SoundListTypes>(
                            SoundListTypes.recent),
                        soundListTypes: SoundListTypes.recent,
                        onSoundSelected: _onSoundSelected,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );

  Widget _buildSearchBar() => Padding(
      padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
      child: Container(
        height: IsrDimens.fortyEight,
        decoration: BoxDecoration(
          color: IsrColors.colorF2F2F2.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search Music',
            hintStyle: IsrStyles.primaryText14.copyWith(
              color: IsrColors.color9B9B9B,
            ),
            prefixIcon: Padding(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
              child: AppImage.svg(
                AssetConstants.icSearchIcon,
                height: IsrDimens.twenty,
                width: IsrDimens.twenty,
                color: IsrColors.color9B9B9B,
              ),
            ),
            suffixIcon: _searchHasFocus
                ? TapHandler(
                    onTap: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchController.clear();
                        setState(() {});
                      } else {
                        _searchFocusNode.unfocus();
                      }
                    },
                    child: Padding(
                      padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
                      child: Icon(
                        Icons.close,
                        size: IsrDimens.twenty,
                        color: IsrColors.color9B9B9B,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: IsrDimens.edgeInsetsSymmetric(
              vertical: IsrDimens.twelve,
              horizontal: IsrDimens.sixteen,
            ),
          ),
        ),
      ),
    );

  Widget _buildTabs() => Container(
      margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
      height: IsrDimens.forty,
      decoration: BoxDecoration(
        color: IsrColors.colorF2F2F2.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(IsrDimens.twenty),
      ),
      child: Row(
        children: [
          _tab(SoundListTypes.trending.value.capitalizeWords() , SoundListTypes.trending),
          _tab(SoundListTypes.saved.value.capitalizeWords() , SoundListTypes.saved),
          _tab(SoundListTypes.recent.value.capitalizeWords() , SoundListTypes.recent),
        ],
      ),
    );

  Widget _tab(String label, SoundListTypes type) {
    final isSelected = _selectedTab == type;
    return Expanded(
      child: TapHandler(
        onTap: () => setState(() => _selectedTab = type),
        child: Container(
          margin: IsrDimens.edgeInsetsAll(IsrDimens.two),
          decoration: BoxDecoration(
            color: isSelected ? IsrColors.appColor : Colors.transparent,
            borderRadius: BorderRadius.circular(IsrDimens.twenty),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: IsrStyles.primaryText14.copyWith(
              fontWeight: FontWeight.w500,
              color: isSelected ? IsrColors.white : IsrColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
