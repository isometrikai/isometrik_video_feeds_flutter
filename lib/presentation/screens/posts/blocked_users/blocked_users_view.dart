import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  BlockedUsersUIConfig? get _uiConfig => IsrVideoReelConfig.blockedUsersConfig.blockedUsersUIConfig;

  BlockedUsersSearchBarConfig? get _searchBarConfig => _uiConfig?.searchBarConfig;

  BlockedUsersCardConfig? get _cardConfig => _uiConfig?.userCardConfig;

  BlockedUsersUnblockButtonConfig? get _unblockButtonConfig => _uiConfig?.unblockButtonConfig;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<BlockedUsersCubit>().search(value);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: IsmCustomAppBarWidget(
          titleText: IsrTranslationFile.blockedUsers,
          backgroundColor: _uiConfig?.appBarConfig?.backgroundColor,
          iconColor: _uiConfig?.appBarConfig?.iconColor,
          titleColor: _uiConfig?.appBarConfig?.titleColor,
          showDivider: _uiConfig?.appBarConfig?.showDivider ?? true,
          dividerColor: _uiConfig?.appBarConfig?.dividerColor,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
                  builder: (context, state) {
                    if (state.loading && state.items.isEmpty) {
                      return Center(
                        child: Utility.loaderWidget(isAdaptive: false),
                      );
                    }
                    if (state.items.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildList(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSearchBar() {
    final borderRadius = _searchBarConfig?.borderRadius ?? 8.0;
    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: 16.responsiveDimension,
        vertical: 8.responsiveDimension,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: _searchBarConfig?.textStyle ?? IsrStyles.primaryText14,
        decoration: InputDecoration(
          hintText: _searchBarConfig?.hintText ?? IsrTranslationFile.searchBlockedUsers,
          hintStyle: _searchBarConfig?.hintStyle ?? IsrStyles.primaryText14,
          prefixIcon: Icon(
            Icons.search,
            color: IsrColors.primaryTextColor,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: IsrColors.primaryTextColor,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: _searchBarConfig?.backgroundColor ?? Colors.grey[100],
          contentPadding: _searchBarConfig?.contentPadding ??
              IsrDimens.edgeInsetsSymmetric(
                horizontal: 16.responsiveDimension,
                vertical: 12.responsiveDimension,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: _searchBarConfig?.borderColor ?? Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: _searchBarConfig?.borderColor ?? Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: _searchBarConfig?.borderColor ?? IsrColors.primaryTextColor,
            ),
          ),
        ),
        onTap: () => setState(() {}),
      ),
    );
  }

  Widget _buildList(BuildContext context, BlockedUsersState state) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.maxScrollExtent > 0 &&
              metrics.pixels >= metrics.maxScrollExtent - 80 &&
              !state.loadingMore &&
              state.hasMore) {
            context.read<BlockedUsersCubit>().loadBlockedUsers(refresh: false);
          }
          return false;
        },
        child: RefreshIndicator(
          color: IsrColors.appColor,
          onRefresh: () => context.read<BlockedUsersCubit>().loadBlockedUsers(refresh: true),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.eight),
            itemCount: state.items.length + (state.loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent:
                  16.responsiveDimension + (_cardConfig?.avatarSize ?? 48.responsiveDimension) + 12,
            ),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return Padding(
                  padding: IsrDimens.edgeInsetsAll(16.responsiveDimension),
                  child: Center(child: Utility.loaderWidget(isAdaptive: false)),
                );
              }
              return _buildBlockedUserItem(context, state.items[index]);
            },
          ),
        ),
      );

  Widget _buildBlockedUserItem(BuildContext context, BlockedUserItem item) {
    final avatarSize = _cardConfig?.avatarSize ?? 48.responsiveDimension;
    final username = item.username.isNotEmpty ? item.username : '@unknown';

    return Padding(
      padding: _cardConfig?.padding ??
          IsrDimens.edgeInsetsSymmetric(
            horizontal: 16.responsiveDimension,
            vertical: 8.responsiveDimension,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TapHandler(
              onTap: () => _openUserProfile(item),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: IsrColors.colorDBDBDB,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: AppImage.network(
                        item.avatarUrl ?? '',
                        height: avatarSize,
                        width: avatarSize,
                        fit: BoxFit.cover,
                        isProfileImage: true,
                        name: item.displayLabel,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.responsiveDimension),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayLabel,
                          style: _cardConfig?.usernameStyle ?? IsrStyles.primaryText16Bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          username.startsWith('@') ? username : '@$username',
                          style: _cardConfig?.fullNameStyle ?? IsrStyles.primaryText14,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppButton(
            title: _unblockButtonConfig?.text ?? IsrTranslationFile.unblock,
            type: ButtonType.secondary,
            width: _unblockButtonConfig?.width ?? 100.responsiveDimension,
            height: _unblockButtonConfig?.height ?? 32.responsiveDimension,
            borderRadius: _unblockButtonConfig?.borderRadius,
            backgroundColor: _unblockButtonConfig?.backgroundColor,
            textColor: _unblockButtonConfig?.textColor,
            textStyle: _unblockButtonConfig?.textStyle ?? IsrStyles.primaryText12,
            onPress: () => _confirmUnblock(context, item),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyConfig = _uiConfig?.emptyStateConfig;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.twentyFour,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emptyConfig?.icon != null)
                  Icon(
                    emptyConfig!.icon,
                    size: emptyConfig.iconSize ?? IsrDimens.eighty,
                    color: emptyConfig.iconColor ?? IsrColors.primaryTextColor,
                  ),
                IsrDimens.sixteen.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.noBlockedUsers,
                  textAlign: TextAlign.center,
                  style: emptyConfig?.titleStyle ?? IsrStyles.primaryText16Bold,
                ),
                IsrDimens.eight.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.noBlockedUsersMessage,
                  textAlign: TextAlign.center,
                  style: emptyConfig?.messageStyle ?? IsrStyles.primaryText14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmUnblock(BuildContext context, BlockedUserItem item) async {
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            dialogConfig?.borderRadius ?? 20.0,
          ),
        ),
        backgroundColor: dialogConfig?.backgroundColor ?? Colors.white,
        child: Padding(
          padding:
              dialogConfig?.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                IsrTranslationFile.unblockUser,
                style: dialogConfig?.titleTextStyle ??
                    IsrStyles.primaryText18.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              16.responsiveVerticalSpace,
              Text(
                IsrTranslationFile.unblockUserConfirmation,
                style: dialogConfig?.messageTextStyle ??
                    IsrStyles.primaryText14.copyWith(color: '4A4A4A'.toColor()),
              ),
              32.responsiveVerticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AppButton(
                    title: IsrTranslationFile.cancel,
                    width: 102.responsiveDimension,
                    type: ButtonType.secondary,
                    onPress: () => Navigator.of(dialogContext).pop(false),
                  ),
                  AppButton(
                    title: IsrTranslationFile.unblock,
                    width: 102.responsiveDimension,
                    onPress: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true && context.mounted) {
      await context.read<BlockedUsersCubit>().unblockUser(item);
    }
  }

  void _openUserProfile(BlockedUserItem item) {
    IsrVideoReelConfig.postConfig.postCallBackConfig?.onProfileClick?.call(
      null,
      item.userId,
      false,
    );
  }
}
