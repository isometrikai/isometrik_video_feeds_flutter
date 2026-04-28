import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  final Function(String userId, bool isFollowing) onTapUserProfile;

  @override
  State<MentionListBottomSheet> createState() => _MentionListBottomSheetState();
}

class _MentionListBottomSheetState extends State<MentionListBottomSheet> {
  // late List<MentionMetaData> _mentionList;
  final List<SocialUserData> _socialUserList = [];
  late SocialPostBloc _socialPostBloc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = context.getOrCreateBloc();
    // _mentionList = List.from(widget.initialMentionList);
    _socialPostBloc.add(GetMentionedUserEvent(
        postId: widget.postData.id ?? '',
        onComplete: (mentionedList) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (mentionedList.isNotEmpty) {
                _socialUserList.clear();
                _socialUserList.addAll(mentionedList);
              }
            });
          }
        }));
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
                                shrinkWrap: true,
                                itemCount: _socialUserList.length,
                                itemBuilder: (context, index) {
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
      TapHandler(
        onTap: () {
          widget.onTapUserProfile(
              socialUserData?.id ?? '', socialUserData?.isFollowing == true);
        },
        child: Container(
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
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        socialUserData?.displayName?.takeIfNotEmpty() ??
                            socialUserData?.fullName?.takeIfNotEmpty() ??
                            socialUserData?.username ??
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
                        socialUserData?.username?.takeIfNotEmpty() ?? '',
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
                socialUserData,
                widget.postData.id ?? '',
              ),
            ],
          ),
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
                  return AppButton(
                    onPress: onTap,
                    height: 36.responsiveDimension,
                    width: 100.responsiveDimension,
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
                    width: 100.responsiveDimension,
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
                  width: 100.responsiveDimension,
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
          : const SizedBox.shrink(),
    );
  }
}
