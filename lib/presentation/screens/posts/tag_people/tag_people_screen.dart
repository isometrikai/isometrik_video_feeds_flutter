import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post/user_mention_text_field.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

class TagPeopleScreen extends StatefulWidget {
  const TagPeopleScreen({
    Key? key,
    required this.mentionDataList,
    required this.mediaDataList,
  }) : super(key: key);

  final List<MentionData> mentionDataList;
  final List<MediaData> mediaDataList;

  @override
  State<TagPeopleScreen> createState() => _TagPeopleScreenState();
}

class _TagPeopleScreenState extends State<TagPeopleScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, List<MentionData>> _mediaMentionedMap =
      {}; // Mentioned for each media item
  final Map<int, List<MentionData>> _mediaTaggedMap =
      {}; // Tagged for each media item
  final Map<int, GlobalKey> _mentionedImageKeys =
      {}; // Unique keys for each image
  final Map<int, GlobalKey> _mentionedVideoKeys =
      {}; // Unique keys for each video
  var _mediaDataList = <MediaData>[];
  var _mentionDataList = <MentionData>[];

  // Video player state
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _videoInitializingStates = {};

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _mentionDataList = widget.mentionDataList;
    _mediaDataList = widget.mediaDataList;

    _mediaMentionedMap.clear();
    for (final mention in _mentionDataList) {
      final pos = mention.mediaPosition?.position?.toInt() ?? 1;
      _mediaMentionedMap.putIfAbsent(pos, () => []).add(mention);
    }

    // Initialize video players for video media
    for (var mediaData in _mediaDataList) {
      if (mediaData.mediaType?.mediaType == MediaType.video) {
        initializeVideoPlayer(mediaData);
      }
    }
  }

  // List<MentionData> get currentMentions => _mediaMentionedMap[_currentIndex + 1] ?? [];

  List<MentionData> get currentMentions => _mediaMentionedMap[1] ?? [];

  List<MentionData> get currentTags => _mediaTaggedMap[_currentIndex] ?? [];

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitializingStates.clear();
    super.dispose();
  }

  /// Get media URL (local or remote) with proper priority
  String _getMediaUrl(MediaData mediaData) {
    // Check for local path first (for new uploads)
    if (mediaData.localPath?.isNotEmpty == true) {
      return mediaData.localPath!;
    }
    // Check for remote URL (for existing/edited posts)
    else if (mediaData.url?.isNotEmpty == true) {
      return mediaData.url!;
    }
    // Return empty string if no valid URL found
    return '';
  }

  /// Method For Initialize Video Player
  Future<void> initializeVideoPlayer(MediaData mediaData) async {
    if (mediaData.mediaType == 'video') {
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

  /// Play/pause video
  void _playPause(VideoPlayerController controller) {
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: IsmCustomAppBarWidget(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black, size: 24.responsiveDimension),
            onPressed: () => Navigator.pop(context),
          ),
          titleText: 'Tag people',
          isCrossIcon: true,
          centerTitle: true,
          showActions: true,
          actions: [
            TapHandler(
              onTap: _setData,
              child: const Icon(Icons.check, color: Colors.black, size: 24),
            ),
            16.horizontalSpace,
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Media Carousel Section with Tagging
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Media PageView
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: _mediaDataList.length,
                          itemBuilder: (context, index) {
                            final mediaData = _mediaDataList[index];
                            if (mediaData.mediaType == 'video') {
                              // Get video URL (local or remote)
                              final videoUrl = _getMediaUrl(mediaData);
                              return _buildTaggableVideoView(videoUrl, index);
                            } else {
                              // Get image URL (local or remote)
                              final imageUrl = _getMediaUrl(mediaData);
                              return _buildTaggableImageView(imageUrl, index);
                            }
                          },
                        ),

                        // Page Indicators (only show if multiple items)
                        if (_mediaDataList.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _mediaDataList.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? Colors.white
                                        : Colors.white.changeOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Media counter (top right)
                        if (_mediaDataList.length > 1)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.applyOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_currentIndex + 1}/${_mediaDataList.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                        // Tag count indicator (top left)
                        if (currentMentions.isNotEmpty)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.applyOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${currentMentions.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Invite Collaborators Section
              // _buildInviteCollaboratorsSection(),

              // Instructions and Tagged People
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      AppButton(
                        title: IsrTranslationFile.tagPeople,
                        type: ButtonType.secondary,
                        borderWidth: 1.responsiveDimension,
                        textColor: IsrColors.appColor,
                        onPress: () {
                          _handleImageTap(null, null, 0);
                        },
                      ),
                      if (currentMentions.isEmpty) ...[
                        // // Instructions
                        // const SizedBox(height: 20),
                        // Icon(
                        //   Icons.touch_app_outlined,
                        //   size: 48,
                        //   color: Colors.grey[400],
                        // ),
                        // const SizedBox(height: 16),
                        // Text(
                        //   'Tap photo to tag people',
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     color: Colors.grey[600],
                        //     fontWeight: FontWeight.w400,
                        //   ),
                        //   textAlign: TextAlign.center,
                        // ),
                      ] else ...[
                        // Tagged People List
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              24.verticalSpace,

                              // Header
                              Text(
                                IsrTranslationFile.taggedPeople,
                                style: IsrStyles.primaryText14
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              4.verticalSpace,
                              Text(
                                IsrTranslationFile.listOfPeopleLinkedToThePost,
                                style: IsrStyles.primaryText12
                                    .copyWith(color: '909090'.toColor()),
                              ),
                              16.verticalSpace,

                              // Tagged people list
                              Expanded(
                                child: ListView.separated(
                                  itemCount: currentMentions.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    indent: 16.responsiveDimension,
                                    endIndent: 16.responsiveDimension,
                                    color: '#DBDBDB'.toColor(),
                                  ),
                                  itemBuilder: (context, index) {
                                    final person = currentMentions[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: !person.avatarUrl.isEmptyOrNull
                                          ? AppImage.network(
                                              person.avatarUrl ?? '',
                                              height: 48.responsiveDimension,
                                              width: 48.responsiveDimension,
                                              border: Border.all(
                                                  color: '#DBDBDB'.toColor()),
                                              name: person.name ??
                                                  person.username ??
                                                  'User',
                                              isProfileImage: true,
                                            )
                                          : CircleAvatar(
                                              radius: IsrDimens.twentyFour,
                                              backgroundColor:
                                                  '#E5F0FB'.color,
                                              child: Text(
                                                Utility.getInitials(
                                                  firstName: person.name
                                                          ?.split(' ')
                                                          .firstOrNull ??
                                                      '',
                                                  lastName: person.name
                                                          ?.split(' ')
                                                          .lastOrNull ??
                                                      '',
                                                ),
                                                style: IsrStyles.primaryText14
                                                    .copyWith(
                                                  color: IsrColors.appColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                      title: Text(
                                        person.name ??
                                            person.username ??
                                            'Unknown User',
                                        style: IsrStyles.primaryText14.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: person.username != null
                                          ? Text(
                                              person.username!,
                                              style: IsrStyles.primaryText12
                                                  .copyWith(
                                                      color:
                                                          '#767676'.toColor()),
                                            )
                                          : null,
                                      trailing: TapHandler(
                                        onTap: () {
                                          setState(() {
                                            _mediaMentionedMap[
                                                    _currentIndex + 1]
                                                ?.remove(person);
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.grey.shade700,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (currentTags.isNotEmpty) ...[
                        24.verticalSpace,
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tagged in this photo:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        12.verticalSpace,
                        ...currentTags
                            .map((tag) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    tileColor: Colors.blue[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: AppImage.network(
                                      tag.avatarUrl ?? '',
                                      height: 30.responsiveDimension,
                                      width: 30.responsiveDimension,
                                      name: tag.name ?? '',
                                      isProfileImage: true,
                                    ),
                                    title: Text(
                                      tag.tag!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _mediaTaggedMap[_currentIndex]
                                              ?.remove(tag);
                                        });
                                      },
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTaggableImageView(String imageUrl, int mediaIndex) {
    // Ensure we have a unique key for this media index
    _mentionedImageKeys.putIfAbsent(mediaIndex, GlobalKey.new);

    // Return empty container if no valid image URL
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTapUp: (TapUpDetails details) {
          // _handleImageTap(details, constraints, mediaIndex);
        },
        child: Utility.isLocalUrl(imageUrl)
            ? AppImage.file(
                imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
                key: _mentionedImageKeys[
                    mediaIndex], // Use unique key for each image
              )
            : AppImage.network(
                imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
                key: _mentionedImageKeys[
                    mediaIndex], // Use unique key for each image
              ),
      ),
    );
  }

  Widget _buildTaggableVideoView(String videoUrl, int mediaIndex) {
    // Ensure we have a unique key for this media index
    _mentionedVideoKeys.putIfAbsent(mediaIndex, GlobalKey.new);

    // Return error container if no valid video URL
    if (videoUrl.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.white),
              16.verticalSpace,
              const Text(
                'No video available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Use the same key logic as in initializeVideoPlayer
    final videoKey = videoUrl;
    final isInitializing = _videoInitializingStates[videoKey] ?? false;
    final controller = _videoControllers[videoKey];

    if (isInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      key: _mentionedVideoKeys[mediaIndex],
      builder: (context, constraints) => Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),

            // Invisible overlay for tap detection
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {
                  // _handleVideoTap(details, constraints, mediaIndex);
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Play/pause button overlay
            if (!controller.value.isPlaying)
              GestureDetector(
                onTap: () => _playPause(controller),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleImageTap(TapUpDetails? details, BoxConstraints? constraints,
      int mediaIndex) async {
    // Calculate relative position (0.0 to 1.0)
    final relativePosition = constraints == null || details == null
        ? null
        : Offset(
            (details.localPosition.dx / constraints.maxWidth) * 100,
            (details.localPosition.dy / constraints.maxHeight) * 100,
          );

    // Convert MentionData to SocialUserData (only for current media position)
    final currentMediaPosition = mediaIndex + 1;
    final currentMentions = _mediaMentionedMap[currentMediaPosition] ?? [];
    final selectedUsers = currentMentions
        .map((mentionData) => SocialUserData(
              id: mentionData.userId,
              username: mentionData.username,
              fullName: mentionData.name,
              avatarUrl: mentionData.avatarUrl,
              displayName: mentionData.name,
            ))
        .toList();

    final taggedUserList = await IsrAppNavigator.goToSearchUserScreen(context, socialUserList: selectedUsers);

    if (taggedUserList.isEmptyOrNull) return;
    _setMentionedUserPosition(taggedUserList, mediaIndex, relativePosition);
    }

  void _handleVideoTap(TapUpDetails? details, BoxConstraints? constraints,
      int mediaIndex) async {
    // Calculate relative position (0.0 to 1.0)
    final relativePosition = constraints == null || details == null
        ? null
        : Offset(
            (details.localPosition.dx / constraints.maxWidth) * 100,
            (details.localPosition.dy / constraints.maxHeight) * 100,
          );

    // Convert MentionData to SocialUserData (only for current media position)
    final currentMediaPosition = mediaIndex + 1;
    final currentMentions = _mediaMentionedMap[currentMediaPosition] ?? [];
    final selectedUsers = currentMentions
        .map((mentionData) => SocialUserData(
              id: mentionData.userId,
              username: mentionData.username,
              fullName: mentionData.name,
              avatarUrl: mentionData.avatarUrl,
              displayName: mentionData.name,
            ))
        .toList();

    final taggedUserList = await IsrAppNavigator.goToSearchUserScreen(context, socialUserList: selectedUsers);

    if (taggedUserList.isEmptyOrNull) return;
    _setMentionedUserPosition(taggedUserList, mediaIndex, relativePosition);
    }

  void _setMentionedUserPosition(
      List<SocialUserData> taggedUserList, int mediaIndex, Offset? position) {
    final pos = mediaIndex + 1;

    // Remove existing mentions for this media position completely
    _mediaMentionedMap.remove(pos);

    // Add new mentions from the updated user list
    if (taggedUserList.isNotEmpty) {
      final mentionList = <MentionData>[];
      for (var element in taggedUserList) {
        final mentionData = MentionData(
          mediaPosition: position == null
              ? null
              : MediaPosition(
                  position: pos,
                  x: position.dx.toInt(),
                  y: position.dy.toInt(),
                ),
          userId: element.id,
          username: element.username,
          name: element.fullName,
          avatarUrl: element.avatarUrl,
        );
        mentionList.add(mentionData);
      }
      _mediaMentionedMap[pos] = mentionList;
    }

    debugPrint(
        'Updated media mentions for position $pos: ${taggedUserList.length} users');
    debugPrint(
        'media mentions....${jsonEncode(_mediaMentionedMap.values.map((list) => list.map((mention) => mention.toJson()).toList()).toList())}');
    setState(() {});
  }

  void _setTagPosition(
      List<HashTagData> taggedList, int mediaIndex, Offset? position) {
    for (var element in taggedList) {
      final mentionData = MentionData(
        mediaPosition: position == null
            ? null
            : MediaPosition(
                position: mediaIndex + 1,
                x: position.dx.toInt(),
                y: position.dy.toInt(),
              ),
        userId: element.id,
        tag: element.hashtag,
      );
      _mediaTaggedMap[mediaIndex] = [mentionData];
    }
    debugPrint(
        'media tags....${jsonEncode(_mediaTaggedMap.values.map((list) => list.map((mention) => mention.toJson()).toList()).toList())}');
    setState(() {});
  }

  void _showInviteCollaboratorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Collaborators'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Feature coming soon!'),
            const SizedBox(height: 16),
            Text(
              'You\'ll be able to invite others to collaborate on tagging people in your photos and videos.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setData() {
    // Debug: Print the current state of _mediaMentionedMap
    debugPrint('=== _setData called ===');
    debugPrint('_mediaMentionedMap keys: ${_mediaMentionedMap.keys.toList()}');
    for (var entry in _mediaMentionedMap.entries) {
      debugPrint('Position ${entry.key}: ${entry.value.length} mentions');
      for (var mention in entry.value) {
        debugPrint('  - ${mention.username} (${mention.userId})');
      }
    }

    final finalMentionDataList = <MentionData>[
      ..._mediaMentionedMap.values.expand((list) => list).toList(),
    ];

    debugPrint('Final mention list size: ${finalMentionDataList.length}');
    debugPrint('======================');

    Navigator.pop(context, finalMentionDataList);
  }

  Widget _buildInviteCollaboratorsSection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ElevatedButton(
          onPressed: _showInviteCollaboratorsDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Invite Collaborators',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
