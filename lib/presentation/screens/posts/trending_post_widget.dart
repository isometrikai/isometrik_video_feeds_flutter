import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class TrendingPostWidget extends StatefulWidget {
  const TrendingPostWidget({super.key});

  @override
  State<TrendingPostWidget> createState() => _TrendingPostWidgetState();
}

class _TrendingPostWidgetState extends State<TrendingPostWidget> {
  final _postBloc = IsmInjectionUtils.getBloc<PostBloc>();
  List<PostDataModel> _trendingPostList = [];

  @override
  Widget build(BuildContext context) => BlocBuilder<PostBloc, PostState>(
        buildWhen: (previousState, currentState) => currentState is TrendingPostsLoadedState,
        builder: (context, state) {
          if (state is TrendingPostsLoadedState) {
            _trendingPostList = state.trendingPosts ?? [];
          } else if (state is SavePostSuccessState) {
            final index = _trendingPostList.indexWhere((post) => post.postId == state.postId);
            if (index != -1) {
              setState(() {
                _trendingPostList[index] = _trendingPostList[index].copyWith(
                  isSavedPost: true,
                );
              });
            }
          } else if (state is FollowSuccessState) {
            final index = _trendingPostList.indexWhere((post) => post.userId == state.userId);
            if (index != -1) {
              setState(() {
                _trendingPostList[index] = _trendingPostList[index].copyWith(
                  followStatus: 1,
                );
              });
            }
          } else if (state is LikeSuccessState) {
            // final index = _trendingPostList.indexWhere((post) => post.postId == state.postId);
            // if (index != -1) {
            //   setState(() {
            //     _trendingPostList[index] = _trendingPostList[index].copyWith(
            //       liked: state.likeAction == LikeAction.like,
            //       likesCount: (state.likeAction == LikeAction.like)
            //           ? (_trendingPostList[index].likesCount ?? 0) + 1
            //           : (_trendingPostList[index].likesCount ?? 0) - 1,
            //     );
            //   });
            // }
          }

          return _trendingPostList.isEmptyOrNull == false
              ? RefreshIndicator(
                  onRefresh: () async {
                    // _postBloc.add(GetTrendingPostEvent(isLoading: false));
                  },
                  child: PageView.builder(
                    allowImplicitScrolling: true,
                    controller: _postBloc.reelsPageTrendingController,
                    clipBehavior: Clip.none,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      // Check if we're at 75% of the list
                      final threshold = (_trendingPostList.length * 0.75).floor();
                      if (index >= threshold) {
                        // _postBloc.add(GetTrendingPostEvent(
                        //   isLoading: false,
                        //   isPagination: true,
                        // ));
                      }
                    },
                    itemCount: _trendingPostList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) => IsrReelsVideoPlayerView(
                      thumbnail: _trendingPostList[index].thumbnailUrl1 ?? '',
                      key: Key(_trendingPostList[index].postId ?? ''),
                      postId: _trendingPostList[index].postId,
                      description: '',
                      isAssetUploading: false,
                      isFollow: _trendingPostList[index].followStatus == 1,
                      isSelfProfile: false,
                      firstName: _trendingPostList[index].firstName ?? '',
                      lastName: _trendingPostList[index].lastName ?? '',
                      name: '@${_trendingPostList[index].userName ?? ''}',
                      hasTags: _trendingPostList[index].hashTags ?? [],
                      profilePhoto: _trendingPostList[index].profilePic ?? '',
                      onTapVolume: () {},
                      isReelsMuted: false,
                      isReelsLongPressed: false,
                      onLongPressEnd: () {},
                      onDoubleTap: () async {},
                      onLongPressStart: () {},
                      mediaUrl: _trendingPostList[index].imageUrl1 ?? '',
                      mediaType: _trendingPostList[index].mediaType1?.toInt() ?? 0,
                      onTapUserProfilePic: () => {},
                      productList: _trendingPostList[index].productData,
                      isSavedPost: _trendingPostList[index].isSavedPost,
                      onPressFollowFollowing: () async {
                        if (_trendingPostList[index].userId != null) {
                          try {
                            final completer = Completer<bool>();

                            // _postBloc.add(FollowUserEvent(
                            //   followingId: _trendingPostList[index].userId!,
                            //   onComplete: (success) {
                            //     if (success) {
                            //       setState(() {
                            //         _trendingPostList[index] = _trendingPostList[index].copyWith(
                            //           followStatus: 1,
                            //         );
                            //       });
                            //     }
                            //     completer.complete(success);
                            //   },
                            // ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        }
                        return false;
                      },
                      onPressSave: () async {
                        if (_trendingPostList[index].postId != null) {
                          try {
                            final completer = Completer<bool>();

                            // _postBloc.add(SavePostEvent(
                            //   postId: _trendingPostList[index].postId!,
                            //   onComplete: (success) {
                            //     if (success) {
                            //       setState(() {
                            //         _trendingPostList[index] = _trendingPostList[index].copyWith(
                            //           isSavedPost: true,
                            //         );
                            //       });
                            //     }
                            //     completer.complete(success);
                            //   },
                            // ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        }
                        return false;
                      },
                      isLiked: _trendingPostList[index].liked ?? false,
                      likesCount: _trendingPostList[index].likesCount ?? 0,
                      onPressLike: () async {
                        if (_trendingPostList[index].postId != null) {
                          try {
                            final completer = Completer<bool>();

                            // _postBloc.add(LikePostEvent(
                            //   postId: _trendingPostList[index].postId!,
                            //   userId: _trendingPostList[index].userId!,
                            //   likeAction: _trendingPostList[index].liked == true ? LikeAction.unlike : LikeAction.like,
                            //   onComplete: (success) {
                            //     if (success) {
                            //       setState(() {
                            //         _trendingPostList[index] = _trendingPostList[index].copyWith(
                            //           liked: !(_trendingPostList[index].liked ?? false),
                            //           likesCount: (_trendingPostList[index].liked ?? false)
                            //               ? (_trendingPostList[index].likesCount ?? 0) - 1
                            //               : (_trendingPostList[index].likesCount ?? 0) + 1,
                            //         );
                            //       });
                            //     }
                            //     completer.complete(success);
                            //   },
                            // ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        }
                        return false;
                      },
                      // onPressReport: ({String message = '', String reason = ''}) async {
                      //   try {
                      //     final completer = Completer<bool>();
                      //
                      //     // _postBloc.add(ReportPostEvent(
                      //     //   postId: _trendingPostList[index].postId!,
                      //     //   message: reason,
                      //     //   reason: reason,
                      //     //   onComplete: (success) {
                      //     //     if (success) {
                      //     //       IsrVideoReelUtility.showToastMessage(
                      //     //         IsrTranslationFile.postReportedSuccessfully,
                      //     //       );
                      //     //
                      //     //       // Remove post from list
                      //     //       setState(() {
                      //     //         _trendingPostList.removeAt(index);
                      //     //       });
                      //     //
                      //     //       // Only scroll if there are more posts
                      //     //       if (_trendingPostList.isNotEmpty && index < _trendingPostList.length) {
                      //     //         _postBloc.reelsPageTrendingController.nextPage(
                      //     //           duration: const Duration(milliseconds: 300),
                      //     //           curve: Curves.easeInOut,
                      //     //         );
                      //     //       }
                      //     //     }
                      //     //     completer.complete(success);
                      //     //   },
                      //     // ));
                      //
                      //     return await completer.future;
                      //   } catch (e) {
                      //     return false;
                      //   }
                      // },
                    ),
                  ),
                )
              : const PostPlaceHolderView(
                  postSectionType: PostSectionType.trending,
                );
        },
      );
}
