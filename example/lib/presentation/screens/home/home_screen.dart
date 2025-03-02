import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
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
              return IsrPostView(
                tabDataModelList: [
                  TabDataModel(
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
                    onTapMore: (postId) async {
                      await _showMoreOptionsDialog(
                        onPressReport: ({String message = '', String reason = ''}) async {
                          try {
                            final completer = Completer<bool>();

                            _homeBloc.add(ReportPostEvent(
                              postId: postId,
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
                      return false;
                    },
                    onPressSave: (postId) async {
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
                  ),
                  TabDataModel(
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
                    onTapMore: (postId) async {
                      await _showMoreOptionsDialog(
                        onPressReport: ({String message = '', String reason = ''}) async {
                          try {
                            final completer = Completer<bool>();

                            _homeBloc.add(ReportPostEvent(
                              postId: postId,
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
                      return false;
                    },
                    onPressSave: (postId) async {
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
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (dialogContext) => MoreOptionsBottomSheet(
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
