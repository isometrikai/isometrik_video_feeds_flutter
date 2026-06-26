import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class MentionListBottomSheet extends StatefulWidget {
  const MentionListBottomSheet({
    required this.initialMentionList,
    required this.postData,
    required this.myUserId,
    required this.onTapUserProfile,
    this.onMentionRemoved,
  });

  final List<MentionMetaData> initialMentionList;
  final TimeLineData postData;
  final String myUserId;
  final VoidCallback? onMentionRemoved;
  final Function(String userId, bool isFollowing) onTapUserProfile;

  @override
  State<MentionListBottomSheet> createState() => _MentionListBottomSheetState();
}

class _MentionListBottomSheetState extends State<MentionListBottomSheet> {
  final List<SocialUserData> _socialUserList = [];
  late SocialPostBloc _socialPostBloc;
  final ScrollController _listScrollController = ScrollController();
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _isExpanded = false;
  bool _canExpandSheet = false;

  static const double _collapsedSheetFraction = 0.5;
  static const double _expandedSheetFraction = 0.9;
  static const double _swipeVelocityThreshold = 200;
  static const double _headerSectionHeight = 80;
  static const double _listItemHeight = 68;

  Color get _backgroundColor =>
      IsrVideoReelConfig
          .socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrColors.white;

  Color get _primaryTextColor => IsrColors.primaryTextColor;

  Color get _secondaryTextColor => IsrColors.secondaryTextColor;

  Color get _dividerColor => IsrColors.dividerColor;

