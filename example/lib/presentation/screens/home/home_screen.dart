import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeBloc = InjectionUtils.getBloc<HomeBloc>();
  var _isLikeLoading = false;

  @override
  void initState() {
    _homeBloc.add(LoadHomeData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) => isr.IsmPostView(
        tabDataModelList: [
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.forYou,
            title: TranslationFile.forYou,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.following,
            title: TranslationFile.following,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.trending,
            title: TranslationFile.trending,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.myPost,
            title: TranslationFile.myPost,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.savedPost,
            title: TranslationFile.saved,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.myTaggedPost,
            title: TranslationFile.tagged,
            reelsDataList: [],
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.singlePost,
            title: TranslationFile.single,
            reelsDataList: [],
            postId: 'post_98e927787ec5',
            //hardCoded post id
            startingPostIndex: 0,
          ),
          isr.TabDataModel(
            postSectionType: isr.PostSectionType.otherUserPost,
            title: TranslationFile.others,
            reelsDataList: [],
            userId: '67c69bb7e0295f209db1d0e9',
            //hardCoded userId of user asjadibrahim10215
            startingPostIndex: 0,
          ),
        ], // ✅ Already working!
        tabConfig: isr.TabConfig(
          autoMoveToNextPost: true,
          tabCallBackConfig: isr.TabCallBackConfig(
            onChangeOfTab: (tabDataModel) {
              //   isr.IsmDataProvider.instance.fetchCollectionList(
              //     page: 1,
              //     pageSize: 10,
              //     onSuccess: (result, statusCode) {
              //       debugPrint('result.......$result');
              //     },
              //   );
            },
          ),
        ),
    postConfig: const isr.PostConfig(
      autoMoveToNextMedia: true
    ),
      );

  isr.ReelsWidgetBuilder buildFooter(TimeLineData postData) =>
      isr.ReelsWidgetBuilder(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop button
              // if ((widget.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  // if (widget.onTapCartIcon != null) {
                  //   widget.onTapCartIcon!();
                  // }
                },
                child: Container(
                  padding: Dimens.edgeInsetsSymmetric(
                    horizontal: Dimens.twelve,
                    vertical: Dimens.eight,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white, // Set to white for the background
                    borderRadius:
                        BorderRadius.circular(Dimens.ten), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.applyOpacity(0.1), // Light shadow
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2), // Shadow offset
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImage.svg(AssetConstants.icAddCartItem),
                      Dimens.boxWidth(Dimens.eight),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shop',
                            style: Styles.primaryText12
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Dimens.boxHeight(Dimens.four),
                          Text(
                            '3 products',
                            style: Styles.primaryText10
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Dimens.boxHeight(Dimens.sixteen),
              // ],

              // Profile info and description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right column - Username, follow button, and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username and follow button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: TapHandler(
                                      onTap: () {
                                        // if (widget.onTapUserProfilePic != null) {
                                        //   widget.onTapUserProfilePic!();
                                        // }
                                      },
                                      child: Text(
                                        postData.user?.username ?? '',
                                        style: Styles.white14.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // if (!widget.isSelfProfile) ...[
                                  //   Dimens.boxWidth(Dimens.eight),
                                  //   // Only show follow button if not following
                                  //   if (!widget.isFollow &&
                                  //       !_isFollowLoading &&
                                  //       !widget.isSelfProfile)
                                  //     Container(
                                  //       height: Dimens.twentyFour,
                                  //       decoration: BoxDecoration(
                                  //         color: Theme.of(context).primaryColor,
                                  //         borderRadius: BorderRadius.circular(Dimens.twenty),
                                  //       ),
                                  //       child: MaterialButton(
                                  //         minWidth: Dimens.sixty,
                                  //         height: Dimens.twentyFour,
                                  //         padding: Dimens.edgeInsetsSymmetric(
                                  //           horizontal: Dimens.twelve,
                                  //         ),
                                  //         shape: RoundedRectangleBorder(
                                  //           borderRadius: BorderRadius.circular(Dimens.twenty),
                                  //         ),
                                  //         onPressed: _callFollowFunction,
                                  //         child: Text(
                                  //           IsrTranslationFile.follow,
                                  //           style: IsrStyles.white12.copyWith(
                                  //             fontWeight: FontWeight.w600,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   // Show loading indicator while API call is in progress
                                  //   if (_isFollowLoading)
                                  //     SizedBox(
                                  //       width: Dimens.sixty,
                                  //       height: Dimens.twentyFour,
                                  //       child: Center(
                                  //         child: SizedBox(
                                  //           width: Dimens.sixteen,
                                  //           height: Dimens.sixteen,
                                  //           child: CircularProgressIndicator(
                                  //             strokeWidth: 2,
                                  //             valueColor: AlwaysStoppedAnimation<Color>(
                                  //                 Theme.of(context).primaryColor),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     ),
                                  // ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (postData.caption.isEmptyOrNull == false) ...[
                          Dimens.boxHeight(Dimens.four),
                          RichText(
                            text: TextSpan(
                              children: [
                                // Description
                                TextSpan(
                                  text: postData.caption,
                                  style: Styles.white14.copyWith(
                                    color: AppColors.white.applyOpacity(0.9),
                                  ),
                                ),
                                // // Read More / Read Less
                                // if ((postData.caption?.length ?? 0) > _maxLengthToShow)
                                //   TextSpan(
                                //     text: _isExpandedDescription
                                //         ? ' ${IsrTranslationFile.viewLess}'
                                //         : ' ${IsrTranslationFile.viewMore}',
                                //     style: IsrStyles.white14.copyWith(
                                //       fontWeight: FontWeight.w700,
                                //     ),
                                //     recognizer: _tapGestureRecognizer
                                //       ?..onTap = () {
                                //         setState(() {
                                //           _isExpandedDescription = !_isExpandedDescription;
                                //         });
                                //       },
                                //   ),
                              ],
                            ),
                          ),
                        ],
                        if (postData.caption.isEmptyOrNull == false &&
                            (postData.caption?.length ?? 0) > 100)
                          Padding(
                            padding: Dimens.edgeInsets(left: Dimens.eight),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // _isExpandedDescription = !_isExpandedDescription;
                                });
                              },
                              child: Text(
                                'Read More',
                                // !_isExpandedDescription ? 'Read More' : 'Read Less',
                                style: Styles.white14.copyWith(
                                  color: AppColors.appColor.applyOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // if ((widget.productCount ?? 0) > 0) ...[
              //   Dimens.boxHeight(Dimens.eight),
              //   _buildCommissionTag(),
              // ],
            ],
          ),
        ),
      );

  isr.ReelsWidgetBuilder buildActionButtons(TimeLineData postData) =>
      isr.ReelsWidgetBuilder(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: Dimens.edgeInsetsAll(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TapHandler(
                borderRadius: Dimens.thirty,
                onTap: () {
                  // if (widget.onTapUserProfilePic != null) {
                  //   widget.onTapUserProfilePic!();
                  // }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(Dimens.thirty),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.applyOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AppImage.network(
                    postData.user?.avatarUrl ?? '',
                    width: Dimens.thirtySix,
                    height: Dimens.thirtySix,
                    isProfileImage: true,
                    name: '${postData.user?.fullName ?? ''}',
                  ),
                ),
              ),
              Dimens.boxHeight(Dimens.fifteen),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor, // Blue background
                ),
                child: IconButton(
                  onPressed: () async {},
                  icon: const Icon(
                    Icons.add, // Simple plus icon
                    color: AppColors.white,
                  ),
                ),
              ),
              Dimens.boxHeight(Dimens.five),
              Text(
                'Create',
                style: Styles.white12,
              ),
              Dimens.boxHeight(Dimens.ten),

              // if (widget.mediaType == kVideoType) ...[
              //   _buildActionButton(
              //     icon: _isMuted ? AssetConstants.icVolumeMute : AssetConstants.icVolumeUp,
              //     label: _isMuted ? IsrTranslationFile.unmute : IsrTranslationFile.mute,
              //     onTap: _toggleSound,
              //   ),
              //   Dimens.boxHeight(Dimens.twenty),
              // ],
              StatefulBuilder(
                builder: (context, setState) => _buildActionButton(
                  icon: postData.isLiked == true
                      ? AssetConstants.icLikeSelected
                      : AssetConstants.icLikeUnSelected,
                  label: postData.engagementMetrics?.likeTypes?.like.toString(),
                  onTap: () {
                    _callLikeFunction(postData, setState);
                  },
                  isLoading: _isLikeLoading,
                ),
              ),
              // _buildActionButton(
              //   icon: postData.isLiked == true
              //       ? AssetConstants.icLikeSelected
              //       : AssetConstants.icLikeUnSelected,
              //   label: postData.engagementMetrics?.likeTypes?.like.toString(),
              //   onTap: () {},
              // ),
              Dimens.boxHeight(Dimens.twenty),
              _buildActionButton(
                icon: AssetConstants.icCommentIcon,
                label: postData.engagementMetrics?.comments?.toString(),
                onTap: () {
                  // if (widget.onTapComment != null) {
                  //   widget.onTapComment!();
                  // }
                },
              ),
              Dimens.boxHeight(Dimens.twenty),
              _buildActionButton(
                icon: AssetConstants.icShareIcon,
                label: 'Share',
                onTap: () {
                  // if (widget.onTapShare != null) {
                  //   widget.onTapShare!();
                  // }
                },
              ),
              // if (widget.postStatus != 0) ...[
              //   Dimens.boxHeight(Dimens.twenty),
              //   _buildActionButton(
              //     icon: widget.isSavedPost == true
              //         ? AssetConstants.icSaveSelected
              //         : AssetConstants.icSaveUnSelected,
              //     label:
              //     widget.isSavedPost == true ? IsrTranslationFile.saved : IsrTranslationFile.save,
              //     onTap: _callSaveFunction,
              //     isLoading: _isSaveLoading,
              //   ),
              // ],
              Dimens.boxHeight(Dimens.twenty),
              _buildActionButton(
                icon: AssetConstants.icMoreIcon,
                label: '',
                onTap: () async {
                  // if (widget.onPressMoreButton != null) {
                  //   widget.onPressMoreButton!();
                  // }
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildActionButton({
    required String icon,
    String? label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: isLoading
                ? SizedBox(
                    width: Dimens.twentyFour,
                    height: Dimens.twentyFour,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                : AppImage.svg(icon),
          ),
          if (label.isEmptyOrNull == false) ...[
            Dimens.boxHeight(Dimens.four),
            Text(
              label ?? '',
              style: Styles.white12.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );

  Future<void> _callLikeFunction(
      TimeLineData postData, StateSetter setState) async {
    _isLikeLoading = true;
    setState.call(() {});
    var success = false;
    try {
      try {
        final completer = Completer<bool>();

        _homeBloc.add(LikePostEvent(
            postId: postData.id ?? '',
            userId: postData.user?.id ?? '',
            likeAction:
                postData.isLiked == true ? LikeAction.unlike : LikeAction.like,
            onComplete: (success) {
              completer.complete(success);
            }));
        success = true;
      } catch (e) {
        return;
      }

      if (success) {
        // Toggle like state
        postData.isLiked = !(postData.isLiked ?? false);

        // Update count based on action
        final currentCount = postData.engagementMetrics?.likeTypes?.like ?? 0;
        if (postData.isLiked == true) {
          postData.engagementMetrics?.likeTypes?.like = currentCount + 1;
        } else {
          postData.engagementMetrics?.likeTypes?.like =
              (currentCount > 0) ? currentCount - 1 : 0;
        }
      }
      setState.call(() {});
    } finally {
      _isLikeLoading = false;
      setState.call(() {});
    }
  }
}
