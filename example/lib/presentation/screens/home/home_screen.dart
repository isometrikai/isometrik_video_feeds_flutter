import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player/utils/isr_utils.dart';
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
                    timeLinePosts: state.timeLinePosts ?? [],
                    isCreatePostButtonVisible: true,
                    postSectionType: PostSectionType.following,
                    title: TranslationFile.following,
                    postList: state.followingPosts,
                    onCreatePost: () async {
                      final postDataModel =
                          await InjectionUtils.getRouteManagement().goToCreatePostView();
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
                              postId: postData.id ?? '',
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
                      final completer = Completer<List<isr.TimeLineData>>();

                      _homeBloc.add(GetTimeLinePostEvent(
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
                    timeLinePosts: [],
                    isCreatePostButtonVisible: true,
                    postSectionType: PostSectionType.trending,
                    title: TranslationFile.trending,
                    postList: state.trendingPosts,
                    onCreatePost: () async {
                      final postDataModel =
                          await InjectionUtils.getRouteManagement().goToCreatePostView();
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
                              postId: postData.id ?? '',
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
                      return [];
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

  Future<List<isr.SocialProductData>>? _handleCartAction(
      String productListJsonString, String productId) async {
    var featuredProductList = <isr.SocialProductData>[];

    try {
      final productDataList = _getSocialProductList(productListJsonString);
      final result = await Utility.showBottomSheet<List<SocialProductData>>(
        child: SocialProductsBottomSheet(
          products: productDataList,
        ),
      );
      if (result.isEmptyOrNull == false) {
        final productList = result as List<SocialProductData>;
        featuredProductList = _getFeaturedProductList(productList);
      }
    } catch (error, stackTrace) {
      Utility.debugCatchLog(error: error, stackTrace: stackTrace);
      debugPrint('Error handling cart action: $error');
    }
    return featuredProductList;
  }

  List<SocialProductData> _getSocialProductList(String? productJsonString) {
    final productDataModelList = <SocialProductData>[];
    if (productJsonString.isEmptyOrNull == false) {
      final jsonList = jsonDecode(productJsonString ?? '');

      final featuredProducts = (jsonList as List)
          .map((item) => SocialProductData.fromJson(item as Map<String, dynamic>))
          .toList();
      if (featuredProducts.isEmptyOrNull == false) {
        productDataModelList.addAll(featuredProducts);
      }
    }
    debugPrint('productDataModelList: $productDataModelList');
    return productDataModelList;
  }

  List<isr.SocialProductData> _getFeaturedProductList(List<SocialProductData>? productDataList) {
    var featuredProducts = <isr.SocialProductData>[];
    if (productDataList.isEmptyOrNull == true) return featuredProducts;
    final productJsonString =
        jsonEncode(productDataList?.map((product) => product.toJson()).toList());
    if (productJsonString.isEmptyOrNull == false) {
      final jsonList = jsonDecode(productJsonString);
      featuredProducts = (jsonList as List)
          .map((item) => isr.SocialProductData.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return featuredProducts;
  }
}
