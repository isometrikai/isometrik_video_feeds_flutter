import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart'
    as mc;
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PostAttributeView extends StatefulWidget {
  const PostAttributeView({
    super.key,
    required this.isEditMode,
    this.onTagProduct,
    this.postData,
    this.newMediaDataList,
  });

  final bool? isEditMode;
  final List<MediaData>? newMediaDataList;
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onTagProduct;
  final TimeLineData? postData;

  @override
  State<PostAttributeView> createState() => _PostAttributeViewState();
}

class _PostAttributeViewState extends State<PostAttributeView>
    with WidgetsBindingObserver {
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitializingStates = {};
  var _mediaDataList = <MediaData>[];
  PostAttributeClass? _postAttributeClass;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _captionInputKey = GlobalKey();
  bool _isCaptionFocused = false;
  bool isKeyboardVisible = false;

  // State variables for tracking changes
  bool _isPostButtonEnabled = true;
  final List<ProductDataModel> _linkedProducts = [];

  // Description and mention handling
  final _descriptionController = TextEditingController();
  final int _maxLength = 200;
  final List<MentionData> _mentionedUsers = [];
  final List<MentionData> _hashTags = [];

  // Original values for comparison in edit mode
  PostAttributeClass? _originalPostAttributeClass;
  var _isEditMode = false;
  DateTime? _selectedDate;

  bool _isDialogOpen = false;

  // Schedule post variables - sync with bloc
  late final CreatePostBloc _createPostBloc;
  late final UploadProgressCubit _progressCubit;
  late final IsmSocialActionCubit _socialActionCubit;

  @override
  void initState() {
    _createPostBloc = context.getOrCreateBloc();
    _progressCubit = context.getOrCreateBloc();
    _socialActionCubit = context.getOrCreateBloc();
    WidgetsBinding.instance.addObserver(this);
    _isEditMode = widget.isEditMode ?? false;
    final editData = widget.postData;
    if (_isEditMode && editData != null) {
      _createPostBloc.add(EditPostEvent(postData: editData));
    } else if (!_isEditMode && widget.newMediaDataList?.isNotEmpty == true) {
      _createPostBloc.add(
          CreatePostInitialEvent(newMediaDataList: widget.newMediaDataList));
    } else {
      Navigator.pop(context);
    }
    super.initState();
  }

  void _prepareData({PostAttributeClass? postAttributeClass}) {
    _postAttributeClass = postAttributeClass;
    _mediaDataList = _postAttributeClass?.mediaDataList ?? [];

    // Load existing linked products
    _linkedProducts.clear();
    _linkedProducts.addAll(_postAttributeClass?.linkedProducts ?? []);

    // Load existing description and mentions

    _descriptionController.text = _createPostBloc.descriptionText;

    // Load mentioned users and hashtags from bloc
    _mentionedUsers.clear();
    _mentionedUsers.addAll(_postAttributeClass?.mentionedUserList ?? []);

    _hashTags.clear();
    _hashTags.addAll(_createPostBloc.hashTagDataList);

    // Set description in PostAttributeClass if not already set
    _postAttributeClass?.createPostRequest?.caption ??=
        _createPostBloc.descriptionText;

    // Set default values for new posts
    _postAttributeClass?.allowComment ??= true;
    _postAttributeClass?.allowSave ??= true;

    // Store original values for change detection in edit mode
    _originalPostAttributeClass = _copyPostAttributeClass(_postAttributeClass);

    // Initialize button state
    _updatePostButtonState();

    for (var mediaData in _mediaDataList) {
      if (mediaData.mediaType?.mediaType == MediaType.video) {
        initializeVideoPlayer(mediaData);
      }
    }
  }

  /// Method For Initialize Video Player
  Future<void> initializeVideoPlayer(
    MediaData mediaData,
  ) async {
    if (mediaData.mediaType?.mediaType == MediaType.video) {
      // Determine the video source URL (local or remote)
      String? videoUrl;
      String videoKey;

      // Check for local path first (for new uploads)
      if (mediaData.localPath?.isNotEmpty == true) {
        videoUrl = mediaData.localPath!;
        videoKey = videoUrl;
      }
      // Check for remote URL (for existing/edited posts)
      else if (mediaData.url?.isNotEmpty == true) {
        videoUrl = mediaData.url!;
        videoKey = videoUrl;
      } else {
        // No valid video URL found
        debugPrint('No valid video URL found for media data');
        return;
      }

      // Return if video URL is empty
      if (videoUrl.isEmpty) {
        debugPrint('Video URL is empty');
        return;
      }

      // Skip if already initialized
      if (_videoControllers.containsKey(videoKey)) return;

      _videoInitializingStates[videoKey] = true;
      setState(() {});

      try {
        VideoPlayerController controller;

        // Check if it's a local file or remote URL
        if (Utility.isLocalUrl(videoUrl)) {
          // Local file
          controller = VideoPlayerController.file(File(videoUrl));
          debugPrint('Initializing video player for local file: $videoUrl');
        } else {
          // Remote URL
          controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          debugPrint('Initializing video player for remote URL: $videoUrl');
        }

        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(1.0);

        _videoControllers[videoKey] = controller;
        _videoInitializingStates[videoKey] = false;
        setState(() {});

        debugPrint('Video player initialized successfully for: $videoUrl');
      } catch (e) {
        debugPrint('Error initializing video player for $videoUrl: $e');
        _videoInitializingStates[videoKey] = false;
        setState(() {});
      }
    }
  }

  /// Build video player widget for specific media
  Widget _buildVideoPlayer(MediaData media) {
    // Use the same key logic as in initializeVideoPlayer
    String videoKey;
    if (media.localPath?.isNotEmpty == true) {
      videoKey = media.localPath!;
    } else if (media.url?.isNotEmpty == true) {
      videoKey = media.url!;
    } else {
      return const Center(child: Icon(Icons.videocam_off, size: 64));
    }

    final isInitializing = _videoInitializingStates[videoKey] ?? false;
    final controller = _videoControllers[videoKey];

    if (isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Icon(Icons.videocam, size: 64));
    }

    return VisibilityDetector(
      key: Key('video_$videoKey'),
      onVisibilityChanged: (VisibilityInfo info) {
        // Pause video if it's not fully visible (visibility < 1.0)
        if (info.visibleFraction < 1.0 && controller.value.isPlaying) {
          controller.pause();
          setState(() {});
        }
      },
      child: GestureDetector(
        onTap: () => _playPause(controller),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            if (!controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _descriptionController.dispose();
    _scrollController.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitializingStates.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app resumes (user returns to this screen), check for changes
      debugPrint('App resumed - checking for linked product changes');
      _updatePostButtonState();
    }
  }

  /// Create a deep copy of PostAttributeClass for comparison
  PostAttributeClass? _copyPostAttributeClass(PostAttributeClass? original) {
    if (original == null) return null;

    final copy = PostAttributeClass();
    copy.mentionedUserList =
        List<MentionData>.from(original.mentionedUserList ?? []);
    copy.hashTagDataList =
        List<MentionData>.from(original.hashTagDataList ?? []);
    copy.taggedPlaces = List<TaggedPlace>.from(original.taggedPlaces ?? []);
    copy.mediaDataList = List<MediaData>.from(original.mediaDataList ?? []);
    copy.linkedProducts =
        List<ProductDataModel>.from(original.linkedProducts ?? []);
    copy.allowComment = original.allowComment ?? true;
    copy.allowSave = original.allowSave ?? true;

    // Deep copy the createPostRequest
    if (original.createPostRequest != null) {
      final originalRequest = original.createPostRequest!;
      final copyRequest = CreatePostRequest();
      copyRequest.caption = originalRequest.caption;
      copyRequest.tags = originalRequest.tags;
      copyRequest.settings = originalRequest.settings;
      copy.createPostRequest = copyRequest;
    }

    return copy;
  }

  /// Update post button enabled state
  void _updatePostButtonState() {
    debugPrint('=== _updatePostButtonState ===');
    debugPrint('_isEditMode: $_isEditMode');
    debugPrint('allowComment: ${_postAttributeClass?.allowComment}');
    debugPrint('allowSave: ${_postAttributeClass?.allowSave}');

    // Simple and clear logic:
    // - If it's a new post: ALWAYS enabled
    // - If it's edit mode: Only enabled if there are changes
    final shouldEnable = _isEditMode ? _hasChanges() : true;

    debugPrint('shouldEnable result: $shouldEnable');
    debugPrint('Current _isPostButtonEnabled: $_isPostButtonEnabled');

    if (_isPostButtonEnabled != shouldEnable) {
      setState(() {
        _isPostButtonEnabled = shouldEnable;
      });
      debugPrint('✅ Button state updated to: $_isPostButtonEnabled');
    } else {
      debugPrint('⚪ Button state unchanged');
    }
    debugPrint('=== END _updatePostButtonState ===');
  }

  /// Check if there are any changes compared to original data
  bool _hasChanges() {
    if (_originalPostAttributeClass == null || _postAttributeClass == null) {
      return true; // If we can't compare, assume changes
    }

    final original = _originalPostAttributeClass!;
    final current = _postAttributeClass!;

    // Check mentioned users changes
    if (!_compareMentionLists(
        original.mentionedUserList, current.mentionedUserList)) {
      debugPrint('Changes detected in mentioned users');
      return true;
    }

    // Check hashtags changes
    if (!_compareMentionLists(
        original.hashTagDataList, current.hashTagDataList)) {
      debugPrint('Changes detected in hashtags');
      return true;
    }

    // Check location tags changes
    if (!_compareLocationTags(original.taggedPlaces, current.taggedPlaces)) {
      debugPrint('Changes detected in location tags');
      return true;
    }

    // Check media data changes
    if (!_compareMediaData(original.mediaDataList, current.mediaDataList)) {
      debugPrint('Changes detected in media data');
      return true;
    }

    // check for coverImage change
    if (Utility.isLocalUrl(_postAttributeClass
            ?.createPostRequest?.previews?.firstOrNull?.localFilePath ??
        '')) {
      debugPrint('Changes detected in preview data');
      return true;
    }

    // Check settings changes
    if (original.allowComment != current.allowComment ||
        original.allowSave != current.allowSave) {
      debugPrint('Changes detected in settings');
      return true;
    }

    // Check description changes from createPostRequest
    final originalCaption = original.createPostRequest?.caption ?? '';
    final currentCaption = current.createPostRequest?.caption ?? '';
    if (originalCaption != currentCaption) {
      debugPrint('Changes detected in description');
      return true;
    }

    // Check linked products changes directly from PostAttributeClass
    if (!_compareLinkedProducts(
        original.linkedProducts, current.linkedProducts)) {
      debugPrint('Changes detected in linked products from PostAttributeClass');
      return true;
    }

    // Check local linked products changes
    if (!_compareLinkedProducts(
        _originalPostAttributeClass?.linkedProducts, _linkedProducts)) {
      debugPrint('Changes detected in local linked products');
      return true;
    }

    // Check linked products changes by comparing with bloc's state (fallback)
    try {
      final createPostBloc = BlocProvider.of<CreatePostBloc>(context);
      final currentLinkedProducts = createPostBloc.linkedProducts;

      debugPrint('=== LINKED PRODUCTS CHECK ===');
      debugPrint(
          'Current linked products count: ${currentLinkedProducts.length}');
      debugPrint(
          'Current linked products: ${currentLinkedProducts.map((p) => p.productName).toList()}');

      // Check what's in the bloc's original products list
      final originalLinkedProducts = createPostBloc.originalLinkedProducts;
      debugPrint(
          'Original linked products count: ${originalLinkedProducts.length}');
      debugPrint(
          'Original linked products: ${originalLinkedProducts.map((p) => p.productName).toList()}');

      debugPrint('Calling checkForChangesInLinkedProducts...');

      final hasLinkedProductChanges =
          createPostBloc.checkForChangesInLinkedProducts(currentLinkedProducts);

      debugPrint('Has linked product changes: $hasLinkedProductChanges');
      debugPrint('=== END LINKED PRODUCTS CHECK ===');

      if (hasLinkedProductChanges) {
        debugPrint('Changes detected in linked products from bloc');
        return true;
      }
    } catch (e) {
      debugPrint('Error checking linked products changes: $e');
    }

    return false;
  }

  /// Compare two mention lists
  bool _compareMentionLists(
      List<MentionData>? list1, List<MentionData>? list2) {
    if (list1?.length != list2?.length) return false;
    if (list1 == null || list2 == null) return list1 == list2;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].userId != list2[i].userId ||
          list1[i].mediaPosition != list2[i].mediaPosition) {
        return false;
      }
    }
    return true;
  }

  /// Compare two location tag lists
  bool _compareLocationTags(
      List<TaggedPlace>? list1, List<TaggedPlace>? list2) {
    if (list1?.length != list2?.length) return false;
    if (list1 == null || list2 == null) return list1 == list2;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].placeId != list2[i].placeId) {
        return false;
      }
    }
    return true;
  }

  /// Compare two media data lists
  bool _compareMediaData(List<MediaData>? list1, List<MediaData>? list2) {
    if (list1?.length != list2?.length) return false;
    if (list1 == null || list2 == null) return list1 == list2;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].url != list2[i].url ||
          list1[i].localPath != list2[i].localPath) {
        return false;
      }
    }
    return true;
  }

  /// Compare two linked product lists
  bool _compareLinkedProducts(
      List<ProductDataModel>? list1, List<ProductDataModel>? list2) {
    if (list1?.length != list2?.length) return false;
    if (list1 == null || list2 == null) return list1 == list2;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].childProductId != list2[i].childProductId) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Check for changes on every build (when user returns from other screens)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePostButtonState();
    });

    return BlocListener<CreatePostBloc, CreatePostState>(
      listenWhen: (previousState, currentState) =>
          currentState is PostCreatedState ||
          currentState is ShowProgressDialogState ||
          currentState is PostAttributionUpdatedState,
      listener: (context, state) {
        if (state is PostAttributionUpdatedState &&
            state.postAttributeClass != _postAttributeClass) {
          setState(() {
            _prepareData(postAttributeClass: state.postAttributeClass);
          });
        }
        if (state is PostCreatedState) {
          if (widget.isEditMode == true) {
            _socialActionCubit.onPostEdited(postId: state.postDataModel?.id, postData: state.postDataModel);
          } else {
            _socialActionCubit.onPostCreated(postId: state.postDataModel?.id);
          }
          final postData = state.postDataModel != null ? jsonEncode(state.postDataModel!.toMap()) : null;
          Utility.showBottomSheet(
            child: _buildSuccessBottomSheet(
              onTapBack: () {
                if (widget.isEditMode != true) {
                  Navigator.pop(context, null);
                  Navigator.pop(context, null);
                }
                Navigator.pop(context, postData);
              },
              title: state.postSuccessTitle ?? '',
              message: state.postSuccessMessage ?? '',
            ),
            isDismissible: false,
          );
          _doMediaCaching(state.mediaDataList);
          Future.delayed(const Duration(seconds: 2), () async {
            Navigator.pop(context);
            if (widget.isEditMode != true) {
              Navigator.pop(context);
              Navigator.pop(context);
            }
            Navigator.pop(context, postData);
          });
        }
        if (state is ShowProgressDialogState) {
          if (!_isDialogOpen) {
            _isDialogOpen = true;
            _showProgressDialog(state.title ?? '', state.subTitle ?? '');
          } else {
            if (state.isAllFilesUploaded) {
              // Show success animation
              // _progressCubit.showSuccess();
              // Dismiss after 3 seconds
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_isDialogOpen) {
                  _isDialogOpen = false;
                  Navigator.pop(context);
                }
              });
            }
          }
          // Update all cubit state values
          _progressCubit.updateProgress(state.progress ?? 0);
          _progressCubit.updateTitle(
              state.title ?? IsrTranslationFile.uploadingMediaFiles);
          _progressCubit.updateSubtitle(state.subTitle ?? '');
        }
      },
      child: _buildPage(),
    );
  }

  Widget _buildPage() => Scaffold(
        backgroundColor: Colors.white,
        appBar: IsmCustomAppBarWidget(
          backgroundColor: Colors.white,
          titleText: widget.isEditMode == true? IsrTranslationFile.editPost : IsrTranslationFile.newPost,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // // Media Preview Section
                    // if (_mediaDataList.isNotEmpty)
                    //   Container(
                    //     height: 280
                    //         .responsiveDimension, // Increased height for reels-like aspect ratio
                    //     width: double.infinity,
                    //     padding: EdgeInsetsGeometry.symmetric(
                    //         horizontal: 5.responsiveDimension),
                    //     child: Center(
                    //       child: ListView.builder(
                    //         scrollDirection: Axis.horizontal,
                    //         itemCount: _mediaDataList.length,
                    //         physics: const BouncingScrollPhysics(),
                    //         shrinkWrap: true,
                    //         itemBuilder: (context, index) {
                    //           final media = _mediaDataList[index];
                    //           return Container(
                    //             margin: IsrDimens.edgeInsetsAll(
                    //                 7.responsiveDimension),
                    //             child: AspectRatio(
                    //               aspectRatio: 9 / 16,
                    //               child: Container(
                    //                 decoration: BoxDecoration(
                    //                     borderRadius: BorderRadius.circular(8),
                    //                     color: IsrColors.blackColor),
                    //                 child: ClipRRect(
                    //                   borderRadius: BorderRadius.circular(8),
                    //                   child: media.mediaType?.mediaType ==
                    //                       MediaType.video
                    //                       ? _buildVideoPlayer(media)
                    //                       : _buildImage(media.localPath?.takeIf((_) => _.isNotEmpty) ?? media.url ?? ''),
                    //                 ),
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //   ),

                    // Media Preview Section
                    if (_mediaDataList.isNotEmpty)
                      Container(
                        height: 220
                            .responsiveDimension, // Increased height for reels-like aspect ratio
                        width: double.infinity,
                        padding: EdgeInsetsGeometry.symmetric(
                            horizontal: 5.responsiveDimension),
                        child: Center(
                          child: GestureDetector(
                            onTap: _changeCover,
                            child: Container(
                              margin: IsrDimens.edgeInsetsAll(
                                  7.responsiveDimension),
                              child: AspectRatio(
                                aspectRatio: 9 / 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: IsrColors.blackColor),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        _buildImage(_postAttributeClass
                                                ?.createPostRequest
                                                ?.previews
                                                ?.firstOrNull
                                                ?.localFilePath ??
                                            _postAttributeClass
                                                ?.createPostRequest
                                                ?.previews
                                                ?.firstOrNull
                                                ?.url ??
                                            ''),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: double.infinity,
                                            height: 28.responsiveDimension,
                                            color: IsrColors.black
                                                .withValues(alpha: 0.3),
                                            child: Center(
                                              child: Text(
                                                IsrTranslationFile.changeCover,
                                                style: IsrStyles.primaryText12
                                                    .copyWith(
                                                  color: IsrColors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Caption input
                    _buildCaptionInput(),
                    10.verticalSpace,

                    // Options List
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Link Products
                        if (widget.onTagProduct != null)
                          _buildOptionTile(
                            icon: AssetConstants.icCartIcon,
                            title: IsrTranslationFile.linkProducts,
                            onTap: _getLinkedProducts,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_linkedProducts.isNotEmpty) ...[
                                  Text(
                                    '${_linkedProducts.length} ${IsrTranslationFile.product}${_linkedProducts.length > 1 ? 's' : ''}',
                                    style: IsrStyles.primaryText14,
                                  ),
                                  8.horizontalSpace,
                                ],
                                Icon(
                                  Icons.chevron_right,
                                  color: '333333'.toColor(),
                                  size: 20.responsiveDimension,
                                ),
                              ],
                            ),
                          ),

                        // Tag People
                        _buildOptionTile(
                          icon: AssetConstants.icTagUser,
                          title: IsrTranslationFile.tagPeople,
                          onTap: () async {
                            final mediaDataList =
                                _postAttributeClass?.mediaDataList ?? [];
                            final result =
                                await IsrAppNavigator.goToTagPeopleScreen(
                              context,
                              mentionDataList: _mentionedUsers,
                              mediaDataList: mediaDataList,
                            );
                            if (result.isEmptyOrNull == false) {
                              for (var mentionData
                                  in result as Iterable<MentionData>) {
                                if (!_mentionedUsers.any((element) =>
                                    element.userId == mentionData.userId)) {
                                  _mentionedUsers.add(mentionData);
                                }
                              }
                              setState(() {});
                              _updatePostButtonState();
                            }
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_getTaggedUsersCount() > 0) ...[
                                Text(
                                  '${_getTaggedUsersCount()} ${IsrTranslationFile.people}',
                                  style: IsrStyles.primaryText14,
                                ),
                                8.horizontalSpace,
                              ],
                              Icon(
                                Icons.chevron_right,
                                color: '333333'.toColor(),
                                size: 20.responsiveDimension,
                              ),
                            ],
                          ),
                        ),

                        // Add Location
                        _buildLocationTile(),

                        // Allow Comments
                        _buildSwitchTile(
                          icon: AssetConstants.icAllowComment,
                          title: IsrTranslationFile.allowComments,
                          value: _postAttributeClass?.allowComment == true,
                          onChanged: (value) {
                            setState(() {
                              _postAttributeClass?.allowComment = value;
                            });
                            _updatePostButtonState();
                          },
                        ),

                        // Allow Save
                        _buildSwitchTile(
                          icon: AssetConstants.icAllowSave,
                          title: IsrTranslationFile.allowSave,
                          value: _postAttributeClass?.allowSave == true,
                          onChanged: (value) {
                            setState(() {
                              _postAttributeClass?.allowSave = value;
                            });
                            _updatePostButtonState();
                          },
                        ),

                        // Schedule Post (only if not in edit mode)
                        if (!_isEditMode) _buildSchedulePostTile(),
                      ],
                    ),

                    // Bottom padding for scroll
                    30.verticalSpace,
                  ],
                ),
              ),
            ),

            // Fixed Post Button at bottom
            Container(
              padding: IsrDimens.edgeInsetsAll(20.responsiveDimension),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                child: AppButton(
                  title: IsrTranslationFile.post,
                  isDisable: !_isPostButtonEnabled,
                  onPress: _isPostButtonEnabled ? _createPost : null,
                  borderRadius: 25.responsiveDimension,
                  height: 44.responsiveDimension,
                ),
              ),
            ),
          ],
        ),
      );

  void _showProgressDialog(String title, String message) async {
    await Utility.showBottomSheet(
        child: BlocProvider(
          create: (context) => _progressCubit,
          child: UploadProgressBottomSheet(message: message),
        ),
        isDismissible: false);
    _isDialogOpen = false;
  }

  void _doMediaCaching(List<MediaData>? mediaDataList) async {
    if (mediaDataList.isEmptyOrNull) return;
    final urls = <String>[];
    for (var media in mediaDataList!) {
      if (media.url.isEmptyOrNull == false) {
        urls.add(media.url!);
      }
      if (media.previewUrl.isEmptyOrNull == false) {
        urls.add(media.previewUrl!);
      }
    }
    if (!mounted) return;

    // Use compute for background processing if needed
    await compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      Utility.preCacheImages(urls, context);
    });
  }

  Widget _buildSuccessBottomSheet({
    required Function() onTapBack,
    required String title,
    required String message,
  }) =>
      Container(
        width: IsrDimens.getScreenWidth(context),
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: TapHandler(
                onTap: () {
                  Navigator.pop(context);
                  onTapBack();
                },
                child: const AppImage.svg(
                  AssetConstants.icCrossIcon,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  AssetConstants.postUploadedAnimation,
                  animate: true,
                  height: IsrDimens.seventy,
                  width: IsrDimens.seventy,
                  repeat: false,
                ),
                24.verticalSpace,
                Text(
                  message,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: IsrDimens.eighteen,
                  ),
                  textAlign: TextAlign.center,
                ),
                8.verticalSpace,
                Text(
                  IsrTranslationFile.yourPostHasBeenSuccessfullyPosted,
                  style: IsrStyles.primaryText14.copyWith(
                    color: Colors.grey,
                    fontSize: IsrDimens.fifteen,
                  ),
                  textAlign: TextAlign.center,
                ),
                16.verticalSpace,
              ],
            ),
          ],
        ),
      );

  /// Build caption input field
  Widget _buildCaptionInput() => Container(
        key: _captionInputKey,
        child: UserMentionTextField(
          controller: _descriptionController,
          hintText: '${IsrTranslationFile.addCaption}...',
          maxLength: _maxLength,
          style: IsrStyles.primaryText14,
          hintStyle:
              IsrStyles.secondaryText14.copyWith(color: IsrColors.colorBBBBBB),
          onTap: _scrollToCaptionInput,
          onChanged: (value) {
            final createPostBloc = BlocProvider.of<CreatePostBloc>(context);
            createPostBloc.descriptionText = _descriptionController.text;

            // Update PostAttributeClass
            if (_postAttributeClass?.createPostRequest != null) {
              _postAttributeClass!.createPostRequest!.caption =
                  _descriptionController.text;
            }

            setState(() {});
            _updatePostButtonState();
          },
          onAddMentionData: (mentionData) {
            if (!_mentionedUsers.any((u) => u.userId == mentionData.userId)) {
              _mentionedUsers.add(mentionData);
              // Immediately sync to bloc for real-time updates
              _syncMentionDataToBloc();
            }
            debugPrint('_mentionedUsers: ${jsonEncode(_mentionedUsers)}');
          },
          onRemoveMentionData: (mentionData) {
            _mentionedUsers.removeWhere((u) => u.userId == mentionData.userId);
            // Immediately sync to bloc for real-time updates
            _syncMentionDataToBloc();
            debugPrint('_mentionedUsers: ${jsonEncode(_mentionedUsers)}');
          },
          onAddHashTagData: (hashTagData) {
            if (!_hashTags.any((u) => u.tag == hashTagData.tag)) {
              _hashTags.add(hashTagData);
              // Immediately sync to bloc for real-time updates
              _syncMentionDataToBloc();
            }
            debugPrint('hashTagData: ${jsonEncode(_hashTags)}');
          },
          onRemoveHashTagData: (hashTagData) {
            _hashTags.removeWhere((u) => u.tag == hashTagData.tag);
            // Immediately sync to bloc for real-time updates
            _syncMentionDataToBloc();
            debugPrint('hashTagData: ${jsonEncode(_hashTags)}');
          },
        ),
      );

  /// Get count of tagged users
  int _getTaggedUsersCount() => _mentionedUsers.length;

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != isKeyboardVisible) {
      debugPrint('Keyboard visibility changed: $newValue');
      isKeyboardVisible = newValue;
      if (isKeyboardVisible && _isCaptionFocused) {
        debugPrint('Keyboard visibility changed a: $newValue');
        Future.delayed(
            const Duration(milliseconds: 700), _performScrollToCaptionInput);
      }
    }
  }

  /// Scroll to the UserMentionTextField position after keyboard appears
  void _scrollToCaptionInput() {
    _isCaptionFocused = true;
    if (isKeyboardVisible && _isCaptionFocused) {
      _performScrollToCaptionInput();
    }
  }

  /// Perform the actual scroll to caption input
  void _performScrollToCaptionInput() {
    if (_scrollController.hasClients &&
        _captionInputKey.currentContext != null) {
      // Get the render box of the caption input
      final renderBox =
          _captionInputKey.currentContext!.findRenderObject() as RenderBox;

      // Get the position of the widget relative to the scrollable area
      final position = renderBox.localToGlobal(Offset.zero);

      // Calculate the offset to scroll to (position of the widget minus some padding)
      final scrollOffset =
          _scrollController.offset + position.dy - 80; // 20px padding from top

      // Ensure we don't scroll beyond the bounds
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final targetOffset = scrollOffset.clamp(0.0, maxScrollExtent);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build location tile with proper alignment and text handling
  Widget _buildLocationTile() {
    final hasLocation = _postAttributeClass?.taggedPlaces?.isNotEmpty == true;
    final taggedPlaces = _postAttributeClass?.taggedPlaces ?? [];
    final taggedPlace = _postAttributeClass?.taggedPlaces?.firstOrNull;
    return _buildOptionTile(
      icon: AssetConstants.icPostLocation,
      title: hasLocation
          ? '${taggedPlace?.placeName}${taggedPlace?.placeName == taggedPlace?.city ? '' : ', ${taggedPlace?.city}'}'
          : IsrTranslationFile.addLocation,
      subtitle:
          hasLocation ? '${taggedPlace?.state}, ${taggedPlace?.country}' : null,
      trailing: Icon(
        hasLocation ? Icons.close : Icons.chevron_right,
        color: IsrColors.primaryTextColor,
        size: 20.responsiveDimension,
      ),
      color: hasLocation ? IsrColors.appColor : IsrColors.primaryTextColor,
      onTap: () async {
        final result = await IsrAppNavigator.goToSearchLocation(context,
            taggedPlaceList: taggedPlaces);

        if (result != null) {
          _postAttributeClass?.taggedPlaces = result;
          setState(() {});
          _updatePostButtonState();
        }
      },
      onTrailingTap: !hasLocation
          ? null
          : () async {
              taggedPlace?.let((place) {
                setState(() {
                  _postAttributeClass?.taggedPlaces?.remove(place);
                });
              });
            },
    );
  }

  /// Build schedule post tile
  Widget _buildSchedulePostTile() => _buildOptionTile(
        icon: AssetConstants.icTimerIcon,
        title: IsrTranslationFile.schedulePost,
        subtitle: _getFormattedScheduleTime(),
        onTap: _showScheduleBottomSheet,
        trailing: _selectedDate != null
            ? GestureDetector(
                onTap: _clearSchedule,
                child: Container(
                  padding: IsrDimens.edgeInsetsAll(4.responsiveDimension),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20.responsiveDimension,
                  ),
                ),
              )
            : Icon(
                Icons.chevron_right,
                color: '333333'.toColor(),
                size: 20.responsiveDimension,
              ),
      );

  /// Get formatted schedule time for display
  String? _getFormattedScheduleTime() {
    if (_selectedDate == null) return null;

    final schedule = _selectedDate!;

    // Format date
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dateStr =
        '${schedule.day} ${months[schedule.month - 1]} ${schedule.year}';

    // Format time
    final hour = schedule.hour == 0
        ? 12
        : (schedule.hour > 12 ? schedule.hour - 12 : schedule.hour);
    final minute = schedule.minute.toString().padLeft(2, '0');
    final period = schedule.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';
    return '$dateStr, $timeStr';
  }

  /// Show schedule bottom sheet
  void _showScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScheduleBottomSheet(),
    );
  }

  /// Clear schedule
  void _clearSchedule() {
    setState(() {
      _selectedDate = null;
    });
    _updatePostButtonState();
  }

  /// Build schedule bottom sheet
  Widget _buildScheduleBottomSheet() {
    var selectedDate =
        _selectedDate?.toLocal() ?? _createPostBloc.getBufferedDate();
    var selectedTime = TimeOfDay.fromDateTime(selectedDate);

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: IsrDimens.edgeInsets(
                  top: 12.responsiveDimension, bottom: 16.responsiveDimension),
              width: 40.responsiveDimension,
              height: 4.responsiveDimension,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      IsrTranslationFile.schedulePost,
                      style: IsrStyles.primaryText20
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Date field
            Container(
              margin: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${IsrTranslationFile.date}*',
                    style: IsrStyles.primaryText12,
                  ),
                  8.verticalSpace,
                  GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: _createPostBloc.getBufferedDate(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.black,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                              secondary: Colors.black,
                              onSecondary: Colors.white,
                              surfaceContainerHighest: Color(0xFFF5F5F5),
                              onSurfaceVariant: Colors.black54,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              elevation: 8,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                            datePickerTheme: const DatePickerThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              headerBackgroundColor: Colors.white,
                              headerForegroundColor: Colors.black,
                              weekdayStyle: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              dayStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              yearStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              todayBackgroundColor:
                                  WidgetStatePropertyAll(Color(0xFFF0F0F0)),
                              todayForegroundColor:
                                  WidgetStatePropertyAll(Colors.black),
                              dayBackgroundColor:
                                  WidgetStatePropertyAll(Colors.transparent),
                              dayForegroundColor:
                                  WidgetStatePropertyAll(Colors.black),
                              rangeSelectionBackgroundColor: Color(0xFFF0F0F0),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedDate != null) {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        setModalState(() {});
                      }
                    },
                    child: Container(
                      padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: 16.responsiveDimension,
                          vertical: 16.responsiveDimension),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(selectedDate),
                              style: IsrStyles.primaryText14,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time field
            Container(
              margin: IsrDimens.edgeInsetsSymmetric(
                  horizontal: 20.responsiveDimension,
                  vertical: 8.responsiveDimension),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${IsrTranslationFile.time}*',
                    style: IsrStyles.primaryText12,
                  ),
                  8.verticalSpace,
                  GestureDetector(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.black,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                              outline: Color(0xFFE0E0E0),
                              secondary: Colors.black,
                              onSecondary: Colors.white,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            ),
                            timePickerTheme: const TimePickerThemeData(
                              backgroundColor: Colors.white,
                              dialBackgroundColor: Color(0xFFF5F5F5),
                              dialHandColor: Colors.black,
                              dialTextColor: Colors.black,
                              hourMinuteTextColor: Colors.black,
                              hourMinuteColor: Color(0xFFF5F5F5),
                              dayPeriodTextColor: Colors.black,
                              dayPeriodColor: Color(0xFFF5F5F5),
                              dayPeriodBorderSide: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                              entryModeIconColor: Colors.black,
                              helpTextStyle: TextStyle(color: Colors.black),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setModalState(() {});
                      }
                    },
                    child: Container(
                      padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: 16.responsiveDimension,
                          vertical: 16.responsiveDimension),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(selectedTime),
                              style: IsrStyles.primaryText14,
                            ),
                          ),
                          Icon(Icons.access_time, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Save button
            AppButton(
              height: 44.responsiveDimension,
              margin: IsrDimens.edgeInsetsAll(20.responsiveDimension),
              borderRadius: 22.responsiveDimension,
              textStyle:
                  IsrStyles.white14.copyWith(fontWeight: FontWeight.w600),
              onPress: () {
                debugPrint('Selected date: $selectedDate');
                debugPrint('Current time: ${DateTime.now()}');
                debugPrint(
                    'Is future: ${selectedDate.isAfter(DateTime.now())}');

                // Validate buffer time before saving
                if (_validateScheduleTime(selectedDate)) {
                  debugPrint('✅ Validation passed - saving schedule');
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                  _updatePostButtonState();
                  Navigator.pop(context);
                } else {
                  debugPrint('❌ Validation failed - showing error');
                  // Show error message for invalid time
                  Utility.showAppDialog(
                    message: IsrTranslationFile.pleaseSelectAFutureTime,
                  );
                }
              },
              title: IsrTranslationFile.save,
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format time for display
  String _formatTime(TimeOfDay time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Validate schedule time with buffer logic from bloc
  bool _validateScheduleTime(DateTime selectedDate) {
    final now = DateTime.now();

    // Basic check: must be at least 1 minute in the future
    final oneMinuteLater = now.add(const Duration(minutes: 1));
    if (selectedDate.isBefore(oneMinuteLater)) {
      return false;
    }

    return true;
  }

  /// Sync mention data to bloc
  void _syncMentionDataToBloc() {
    debugPrint('=== _syncMentionDataToBloc START ===');
    debugPrint('Current _mentionedUsers count: ${_mentionedUsers.length}');
    debugPrint('Current _hashTags count: ${_hashTags.length}');

    final createPostBloc = BlocProvider.of<CreatePostBloc>(context);

    debugPrint(
        'Current bloc mentionedUserData count: ${createPostBloc.mentionedUserData.length}');
    debugPrint(
        'Current bloc mediaMentionUserData count: ${createPostBloc.mediaMentionUserData.length}');

    // DON'T clear mediaMentionUserData as it may contain media-positioned mentions
    createPostBloc.hashTagDataList.clear();
    createPostBloc.mentionedUserData.clear();

    // Add current mentioned users and hashtags
    createPostBloc.mentionedUserData.addAll(_mentionedUsers);
    createPostBloc.hashTagDataList.addAll(_hashTags);

    // Update PostAttributeClass with combined mentioned users
    _postAttributeClass?.mentionedUserList = [
      ...createPostBloc.mentionedUserData,
      ...createPostBloc.mediaMentionUserData
    ];
    _postAttributeClass?.hashTagDataList = createPostBloc.hashTagDataList;

    setState(() {});
    debugPrint(
        'After sync - bloc mentionedUserData count: ${createPostBloc.mentionedUserData.length}');
    debugPrint(
        'After sync - bloc mediaMentionUserData count: ${createPostBloc.mediaMentionUserData.length}');
    debugPrint(
        'After sync - bloc hashTagDataList count: ${createPostBloc.hashTagDataList.length}');
    debugPrint('=== _syncMentionDataToBloc END ===');
  }

  /// Get linked products from product selection screen
  void _getLinkedProducts() async {
    final result = await widget.onTagProduct?.call(_linkedProducts.toList());
    setState(() {
      _linkedProducts.clear();
      _linkedProducts.addAll(result ?? []);
    });
    _updatePostButtonState();
  }

  void _playPause(VideoPlayerController controller) async {
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    setState(() {});
  }

  void _createPost() {
    _setPostRequest();
    BlocProvider.of<CreatePostBloc>(context).add(PostCreateEvent(
      createPostRequest:
          _postAttributeClass?.createPostRequest ?? CreatePostRequest(),
      isForEdit: _isEditMode,
    ));
  }

  void _setPostRequest() {
    final createPostRequest = _postAttributeClass?.createPostRequest;
    if (createPostRequest != null) {
      final settings = PostSettingModel(
        saveEnabled: _postAttributeClass?.allowSave,
        commentsEnabled: _postAttributeClass?.allowComment,
      );
      createPostRequest.settings = settings;

      // Set schedule time if post is scheduled
      if (_isEditMode == false && _selectedDate != null) {
        // Check if selected date is today
        if (DateTimeUtil.isTodayDate(_selectedDate!)) {
          // If it's today, ensure time is at least one hour later
          final oneHourLater = _createPostBloc.getBufferedDate();
          if (_selectedDate!.isBefore(oneHourLater)) {
            _selectedDate = oneHourLater;
          }
        }
        createPostRequest.scheduleTime =
            DateTimeUtil.getIsoDate(_selectedDate!.millisecondsSinceEpoch);
        createPostRequest.visibility = SocialPostVisibility.scheduled;
      } else {
        createPostRequest.scheduleTime = null;
        createPostRequest.visibility = SocialPostVisibility.public;
      }

      final tags = createPostRequest.tags ?? Tags();
      if (_mentionedUsers.isEmptyOrNull == false) {
        _postAttributeClass?.mentionedUserList = _mentionedUsers;
        tags.mentions = _mentionedUsers;
      }
      if (_hashTags.isNotEmpty) {
        tags.hashtags = _hashTags;
      } else if (_postAttributeClass?.hashTagDataList?.isEmptyOrNull == false) {
        tags.hashtags = _postAttributeClass?.hashTagDataList;
      }
      if (_postAttributeClass?.taggedPlaces.isEmptyOrNull == false) {
        tags.places = _postAttributeClass?.taggedPlaces;
      }
      if (_linkedProducts.isNotEmpty) {
        _postAttributeClass?.linkedProducts = _linkedProducts;
        tags.products = _createPostBloc.getSocialProductList(_linkedProducts);
      }

      createPostRequest.tags = tags;

      debugPrint(
          'createPostRequest.....${jsonEncode(createPostRequest.toJson())}');
      debugPrint(
          'createPostRequest.....${jsonEncode(createPostRequest.tags?.mentions)}');
      debugPrint(
          'createPostRequest.....${jsonEncode(createPostRequest.tags?.hashtags)}');
      debugPrint(
          'createPostRequest.....${jsonEncode(createPostRequest.tags?.places)}');
      debugPrint(
          'createPostRequest.....${jsonEncode(createPostRequest.tags?.products)}');
    }
    _postAttributeClass?.createPostRequest = createPostRequest;
  }

  // Helper method to build option tiles
  Widget _buildOptionTile({
    required String icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    VoidCallback? onTrailingTap,
    Widget? trailing,
    Color color = IsrColors.primaryTextColor,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin:
                IsrDimens.edgeInsetsSymmetric(vertical: 4.responsiveDimension),
            padding: IsrDimens.edgeInsetsSymmetric(
                horizontal: 20.responsiveDimension,
                vertical: 12.responsiveDimension),
            child: Row(
              children: [
                AppImage.svg(
                  icon,
                  height: 20.responsiveDimension,
                  width: 20.responsiveDimension,
                  color: color,
                ),
                8.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        4.horizontalSpace,
                        Text(
                          subtitle,
                          style: IsrStyles.primaryText12
                              .copyWith(color: IsrColors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                TapHandler(
                  onTap: onTrailingTap ?? onTap,
                  child: (trailing != null)
                      ? trailing
                      : (onTap != null)
                          ? const Icon(
                              Icons.chevron_right,
                              color: IsrColors.primaryTextColor,
                              size: 20,
                            )
                          : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );

  void _changeCover() async {
    final coverPic = await _pickCoverPic();
    if (coverPic != null && Utility.isLocalUrl(coverPic)) {
      _createPostBloc.add(ChangeCoverImageEvent(
          coverImage: File(coverPic),
          onComplete: () {
            setState(_updatePostButtonState);
          }));
    }
  }

  Future<String?> _pickCoverPic() async {
    final res = await Navigator.push<List<ms.MediaAssetData>>(
      context,
      MaterialPageRoute(
        builder: (context) => ms.MediaSelectionView(
          mediaSelectionConfig: mediaSelectionConfig.copyWith(
              mediaListType: ms.MediaListType.image,
              isMultiSelect: false,
              selectMediaTitle: IsrTranslationFile.addCover),
          onCaptureMedia: _captureMedia,
        ),
      ),
    );
    return res?.first.localPath;
  }

  final mediaSelectionConfig = ms.MediaSelectionConfig(
    isMultiSelect: true,
    imageMediaLimit: AppConstants.imageMediaLimit,
    videoMediaLimit: AppConstants.videoMediaLimit,
    mediaLimit: AppConstants.totalMediaLimit,
    singleSelectModeIcon:
        const AppImage.svg(AssetConstants.icMediaSelectSingle),
    multiSelectModeIcon:
        const AppImage.svg(AssetConstants.icMediaSelectMultiple),
    doneButtonText: IsrTranslationFile.next,
    selectMediaTitle: IsrTranslationFile.newReel,
    primaryColor: IsrColors.appColor,
    primaryTextColor: IsrColors.primaryTextColor,
    backgroundColor: Colors.white,
    appBarColor: Colors.white,
    primaryFontFamily: AppConstants.primaryFontFamily,
    mediaListType: ms.MediaListType.imageVideo,
  );

  Future<String?> _captureMedia(String? mediaType) async =>
      await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => mc.CameraCaptureView(
            mediaType: mediaType?.mediaType ?? MediaType.photo,
            onGalleryClick: () async {
              Navigator.pop(context);
              return null;
            },
          ),
        ),
      );

  // Helper method to build switch tiles
  Widget _buildSwitchTile({
    required String icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Container(
            margin:
                IsrDimens.edgeInsetsSymmetric(vertical: 4.responsiveDimension),
            padding: IsrDimens.edgeInsetsSymmetric(
                horizontal: 20.responsiveDimension),
            child: Row(
              children: [
                AppImage.svg(icon),
                8.horizontalSpace,
                Expanded(
                  child: Text(
                    title,
                    style: IsrStyles.primaryText14
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: IsrColors.white,
                  inactiveThumbColor: IsrColors.white,
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: 'C6C6CC'.toColor(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildImage(String url) => Utility.isLocalUrl(url)
      ? AppImage.file(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        )
      : AppImage.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
}
