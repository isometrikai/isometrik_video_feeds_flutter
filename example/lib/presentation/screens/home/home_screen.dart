import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
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

  @override
  void initState() {
    super.initState();
    _homeBloc.add(LoadHomeData());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.grey.shade100,
        body: BlocBuilder<HomeBloc, HomeState>(
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
              return isr.IsmPostView(
                tabDataModelList: [
                  isr.TabDataModel(
                    isCreatePostButtonVisible: true,
                    postSectionType: PostSectionType.following,
                    title: TranslationFile.following,
                    postList: state.followingPosts,
                    onCreatePost: () async {
                      final postDataModel = await InjectionUtils.getRouteManagement().goToCreatePostView();
                      return postDataModel;
                    },
                    onPressLike: (postId, userId, isLiked) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(LikePostEvent(
                          postId: postId,
                          userId: userId,
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
                    onTapMore: (postData, userId) async {
                      await _showMoreOptionsDialog(
                        onPressReport: ({String message = '', String reason = ''}) async {
                          try {
                            final completer = Completer<bool>();

                            _homeBloc.add(ReportPostEvent(
                              postId: postData.postId ?? '',
                              message: reason,
                              reason: reason,
                              onComplete: (success) {
                                if (success) {
                                  Utility.showToastMessage(
                                    TranslationFile.postReportedSuccessfully,
                                  );
                                }
                                completer.complete(success);
                              },
                            ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        },
                      );
                      return {'isSuccess': false};
                    },
                    onPressSave: (postId, isSavedPost) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(SavePostEvent(
                          postId: postId,
                          onComplete: (success) {
                            completer.complete(success);
                          },
                        ));

                        return await completer.future;
                      } catch (e) {
                        return false;
                      }
                    },
                    onPressFollow: (userId) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(FollowUserEvent(
                          followingId: userId,
                          onComplete: (success) {
                            completer.complete(success);
                          },
                        ));

                        return await completer.future;
                      } catch (e) {
                        return false;
                      }
                    },
                    onLoadMore: (postSectionType) async {
                      final completer = Completer<List<isr.PostDataModel>>();

                      _homeBloc.add(GetFollowingPostEvent(
                        isLoading: false,
                        isPagination: true,
                        onComplete: (posts) {
                          completer.complete(posts);
                        },
                      ));
                      final postResponse = await completer.future;
                      return postResponse;
                    },
                    onRefresh: () async {
                      _homeBloc.add(GetFollowingPostEvent(
                        isLoading: true,
                        isPagination: true,
                        isRefresh: true,
                      ));
                      return false;
                    },
                  ),
                  isr.TabDataModel(
                    isCreatePostButtonVisible: true,
                    postSectionType: PostSectionType.trending,
                    title: TranslationFile.trending,
                    postList: state.trendingPosts,
                    onCreatePost: () async {
                      final postDataModel = await InjectionUtils.getRouteManagement().goToCreatePostView();
                      return postDataModel;
                    },
                    onPressLike: (postId, userId, isLiked) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(LikePostEvent(
                          postId: postId,
                          userId: userId,
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
                    onTapMore: (postData, userId) async {
                      await _showMoreOptionsDialog(
                        onPressReport: ({String message = '', String reason = ''}) async {
                          try {
                            final completer = Completer<bool>();

                            _homeBloc.add(ReportPostEvent(
                              postId: postData.postId ?? '',
                              message: reason,
                              reason: reason,
                              onComplete: (success) {
                                if (success) {
                                  Utility.showToastMessage(
                                    TranslationFile.postReportedSuccessfully,
                                  );
                                }
                                completer.complete(success);
                              },
                            ));

                            return await completer.future;
                          } catch (e) {
                            return false;
                          }
                        },
                      );
                      return {'isSuccess': false};
                    },
                    onPressSave: (postId, isSavedPost) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(SavePostEvent(
                          postId: postId,
                          onComplete: (success) {
                            completer.complete(success);
                          },
                        ));

                        return await completer.future;
                      } catch (e) {
                        return false;
                      }
                    },
                    onPressFollow: (userId) async {
                      try {
                        final completer = Completer<bool>();

                        _homeBloc.add(FollowUserEvent(
                          followingId: userId,
                          onComplete: (success) {
                            completer.complete(success);
                          },
                        ));

                        return await completer.future;
                      } catch (e) {
                        return false;
                      }
                    },
                    onLoadMore: (postSectionType) async {
                      final completer = Completer<List<isr.PostDataModel>>();

                      _homeBloc.add(GetTrendingPostEvent(
                        isLoading: false,
                        isPagination: true,
                        onComplete: (posts) {
                          completer.complete(posts);
                        },
                      ));
                      final postResponse = await completer.future;
                      return postResponse;
                    },
                    onRefresh: () async {
                      _homeBloc.add(GetTrendingPostEvent(
                        isLoading: true,
                        isPagination: true,
                        isRefresh: true,
                      ));
                      return false;
                    },
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      );

  Future<void> _showMoreOptionsDialog({
    Future<bool> Function({String message, String reason})? onPressReport,
  }) async {
    await Utility.showBottomSheet(
      height: Dimens.percentHeight(0.25),
      child: MoreOptionsBottomSheet(
        onPressReport: ({String message = '', String reason = ''}) async {
          try {
            if (onPressReport != null) {
              final isReported = await onPressReport(message: message, reason: reason);
              return isReported;
            }

            return false;
          } catch (e) {
            return false;
          }
        },
      ),
    );
  }
}
