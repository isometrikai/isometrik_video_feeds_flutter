import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:video_player/video_player.dart';

class PostAttributeView extends StatefulWidget {
  const PostAttributeView({
    super.key,
    required this.postAttributeClass,
  });

  final PostAttributeClass? postAttributeClass;

  @override
  State<PostAttributeView> createState() => _PostAttributeViewState();
}

class _PostAttributeViewState extends State<PostAttributeView> {
  VideoPlayerController? _videoPlayerController;
  var _isVideoInitializing = false;
  var _mediaDataList = <MediaData>[];
  var _taggedPlaces = <TaggedPlace>[];
  PostAttributeClass? _postAttributeClass;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _postAttributeClass = widget.postAttributeClass;
    _mediaDataList = _postAttributeClass?.mediaDataList ?? [];
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
      _isVideoInitializing = true;
      setState(() {});
      _videoPlayerController = VideoPlayerController.file(File(mediaData.localPath ?? ''));
      await _videoPlayerController?.initialize();
      await _videoPlayerController?.setLooping(true);
      await _videoPlayerController?.setVolume(1.0);
      _isVideoInitializing = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CustomAppBar(
          titleText: 'New Post',
          centerTitle: true,
          onTap: () {
            _setPostRequest();
            Navigator.pop(context, _postAttributeClass);
          },
        ),
        bottomNavigationBar: SafeArea(
          child: AppButton(
            margin: Dimens.edgeInsetsSymmetric(horizontal: Dimens.fifteen, vertical: Dimens.ten),
            title: TranslationFile.post,
            onPress: _createPost,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.twenty),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_mediaDataList.isNotEmpty)
                        Container(
                          alignment: Alignment.center,
                          height: 140.scaledValue, // Adjust as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _mediaDataList.length,
                            itemBuilder: (context, index) {
                              final media = _mediaDataList[index];
                              return Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MediaPreviewWidget(
                                  mediaData: media,
                                  height: 140.scaledValue,
                                  width: 140.scaledValue,
                                ),
                              );
                            },
                          ),
                        ),
                      // Dimens.boxHeight(Dimens.ten),
                      // TextFormField(
                      //   maxLines: 5,
                      //   onChanged: (value) {
                      //     _postAttributeClass?.caption = value;
                      //   },
                      //   decoration: InputDecoration(
                      //     hintText: TranslationFile.writeCaption,
                      //     hintStyle: Styles.primaryText12,
                      //     border: InputBorder.none,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                CustomDivider(thickness: Dimens.five),
                // TapHandler(
                //   onTap: () {},
                //   child: Padding(
                //     padding:
                //         Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                //     child: Row(
                //       children: [
                //         Text(
                //           TranslationFile.category,
                //           style: Styles.primaryText14.copyWith(
                //             color: AppColors.color2783FB,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //         const Spacer(),
                //         Text(
                //           TranslationFile.selectCategory,
                //           style: Styles.primaryText14.copyWith(
                //             color: AppColors.color2783FB,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //         10.horizontalSpace,
                //         const AppImage.svg(
                //           AssetConstants.icChevronRight,
                //           height: 15,
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // const CustomDivider(),
                ListTile(
                  onTap: () {
                    setState(() {
                      _postAttributeClass?.allowComment =
                          _postAttributeClass?.allowComment == false;
                    });
                  },
                  title: Text(
                    TranslationFile.allowComments,
                    style: Styles.primaryText14.copyWith(
                      color: AppColors.color2783FB,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: _postAttributeClass?.allowComment == true,
                    onChanged: (value) {
                      setState(() {
                        _postAttributeClass?.allowComment = value;
                      });
                    },
                  ),
                ),
                const CustomDivider(),
                ListTile(
                  onTap: () {
                    setState(() {
                      _postAttributeClass?.allowSave = _postAttributeClass?.allowSave == false;
                    });
                  },
                  title: Text(
                    TranslationFile.allowSave,
                    style: Styles.primaryText14.copyWith(
                      color: AppColors.color2783FB,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: _postAttributeClass?.allowSave == true,
                    onChanged: (value) {
                      setState(() {
                        _postAttributeClass?.allowSave = value;
                      });
                    },
                  ),
                ),
                const CustomDivider(),
                ListTile(
                  onTap: () async {
                    // final result = await InjectionUtils.getRouteManagement()
                    //     .goToSearchUserScreen(socialUserList: _socialUserDataList);
                    // _socialUserDataList = result;

                    final result = await InjectionUtils.getRouteManagement()
                        .goToTagPeopleScreen(postAttributeClass: _postAttributeClass);
                    if (result != null) {
                      _postAttributeClass = result;
                    }
                  },
                  title: Text(
                    TranslationFile.tagPeople,
                    style: Styles.primaryText14.copyWith(
                      color: AppColors.color2783FB,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const AppImage.svg(
                    AssetConstants.icChevronRight,
                    height: 15,
                  ),
                ),
                _buildTaggedUsers(_postAttributeClass?.mentionedUserList ?? []),

                const CustomDivider(),
                ListTile(
                  onTap: _taggedPlaces.isEmptyOrNull == false
                      ? null
                      : () async {
                          final result =
                              await InjectionUtils.getRouteManagement().goToSearchLocationScreen();
                          if (result != null) {
                            _taggedPlaces = result;
                            setState(() {});
                          }
                        },
                  title: _taggedPlaces.isEmptyOrNull == true
                      ? Text(
                          TranslationFile.tagLocation,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : _buildTaggedPlaces(),
                  trailing: _taggedPlaces.isEmptyOrNull == true
                      ? const AppImage.svg(
                          AssetConstants.icChevronRight,
                          height: 15,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );

  void _playPause() async {
    if (_videoPlayerController?.value.isPlaying == true) {
      await _videoPlayerController?.pause();
    } else {
      await _videoPlayerController?.play();
    }
    setState(() {});
  }

  Widget _buildTaggedUsers(List<MentionData> taggedUsers) {
    if (taggedUsers.isEmpty) {
      return const SizedBox.shrink(); // nothing if no tagged users
    }

    return Container(
      height: 100.scaledValue,
      margin: const EdgeInsets.only(top: 8, left: 16),
      child: ListView.separated(
        padding: Dimens.edgeInsetsAll(10.scaledValue),
        scrollDirection: Axis.horizontal,
        itemCount: taggedUsers.length,
        separatorBuilder: (_, __) => 15.horizontalSpace,
        itemBuilder: (context, index) {
          final user = taggedUsers[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppImage.network(
                    user.avatarUrl ?? '',
                    height: 40.scaledValue,
                    width: 40.scaledValue,
                    isProfileImage: true,
                    name: user.name ?? '',
                    border: Border.all(color: Colors.black12),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          taggedUsers.removeAt(index);
                        });
                      },
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: Text(
                  user.username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createPost() {
    _setPostRequest();
    InjectionUtils.getBloc<CreatePostBloc>()
        .add(PostCreateEvent(createPostRequest: _postAttributeClass?.createPostRequest));
  }

  void _setPostRequest() {
    final createPostRequest = _postAttributeClass?.createPostRequest;
    if (createPostRequest != null) {
      final settings = PostSetting(
        saveEnabled: _postAttributeClass?.allowSave,
        commentsEnabled: _postAttributeClass?.allowComment,
      );
      createPostRequest.settings = settings;
      final tags = createPostRequest.tags ?? Tags();
      if (_postAttributeClass?.mentionedUserList?.isEmptyOrNull == false) {
        tags.mentions = _postAttributeClass?.mentionedUserList;
      }
      if (_postAttributeClass?.tagDataList?.isEmptyOrNull == false) {
        tags.hashtags = _postAttributeClass?.tagDataList;
      }
      if (_taggedPlaces.isEmptyOrNull == false) {
        tags.places = _taggedPlaces;
      }

      createPostRequest.tags = tags;

      debugPrint('createPostRequest.....${jsonEncode(createPostRequest.toJson())}');
      debugPrint('createPostRequest.....${jsonEncode(createPostRequest.tags?.mentions)}');
      debugPrint('createPostRequest.....${jsonEncode(createPostRequest.tags?.hashtags)}');
      debugPrint('createPostRequest.....${jsonEncode(createPostRequest.tags?.places)}');
    }
    _postAttributeClass?.createPostRequest = createPostRequest;
  }

  Widget _buildTaggedPlaces() =>
      Row(children: List.generate(_taggedPlaces.length, _buildSelectedPlaceWidget));

  Widget _buildSelectedPlaceWidget(int index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _taggedPlaces[index].placeName ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _taggedPlaces.removeAt(index);
                setState(() {});
              },
              child: const Icon(Icons.close, color: Colors.black54, size: 20),
            ),
          ],
        ),
      );
}
