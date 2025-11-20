import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  });

  final List<MentionMetaData> initialMentionList;
  final TimeLineData postData;
  final String myUserId;
  final Function(String) onTapUserProfile;

  @override
  State<MentionListBottomSheet> createState() => _MentionListBottomSheetState();
}

class _MentionListBottomSheetState extends State<MentionListBottomSheet> {
  late List<MentionMetaData> _mentionList;
  final List<SocialUserData> _socialUserList = [];
  late SocialPostBloc _socialPostBloc;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = context.getOrCreateBloc();
    _mentionList = List.from(widget.initialMentionList);
    _socialPostBloc.add(GetMentionedUserEvent(
        postId: widget.postData.id ?? '',
        onComplete: (mentionedList) {
          if (mounted && mentionedList.isNotEmpty) {
            setState(() {
              _socialUserList.clear();
              _socialUserList.addAll(mentionedList);
            });
          }
        }));
    // If no mentions initially, dismiss the bottom sheet immediately
    if (_mentionList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop(_mentionList); // Return empty list
        }
      });
    }
  }

  void _removeMentionFromList(String userId) {
    // If this is the last mention, dismiss immediately without updating UI
    if (_mentionList.length == 1 && _mentionList.first.userId == userId) {
      context.pop(_mentionList); // Return empty list
      return;
    }

    setState(() {
      _mentionList.removeWhere((mention) => mention.userId == userId);
    });
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.pop(_mentionList);
          }
        },
        child: BlocProvider<SocialPostBloc>(
          create: (context) => _socialPostBloc,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery
                  .of(context)
                  .size
                  .height * 0.9,
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
                          context.pop(_mentionList);
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
                Flexible(
                  child: _mentionList.isEmpty
                      ? Center(
                    child: Padding(
                      padding:
                      IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
                      child: Text(
                        'No mentions found',
                        style: IsrStyles.primaryText14.copyWith(
                          color: IsrColors.grey,
                        ),
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _mentionList.length,
                    itemBuilder: (context, index) {
                      final mentionedData = _mentionList[index];
                      final socialUserData = _socialUserList
                          .firstWhere(
                              (_) =>
                          _.id?.takeIfNotEmpty() != null &&
                              _.id == mentionedData.userId,
                          orElse: SocialUserData.new)
                          .takeIf((_) => _.id?.takeIfNotEmpty() != null);
                      return _buildProfileItem(
                          mentionedData, socialUserData, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildProfileItem(MentionMetaData mentionedData,
      SocialUserData? socialUserData, int index) =>
      TapHandler(
        onTap: () {
          widget.onTapUserProfile(mentionedData.userId ?? '');
          context.pop(_mentionList);
        },
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.sixteen,
            vertical: IsrDimens.twelve,
          ),
          decoration: BoxDecoration(
            border: index < _mentionList.length - 1
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
              // Profile Picture
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
                    socialUserData?.avatarUrl?.takeIfNotEmpty() ??
                        mentionedData.avatarUrl ??
                        '',
                    height: IsrDimens.forty,
                    width: IsrDimens.forty,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              IsrDimens.boxWidth(IsrDimens.twelve),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        socialUserData?.displayName?.takeIfNotEmpty() ??
                            mentionedData.name?.takeIfNotEmpty() ??
                            mentionedData.username ??
                            'Unknown User',
                        style: IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: IsrColors.black,
                        ),
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.four),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        socialUserData?.username?.takeIfNotEmpty() ??
                            mentionedData.username ??
                            '',
                        style: IsrStyles.primaryText12.copyWith(
                          color: '767676'.toColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              10.responsiveHorizontalSpace,
              // Action Button
              _buildFollowFollowingButton(
                mentionedData,
                socialUserData?.isFollowing ?? false,
                widget.postData.id ?? '',
              ),
            ],
          ),
        ),
      );

  Widget _buildFollowFollowingButton(MentionMetaData mentionedData,
      bool isFollow,
      String postId,) {
    final userId = mentionedData.userId ?? '';
    var isLoading = false;
    var isFollowing = isFollow;

    return StatefulBuilder(
      builder: (context, setState) =>
      userId == widget.myUserId
          ? AppButton(
        height: 36.responsiveDimension,
        width: 95.responsiveDimension,
        type: ButtonType.secondary,
        borderRadius: 40.responsiveDimension,
        title: IsrTranslationFile.remove,
        isLoading: isLoading,
        textStyle: IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w600,
        ),
        onPress: isLoading == true
            ? null
            : () {
          isLoading = true;
          setState.call(() {});
          _socialPostBloc.add(RemoveMentionEvent(
            postId:
            postId, // This should be the actual post ID, not user ID
            onComplete: (isSuccess) {
              isLoading = false;
              if (isSuccess) {
                // Remove the mention from the list
                _removeMentionFromList(userId);
              }
              setState.call(() {});
            },
          ));
        },
      )
          : AppButton(
        onPress: isLoading == true
            ? null
            : () {
          isLoading = true;
          setState.call(() {});
          _socialPostBloc.add(FollowUserEvent(
              followingId: userId,
              onComplete: (isSuccess) {
                isLoading = false;
                if (isSuccess) {
                  isFollowing = !isFollowing;
                }
                setState.call(() {});
              },
              followAction: isFollowing
                  ? FollowAction.unfollow
                  : FollowAction.follow));
        },
        height: 36.responsiveDimension,
        width: 95.responsiveDimension,
        borderRadius: 40.responsiveDimension,
        borderColor:
        isFollowing ? IsrColors.appColor : IsrColors.transparent,
        backgroundColor:
        isFollowing ? IsrColors.white : IsrColors.appColor,
        title: isFollowing
            ? IsrTranslationFile.following
            : IsrTranslationFile.follow,
        isLoading: isLoading,
        textStyle: IsrStyles.primaryText12.copyWith(
          color: isFollowing ? IsrColors.appColor : IsrColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
