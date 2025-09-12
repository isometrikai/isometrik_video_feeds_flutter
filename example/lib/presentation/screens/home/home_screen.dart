import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  var _myUserId = '';

  @override
  void initState() {
    _homeBloc.add(LoadHomeData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black.applyOpacity(0.50),
        extendBodyBehindAppBar: true,
        body: BlocBuilder<HomeBloc, HomeState>(
          buildWhen: _filterBuildStates,
          builder: (context, state) {
            if (state is HomeLoading) {
              return state.isLoading == true
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : const SizedBox.shrink();
            }

            if (state is HomeError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is HomeLoaded) {
              _myUserId = state.userId;
              return isr.IsmPostView(
                key: ValueKey(
                    state.timeLinePosts), // will rebuild if list changes
                tabDataModelList: [
                  isr.TabDataModel(
                    title: 'Following',
                    onRefresh: _handleFollowingRefresh,
                    reelsDataList:
                        state.timeLinePosts?.map(_getReelData).toList() ?? [],
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      );

  Future<bool> _handleFollowingRefresh() async {
    _homeBloc.add(GetTimeLinePostEvent(
      isLoading: false,
      isPagination: false,
      isRefresh: true,
    ));
    return false;
  }

  bool _filterBuildStates(HomeState previous, HomeState current) =>
      current is! LoadPostCommentState &&
      current is! LoadingPostComment &&
      current is! PostDetailsLoading &&
      current is! PostDetailsLoaded;

  isr.ReelsData _getReelData(TimeLineData postData) => isr.ReelsData(
        postSetting: isr.PostSetting(
          isProfilePicVisible: true,
          isCreatePostButtonVisible: true,
          isCommentButtonVisible: postData.settings?.commentsEnabled == true,
          isSaveButtonVisible: true,
          isLikeButtonVisible: true,
          isShareButtonVisible: true,
          isMoreButtonVisible: true,
          isFollowButtonVisible: true,
          isUnFollowButtonVisible: true,
        ),
        mentions: postData.tags != null &&
                postData.tags?.mentions.isEmptyOrNull == false
            ? postData.tags?.mentions?.map(_getMentionMetaData).toList()
            : null,
        tagDataList: postData.tags != null &&
                postData.tags?.hashtags.isEmptyOrNull == false
            ? postData.tags?.hashtags?.map(_getMentionMetaData).toList()
            : null,
        placeDataList: postData.tags != null &&
                postData.tags?.places.isEmptyOrNull == false
            ? postData.tags?.places?.map(_getPlaceMetaData).toList()
            : null,
        onTapMentionTag: (mention) {},
        postId: postData.id,
        onCreatePost: () async => await _handleCreatePost(),
        mediaMetaDataList:
            postData.media?.map(_getMediaMetaData).toList() ?? [],
        // actionWidget: _buildActionButtons(postData),
        // footerWidget: _buildFooter(postData),
        userId: postData.user?.id ?? '',
        userName: postData.user?.username ?? '',
        profilePhoto: postData.user?.avatarUrl ?? '',
        firstName: '',
        lastName: '',
        likesCount: postData.engagementMetrics?.likeTypes?.love?.toInt() ?? 0,
        commentCount: postData.engagementMetrics?.comments?.toInt() ?? 0,
        isFollow: true,
        isLiked: postData.isLiked,
        isSavedPost: false,
        isVerifiedUser: false,
        productCount: postData.tags?.products?.length ?? 0,
        description: postData.caption ?? '',
        onTapComment: (totalCommentsCount) async {
          final result =
              await _handleCommentAction(postData.id ?? '', totalCommentsCount);
          return result;
        },
        onPressMoreButton: () async {
          final result = await _handleMoreOptions(postData);
          return result;
        },
        onPressLike: (isLiked) async {
          try {
            final completer = Completer<bool>();

            _homeBloc.add(LikePostEvent(
              postId: postData.id ?? '',
              userId: postData.user?.id ?? '',
              likeAction: isLiked ? LikeAction.unlike : LikeAction.like,
              onComplete: (success) {
                completer.complete(success);
              },
            ));
            return await completer.future;
          } catch (e) {
            return false;
          }
        },
        onPressSave: (isSavedPost) async {
          try {
            final completer = Completer<bool>();

            _homeBloc.add(SavePostEvent(
              postId: postData.id ?? '',
              isSaved: isSavedPost,
              onComplete: (success) {
                completer.complete(success);
              },
            ));
            return await completer.future;
          } catch (e) {
            return false;
          }
        },
        onPressFollow: (userId, isFollow) async {
          try {
            final completer = Completer<bool>();

            _homeBloc.add(FollowUserEvent(
              followingId: userId,
              onComplete: (success) {
                completer.complete(success);
              },
              followAction:
                  isFollow ? FollowAction.unfollow : FollowAction.follow,
            ));

            return await completer.future;
          } catch (e) {
            return false;
          }
        },
        onTapCartIcon: () {
          _handleCartAction(postData);
        },
      );

  /// Handles the more options menu for a post
  Future<dynamic> _handleMoreOptions(TimeLineData postDataModel) async {
    try {
      return await _showMoreOptionsDialog(
        onPressReport: ({String message = '', String reason = ''}) async {
          final completer = Completer<bool>();
          _homeBloc.add(
            ReportPostEvent(
              postId: postDataModel.id ?? '',
              message: message,
              reason: reason,
              onComplete: (success) {
                if (success) {
                  Utility.showToastMessage(
                      TranslationFile.postReportedSuccessfully);
                }
                completer.complete(success);
              },
            ),
          );
          return await completer.future;
        },
        onDeletePost: () async {
          final result = await _showDeletePostDialog(context);
          if (result == true) {
            final completer = Completer<bool>();
            _homeBloc.add(
              DeletePostEvent(
                postId: postDataModel.id ?? '',
                onComplete: (success) {
                  if (success) {
                    Utility.showToastMessage(
                        TranslationFile.postDeletedSuccessfully);
                  }
                  completer.complete(success);
                },
              ),
            );
            return await completer.future;
          }
          return false;
        },
        isSelfProfile: postDataModel.user?.id == _myUserId,
        onEditPost: () async {
          final postDataString =
              await _showEditPostDialog(context, postDataModel);
          return postDataString ?? '';
        },
      );
    } catch (e) {
      debugPrint('Error handling more options: $e');
      return false;
    }
  }

  Future<dynamic> _showMoreOptionsDialog({
    Future<bool> Function({String message, String reason})? onPressReport,
    Future<bool> Function()? onDeletePost,
    Future<String> Function()? onEditPost,
    bool? isSelfProfile,
  }) async {
    final completer = Completer<dynamic>();
    await Utility.showBottomSheet(
      isDismissible: true,
      child: MoreOptionsBottomSheet(
        onPressReport: ({String message = '', String reason = ''}) async {
          try {
            if (onPressReport != null) {
              final isReported =
                  await onPressReport(message: message, reason: reason);
              completer.complete(isReported);
              return isReported;
            }
            return false;
          } catch (e) {
            return false;
          }
        },
        isSelfProfile: isSelfProfile == true,
        onDeletePost: () async {
          if (onDeletePost != null) {
            final isDeleted = await onDeletePost();
            completer.complete(isDeleted);
            return isDeleted;
          }
          return false;
        },
        onEditPost: () async {
          if (onEditPost != null) {
            final postDataString = await onEditPost();
            if (postDataString.isEmptyOrNull == false) {
              final postData = TimeLineData.fromMap(
                  jsonDecode(postDataString) as Map<String, dynamic>);
              final reelData = _getReelData(postData);
              completer.complete(reelData);
            }
            return postDataString;
          }
          return '';
        },
      ),
    );
    return completer.future;
  }

  Future<bool?> _showDeletePostDialog(BuildContext context) => showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationFile.deletePost,
                  style: Styles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.verticalSpace,
                Text(
                  TranslationFile.deletePostConfirmation,
                  style: Styles.primaryText14.copyWith(
                    color: '4A4A4A'.toHexColor,
                  ),
                ),
                32.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: TranslationFile.delete,
                      width: 102.scaledValue,
                      onPress: () => Navigator.of(context).pop(true),
                      backgroundColor: 'E04755'.toHexColor,
                    ),
                    AppButton(
                      title: TranslationFile.cancel,
                      width: 102.scaledValue,
                      onPress: () => Navigator.of(context).pop(false),
                      backgroundColor: 'F6F6F6'.toHexColor,
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<String?> _showEditPostDialog(
          BuildContext context, TimeLineData postDataModel) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationFile.editPost,
                  style: Styles.primaryText18
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                16.verticalSpace,
                Text(
                  TranslationFile.editPostConfirmation,
                  style: Styles.primaryText14.copyWith(
                    color: '4A4A4A'.toHexColor,
                  ),
                ),
                32.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AppButton(
                      title: TranslationFile.yes,
                      width: 102.scaledValue,
                      onPress: () async {
                        final postDataString =
                            await _handleEditPost(postDataModel);
                        Navigator.of(context).pop(postDataString ?? '');
                      },
                      backgroundColor: '006CD8'.toHexColor,
                    ),
                    AppButton(
                      title: TranslationFile.cancel,
                      width: 102.scaledValue,
                      onPress: () => Navigator.of(context).pop(''),
                      backgroundColor: 'F6F6F6'.toHexColor,
                      textColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Future<String?> _handleEditPost(TimeLineData postDataModel) async {
    final postDataString = await InjectionUtils.getRouteManagement()
        .goToCreatePostView(postData: postDataModel);
    return postDataString;
  }

  Future<List<ProductDataModel>> _handleCartAction(
      TimeLineData postData) async {
    var featuredProductList = <ProductDataModel>[];
    try {
      final productIds = <String>[];
      final socialProductList =
          postData.tags?.products ?? <SocialProductData>[];
      for (final productItem in socialProductList) {
        productIds.add(productItem.id ?? '');
      }

      // final productDataList = _getSocialProductList(productJsonString);
      final result = await Utility.showBottomSheet<List<ProductDataModel>>(
        child: SocialProductsBottomSheet(
          productIds: productIds,
          // products: productDataList,
          products: [],
        ),
      );
      if (result.isEmptyOrNull == false) {
        final productList = result as List<ProductDataModel>;
        featuredProductList = productList;
      }
    } catch (error, stackTrace) {
      Utility.debugCatchLog(error: error, stackTrace: stackTrace);
      debugPrint('Error handling cart action: $error');
    }
    return featuredProductList;
  }

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
                        color: Colors.black.changeOpacity(0.1), // Light shadow
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
                                  color: AppColors.appColor.changeOpacity(0.6),
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
                        color: Colors.black.changeOpacity(0.2),
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
          if (label.isStringEmptyOrNull == false) ...[
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

  // Interaction handlers
  Future<isr.ReelsData?> _handleCreatePost() async {
    final completer = Completer<isr.ReelsData>();
    final postDataModelString =
        await InjectionUtils.getRouteManagement().goToCreatePostView();
    if (postDataModelString.isStringEmptyOrNull == false) {
      final postDataModel = TimeLineData.fromMap(
          jsonDecode(postDataModelString!) as Map<String, dynamic>);
      final reelsData = _getReelData(postDataModel);
      completer.complete(reelsData);
    }
    return completer.future;
  }

  /// Handles comment action
  Future<int> _handleCommentAction(
      String postId, int totalCommentsCount) async {
    final completer = Completer<int>();

    final result = await Utility.showBottomSheet<int>(
      child: CommentsBottomSheet(
        postId: postId,
        totalCommentsCount: totalCommentsCount,
        onTapProfile: (userId) {
          context.pop(totalCommentsCount);
        },
      ),
      isDarkBG: true,
      backgroundColor: Colors.black,
    );
    completer.complete(result ?? 0);

    return completer.future;
  }

  isr.MediaMetaData _getMediaMetaData(MediaData mediaData) => isr.MediaMetaData(
        mediaType: mediaData.mediaType == 'image' ? 0 : 1,
        mediaUrl: mediaData.url ?? '',
        thumbnailUrl: mediaData.previewUrl ?? '',
      );

  isr.MentionMetaData _getMentionMetaData(MentionData mentionData) =>
      isr.MentionMetaData(
        userId: mentionData.userId,
        username: mentionData.username,
        name: mentionData.name,
        avatarUrl: mentionData.avatarUrl,
        tag: mentionData.tag,
        textPosition: mentionData.textPosition != null
            ? isr.MentionPosition(
                start: mentionData.textPosition?.start,
                end: mentionData.textPosition?.end,
              )
            : null,
        mediaPosition: mentionData.mediaPosition != null
            ? isr.MediaPosition(
                position: mentionData.mediaPosition?.position,
                x: mentionData.mediaPosition?.x,
                y: mentionData.mediaPosition?.y,
              )
            : null,
      );

  isr.PlaceMetaData _getPlaceMetaData(TaggedPlace placeData) =>
      isr.PlaceMetaData(
        address: placeData.address,
        city: placeData.city,
        coordinates: placeData.coordinates,
        country: placeData.country,
        description: placeData.placeData?.description,
        placeId: placeData.placeId,
        placeName: placeData.placeName,
        placeType: placeData.placeType,
        postalCode: placeData.postalCode,
        state: placeData.state,
      );
}
