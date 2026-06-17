import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
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
  // late List<MentionMetaData> _mentionList;
  final List<SocialUserData> _socialUserList = [];
  late SocialPostBloc _socialPostBloc;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = context.getOrCreateBloc();
    _scrollController.addListener(_onScroll);
    _fetchMentionedUsers();
    // If no mentions initially, dismiss the bottom sheet immediately
    // if (_mentionList.isEmpty) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) {
    //       context.pop(_mentionList); // Return empty list
    //     }
    //   });
    // }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
        });
      },
    ));
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final scrollPosition = _scrollController.position;
    final threshold = scrollPosition.maxScrollExtent * 0.6;

    if (scrollPosition.pixels >= threshold) {
      _fetchMentionedUsers(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.pop();
          }
        },
        child: BlocProvider<SocialPostBloc>(
          create: (context) => _socialPostBloc,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: IsrColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(IsrDimens.twenty),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.sixteen,
                    vertical: IsrDimens.twenty,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        IsrTranslationFile.inThisSocialPost,
                        style: IsrStyles.primaryText18.copyWith(
                          fontWeight: FontWeight.w600,
                          color: IsrColors.black,
                        ),
                      ),
                      TapHandler(
                        onTap: () {
                          context.pop();
                        },
                        child: Container(
                          padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
                          child: Icon(
                            Icons.close,
                            color: IsrColors.black,
                            size: IsrDimens.twentyFour,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // User List
                _isLoading
                    ? Padding(
                        padding: IsrDimens.edgeInsetsSymmetric(
                          vertical: IsrDimens.forty,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: IsrColors.appColor,
                          ),
                        ),
                      )
                    : Flexible(
                        child: _socialUserList.isEmpty
                            ? Container(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: IsrDimens.edgeInsetsAll(
                                        IsrDimens.twentyFour),
                                    child: Text(
                                      'No mentions found',
                                      style: IsrStyles.primaryText14.copyWith(
                                        color: IsrColors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: _socialUserList.length +
                                    (_isLoadingMore ? 1 : 0),
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
                                  final socialUserData = _socialUserList[index];
                                  return _buildProfileItem(
                                      socialUserData, index);
                                },
                              ),
                      ),
              ],
            ),
          ),
        ),
      );

  Widget _buildProfileItem(SocialUserData? socialUserData, int index) =>
      Container(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.sixteen,
          vertical: IsrDimens.twelve,
        ),
        decoration: BoxDecoration(
          border: index < _socialUserList.length - 1
              ? const Border(
                  bottom: BorderSide(
                    color: IsrColors.colorDBDBDB,
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
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
                          color: IsrColors.colorDBDBDB,
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
                              color: IsrColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            socialUserData?.username?.takeIfNotEmpty() ?? '',
                            style: IsrStyles.primaryText12.copyWith(
                              color: '767676'.toColor(),
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
            _buildFollowFollowingButton(
              socialUserData,
              widget.postData.id ?? '',
            ),
          ],
        ),
      );

  Future<void> _removeSelfFromPost() async {
    final postId = widget.postData.id?.trim() ?? '';
    if (postId.isEmpty) return;

    var userId = widget.myUserId.trim();
    if (userId.isEmpty) {
      userId = await IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>()
          .getUserId();
    }
    if (userId.isEmpty) {
      userId = IsmSocialActionCubit.instance().userId;
    }

    final onMentionRemoved = widget.onMentionRemoved;

    // Dismiss the mention sheet first — a modal route cannot host the confirm
    // dialog when [IsmPostView] is embedded in the Reels tab.
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final confirmed = await Utility.showRemoveMeFromPostConfirmDialog();
    if (confirmed != true) return;

    final apiResult =
        await IsmInjectionUtils.getUseCase<RemoveMentionUseCase>()
            .executeRemoveMention(
      isLoading: true,
      postId: postId,
    );

    final statusCode = apiResult.statusCode ?? 0;
    final success =
        apiResult.isSuccess || (statusCode >= 200 && statusCode < 300);
    if (!success) {
      if (apiResult.isError) {
        ErrorHandler.showAppError(
          appError: apiResult.error,
          isNeedToShowError: true,
          errorViewType: ErrorViewType.toast,
        );
      } else {
        Utility.showToastMessage(IsrTranslationFile.somethingWentWrong);
      }
      return;
    }

    if (userId.isNotEmpty) {
      IsmSocialActionCubit.instance().onMentionRemoved(
        postId: postId,
        userId: userId,
      );
    }

    Utility.showToastMessage(IsrTranslationFile.mentionRemovedSuccessfully);
    onMentionRemoved?.call();
  }

  Widget _buildFollowFollowingButton(
    SocialUserData? socialUserData,
    String postId,
  ) {
    final userId = socialUserData?.id ?? '';
    const actionButtonWidth = 96.0;

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
                  return AppButton(
                    onPress: onTap,
                    height: 36.responsiveDimension,
                    width: actionButtonWidth,
                    borderRadius: 40.responsiveDimension,
                    type: ButtonType.secondary,
                    borderColor: IsrColors.appColor,
                    backgroundColor: IsrColors.white,
                    title: IsrTranslationFile.requested,
                    isLoading: isLoading,
                    textStyle: IsrStyles.primaryText12.copyWith(
                      color: IsrColors.appColor,
                      fontWeight: FontWeight.w600,
                    ),
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
                  return AppButton(
                    onPress: onTap,
                    height: 36.responsiveDimension,
                    width: actionButtonWidth,
                    borderRadius: 40.responsiveDimension,
                    type: ButtonType.primary,
                    borderColor: IsrColors.transparent,
                    backgroundColor: IsrColors.appColor,
                    title: showRequest
                        ? IsrTranslationFile.request
                        : IsrTranslationFile.follow,
                    isLoading: isLoading,
                    textStyle: IsrStyles.primaryText12.copyWith(
                      color: IsrColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return AppButton(
                  onPress: onTap,
                  height: 36.responsiveDimension,
                  width: actionButtonWidth,
                  borderRadius: 40.responsiveDimension,
                  type: ButtonType.secondary,
                  borderColor: IsrColors.appColor,
                  backgroundColor: IsrColors.white,
                  title: IsrTranslationFile.following,
                  isLoading: isLoading,
                  textStyle: IsrStyles.primaryText12.copyWith(
                    color: IsrColors.appColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            )
          : SizedBox(
              width: actionButtonWidth,
              child: AppButton(
                onPress: _removeSelfFromPost,
                height: 36.responsiveDimension,
                width: actionButtonWidth,
                borderRadius: 40.responsiveDimension,
                type: ButtonType.secondary,
                borderColor: IsrColors.appColor,
                backgroundColor: IsrColors.white,
                title: IsrTranslationFile.removeTag,
                textStyle: IsrStyles.primaryText12.copyWith(
                  color: IsrColors.appColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
    );
  }
}