  Color get _secondaryButtonBackground => IsrColors.scaffoldColor;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = context.getOrCreateBloc();
    _listScrollController.addListener(_onScroll);
    _fetchMentionedUsers();
  }

  @override
  void dispose() {
    _listScrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onHeaderSwipe(DragEndDetails details) {
    if (!_canExpandSheet) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_swipeVelocityThreshold) {
      setState(() => _isExpanded = true);
      return;
    }
    if (velocity > _swipeVelocityThreshold) {
      setState(() => _isExpanded = false);
    }
  }

  bool _estimateCanExpand(double screenHeight, double bottomInset) {
    if (_isLoading || _socialUserList.isEmpty) {
      return false;
    }
    if (_hasMore || _isLoadingMore) {
      return true;
    }
    final listViewportHeight =
        (screenHeight * _collapsedSheetFraction) - _headerSectionHeight;
    final contentListHeight =
        (_socialUserList.length * _listItemHeight) + bottomInset;
    return contentListHeight > listViewportHeight;
  }

  void _syncExpandAvailability() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final screenHeight = MediaQuery.sizeOf(context).height;
      final bottomInset = MediaQuery.paddingOf(context).bottom;
      var canExpand = _estimateCanExpand(screenHeight, bottomInset);
      if (_listScrollController.hasClients) {
        canExpand =
            canExpand || _listScrollController.position.maxScrollExtent > 0;
      }

      if (canExpand == _canExpandSheet && (canExpand || !_isExpanded)) {
        return;
      }

      setState(() {
        _canExpandSheet = canExpand;
        if (!canExpand) {
          _isExpanded = false;
        }
      });
    });
  }

  double _resolveSheetHeight(double screenHeight, double bottomInset) {
    final collapsedCap = screenHeight * _collapsedSheetFraction;
    if (_isExpanded && _canExpandSheet) {
      return screenHeight * _expandedSheetFraction;
    }
    if (!_canExpandSheet &&
        !_isLoading &&
        _socialUserList.isNotEmpty) {
      final fittedHeight = _headerSectionHeight +
          (_socialUserList.length * _listItemHeight) +
          bottomInset;
      return fittedHeight.clamp(
        _headerSectionHeight + _listItemHeight,
        collapsedCap,
      );
    }
    return collapsedCap;
  }

  void _fetchMentionedUsers({bool loadMore = false}) {
    if (loadMore && (!_hasMore || _isLoadingMore)) {
      return;
    }

    final pageToFetch = loadMore ? _currentPage + 1 : 1;

    if (loadMore) {
      _isLoadingMore = true;
    }

    _socialPostBloc.add(GetMentionedUserEvent(
      postId: widget.postData.id ?? '',
      page: pageToFetch,
      onComplete: (mentionedList, hasMore) {
        if (!mounted) {
          return;
        }
        final screenHeight = MediaQuery.sizeOf(context).height;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = hasMore;
          _currentPage = pageToFetch;
          if (loadMore) {
            _socialUserList.addAll(mentionedList);
          } else {
            _socialUserList
              ..clear()
              ..addAll(mentionedList);
          }
          _canExpandSheet = _estimateCanExpand(screenHeight, bottomInset);
          if (!_canExpandSheet) {
            _isExpanded = false;
          }
        });
        _syncExpandAvailability();
      },
    ));
  }

  void _onScroll() {
    if (!_listScrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final scrollPosition = _listScrollController.position;
    final threshold = scrollPosition.maxScrollExtent * 0.6;

    if (scrollPosition.pixels >= threshold) {
      _fetchMentionedUsers(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = _resolveSheetHeight(screenHeight, bottomInset);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.pop();
        }
      },
      child: BlocProvider<SocialPostBloc>(
        create: (context) => _socialPostBloc,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: sheetHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(IsrDimens.twenty),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragEnd:
                      _canExpandSheet ? _onHeaderSwipe : null,
                  child: Column(
                    children: [
                      if (_canExpandSheet)
                        Padding(
                          padding: EdgeInsets.only(top: IsrDimens.twelve),
                          child: Container(
                            width: IsrDimens.forty,
                            height: IsrDimens.four,
                            decoration: BoxDecoration(
                              color: _dividerColor,
                              borderRadius:
                                  BorderRadius.circular(IsrDimens.two),
                            ),
                          ),
                        )
                      else
                        SizedBox(height: IsrDimens.twelve),
                      Padding(
                        padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: IsrDimens.sixteen,
                          vertical: IsrDimens.twelve,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                IsrTranslationFile.inThisSocialPost,
                                style: IsrStyles.primaryText18.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _primaryTextColor,
                                ),
                              ),
                            ),
                            TapHandler(
                              onTap: context.pop,
                              child: Container(
                                padding:
                                    IsrDimens.edgeInsetsAll(IsrDimens.eight),
                                child: Icon(
                                  Icons.close,
                                  color: _primaryTextColor,
                                  size: IsrDimens.twentyFour,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: _dividerColor),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(bottomInset: bottomInset),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({required double bottomInset}) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: IsrColors.appColor,
        ),
      );
    }

    if (_socialUserList.isEmpty) {
      return Center(
        child: Padding(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
          child: Text(
            'No mentions found',
            style: IsrStyles.primaryText14.copyWith(
              color: _secondaryTextColor,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _listScrollController,
      physics: _canExpandSheet
          ? const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            )
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomInset),
      itemCount: _socialUserList.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _socialUserList.length) {
          return Padding(
            padding: IsrDimens.edgeInsetsSymmetric(
              vertical: IsrDimens.sixteen,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: IsrColors.appColor,
              ),
            ),
          );
        }
        return _buildProfileItem(
          _socialUserList[index],
          index,
        );
      },
    );
  }

  static const double _actionButtonWidth = 108;

  Widget _buildProfileItem(SocialUserData? socialUserData, int index) =>
      Container(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.sixteen,
          vertical: IsrDimens.twelve,
        ),
        decoration: BoxDecoration(
          border: index < _socialUserList.length - 1
              ? Border(
                  bottom: BorderSide(
                    color: _dividerColor,
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TapHandler(
                onTap: () {
                  widget.onTapUserProfile(
                    socialUserData?.id ?? '',
                    socialUserData?.isFollowing == true,
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: IsrDimens.forty,
                      height: IsrDimens.forty,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _dividerColor,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: AppImage.network(
                          socialUserData?.avatarUrl?.takeIfNotEmpty() ?? '',
                          height: IsrDimens.forty,
                          width: IsrDimens.forty,
                          fit: BoxFit.cover,
                          name: socialUserData?.fullName ?? '',
                          isProfileImage: true,
                        ),
                      ),
                    ),
                    IsrDimens.boxWidth(IsrDimens.twelve),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            socialUserData?.displayName?.takeIfNotEmpty() ??
                                socialUserData?.fullName?.takeIfNotEmpty() ??
                                socialUserData?.username ??
                                'Unknown User',
                            style: IsrStyles.primaryText14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            socialUserData?.username?.takeIfNotEmpty() ?? '',
                            style: IsrStyles.primaryText12.copyWith(
                              color: _secondaryTextColor,
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
            ),
            IsrDimens.boxWidth(IsrDimens.eight),
            SizedBox(
              width: _actionButtonWidth,
              child: _buildFollowFollowingButton(
                socialUserData,
                widget.postData.id ?? '',
              ),
            ),
          ],
        ),
      );

  Future<void> _removeSelfFromPost() async {
    widget.onMentionRemoved?.call();

    // Dismiss the mention sheet first — a modal route cannot host the confirm
    // dialog when [IsmPostView] is embedded in the Reels tab.
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Widget _buildActionButton({
    required VoidCallback? onPress,
    required String title,
    required ButtonType type,
    bool isLoading = false,
    Color? backgroundColor,
  }) =>
      AppButton(
        onPress: onPress,
        size: ButtonSize.small,
        height: 36.responsiveDimension,
        width: _actionButtonWidth,
        maxWidth: _actionButtonWidth,
        borderRadius: 40.responsiveDimension,
        type: type,
        borderColor: IsrColors.appColor,
        backgroundColor: backgroundColor,
        title: title,
        isLoading: isLoading,
        textStyle: IsrStyles.primaryText12.copyWith(
          color: type == ButtonType.primary
              ? IsrColors.white
              : IsrColors.appColor,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _buildFollowFollowingButton(
    SocialUserData? socialUserData,
    String postId,
  ) {
    final userId = socialUserData?.id ?? '';

    return StatefulBuilder(
      builder: (context, setState) => userId != widget.myUserId
          ? FollowActionWidget(
              userId: userId,
              isFollowing: socialUserData?.isFollowing == true,
              isTargetPrivate: (socialUserData?.isPrivate ?? 0) == 1,
              initialFollowStatus: socialUserData?.followStatus,
              initialIsRequested: socialUserData?.isRequested,
              builder: (isLoading, isFollowing, followRequestPending, onTap) {
                socialUserData?.isFollowing = isFollowing;
                if (followRequestPending) {
                  return _buildActionButton(
                    onPress: onTap,
                    type: ButtonType.secondary,
                    backgroundColor: _secondaryButtonBackground,
                    title: IsrTranslationFile.requested,
                    isLoading: isLoading,
                  );
                }
                if (!isFollowing) {
                  final private = (socialUserData?.isPrivate ?? 0) == 1;
                  final showRequest = FollowRelationshipUi.showRequestPrimaryLabel(
                    isFollowing: isFollowing,
                    isPrivateAccount: private,
                    isRequested: socialUserData?.isRequested,
                    followStatus: socialUserData?.followStatus,
                  );
                  return _buildActionButton(
                    onPress: onTap,
                    type: ButtonType.primary,
                    backgroundColor: IsrColors.appColor,
                    title: showRequest
                        ? IsrTranslationFile.request
                        : IsrTranslationFile.follow,
                    isLoading: isLoading,
                  );
                }
                return _buildActionButton(
                  onPress: onTap,
                  type: ButtonType.secondary,
                  backgroundColor: _secondaryButtonBackground,
                  title: IsrTranslationFile.following,
                  isLoading: isLoading,
                );
              },
            )
          : _buildActionButton(
              onPress: _removeSelfFromPost,
              type: ButtonType.secondary,
              backgroundColor: _secondaryButtonBackground,
              title: IsrTranslationFile.removeTag,
            ),
    );
  }
}
