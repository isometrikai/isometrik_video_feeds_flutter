import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/dimens.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class TagPeopleScreen extends StatefulWidget {
  const TagPeopleScreen({
    Key? key,
    required this.postAttributeClass,
  }) : super(key: key);

  final PostAttributeClass postAttributeClass;

  @override
  State<TagPeopleScreen> createState() => _TagPeopleScreenState();
}

class _TagPeopleScreenState extends State<TagPeopleScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<int, List<MentionData>> _mediaMentionedMap = {}; // Mentioned for each media item
  final Map<int, List<MentionData>> _mediaTaggedMap = {}; // Tagged for each media item
  final Map<int, GlobalKey> _mentionedImageKeys = {}; // Unique keys for each image  // <-- HERE
  final Map<int, GlobalKey> _taggedImageKeys = {}; // Unique keys for each image  // <-- HERE
  var _mediaDataList = <MediaData>[];
  var _mentionDataList = <MentionData>[];
  var _tagDataList = <MentionData>[];
  late PostAttributeClass _postAttributeClass;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _postAttributeClass = widget.postAttributeClass;
    _mediaDataList = _postAttributeClass.mediaDataList ?? [];
    _mentionDataList = _postAttributeClass.mentionedUserList
            ?.where((mentionData) => mentionData.mediaPosition != null)
            .toList() ??
        [];
    _tagDataList = _postAttributeClass.tagDataList
            ?.where((mentionData) => mentionData.mediaPosition != null)
            .toList() ??
        [];
    for (var i = 0; i < _mentionDataList.length; i++) {
      _mediaMentionedMap[i] = [_mentionDataList[i]];
      _mentionedImageKeys[i] = GlobalKey();
    }
    for (var i = 0; i < _tagDataList.length; i++) {
      _mediaTaggedMap[i] = [_tagDataList[i]];
      _taggedImageKeys[i] = GlobalKey();
    }
  }

  List<MentionData> get currentMentions => _mediaMentionedMap[_currentIndex] ?? [];

  List<MentionData> get currentTags => _mediaTaggedMap[_currentIndex] ?? [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.black, size: 24.scaledValue),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tag people',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: Dimens.edgeInsets(right: 10.scaledValue),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: _setData,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Media Carousel Section with Tagging
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.applyOpacity(0.1),
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
                          itemBuilder: (context, index) =>
                              _mediaDataList[index].mediaType == 'video'
                                  ? _buildVideoPlayer(_mediaDataList[index].localPath ?? '')
                                  : _buildTaggableImageView(
                                      _mediaDataList[index].localPath ?? '', index),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? Colors.white
                                        : Colors.white.applyOpacity(0.5),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.applyOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, color: Colors.white, size: 16),
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
              Container(
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
              ),

              // Instructions and Tagged People
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Instructions
                      const SizedBox(height: 20),
                      Icon(
                        Icons.touch_app_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap on people in the photo to tag them.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Tagged People List
                      if (currentMentions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Mentioned in this photo:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...currentMentions
                            .map((tag) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    tileColor: Colors.blue[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: AppImage.network(
                                      tag.avatarUrl ?? '',
                                      height: 30.scaledValue,
                                      width: 30.scaledValue,
                                      name: tag.name ?? '',
                                      isProfileImage: true,
                                    ),
                                    title: Text(
                                      tag.username!,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _mediaMentionedMap[_currentIndex]?.remove(tag);
                                        });
                                      },
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                      if (currentTags.isNotEmpty) ...[
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 12),
                        ...currentTags
                            .map((tag) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    tileColor: Colors.blue[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: AppImage.network(
                                      tag.avatarUrl ?? '',
                                      height: 30.scaledValue,
                                      width: 30.scaledValue,
                                      name: tag.name ?? '',
                                      isProfileImage: true,
                                    ),
                                    title: Text(
                                      tag.tag!,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _mediaTaggedMap[_currentIndex]?.remove(tag);
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

  Widget _buildTaggableImageView(String imageUrl, int mediaIndex) => LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapUp: (TapUpDetails details) {
            // if (_mediaDataList[mediaIndex].mediaType == 'image') {
            _handleImageTap(details, constraints, mediaIndex);
            // }
          },
          child: Stack(
            children: [
              // Main Image
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AppImage.file(
                  imageUrl,
                  fit: BoxFit.cover,
                  key: _mentionedImageKeys[mediaIndex], // Use unique key for each image
                ),
              ),

              // Tag Markers
              ...currentMentions
                  .map((tag) => Positioned(
                        left: ((tag.textPosition?.start ?? 0) * constraints.maxWidth) - 12,
                        top: ((tag.textPosition?.end ?? 0) * constraints.maxHeight) - 12,
                        child: _buildTagMarker(tag),
                      ))
                  .toList(),
            ],
          ),
        ),
      );

  Widget _buildTagMarker(MentionData tag) => GestureDetector(
        onTap: () {
          // _showTagDetails(tag);
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.applyOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              tag.username![0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Widget _buildVideoPlayer(String videoUrl) => Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.white,
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.applyOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.applyOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Video tagging not supported',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _handleImageTap(TapUpDetails details, BoxConstraints constraints, int mediaIndex) async {
    // Calculate relative position (0.0 to 1.0)
    final relativePosition = Offset(
      (details.localPosition.dx / constraints.maxWidth) * 100,
      (details.localPosition.dy / constraints.maxHeight) * 100,
    );

    final taggedUserList = await InjectionUtils.getRouteManagement().goToSearchUserScreen();

    if (taggedUserList.isEmptyOrNull) return;
    if (taggedUserList is List<SocialUserData>) {
      _setMentionedUserPosition(taggedUserList, mediaIndex, relativePosition);
    }
    if (taggedUserList is List<HashTagData>) {
      _setTagPosition(taggedUserList, mediaIndex, relativePosition);
    }
    // _showTagDialog(context, relativePosition, mediaIndex);
  }

  void _setMentionedUserPosition(
      List<SocialUserData> taggedUserList, int mediaIndex, Offset position) {
    for (var element in taggedUserList) {
      final mentionData = MentionData(
        mediaPosition: MediaPosition(
          position: mediaIndex + 1,
          x: position.dx.toInt(),
          y: position.dy.toInt(),
        ),
        userId: element.id,
        username: element.username,
        name: element.fullName,
        avatarUrl: element.avatarUrl,
      );
      _mediaMentionedMap[mediaIndex] = [mentionData];
    }
    debugPrint(
        'media mentions....${jsonEncode(_mediaMentionedMap.values.map((list) => list.map((mention) => mention.toJson()).toList()).toList())}');
    setState(() {});
  }

  void _setTagPosition(List<HashTagData> taggedList, int mediaIndex, Offset position) {
    for (var element in taggedList) {
      final mentionData = MentionData(
        mediaPosition: MediaPosition(
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
    _setMentionData();
    _setTagData();
    Navigator.pop(context, _postAttributeClass);
  }

  void _setMentionData() {
    // Combine all mentions into a single list
    final combinedMentions = <MentionData>[
      ..._postAttributeClass.mentionedUserList ?? [],
      ..._mediaMentionedMap.values.expand((list) => list).toList(),
    ];

    // Use a Set to remove duplicates based on the MentionData object's properties
    final uniqueMentions = <MentionData>{};
    for (final mention in combinedMentions) {
      // You need to override the hashCode and == operators in your MentionData class
      // to correctly check for equality. Without this, the Set will treat every object
      // as unique.
      uniqueMentions.add(mention);
    }

    final finalMentionDataList = uniqueMentions.toList();

    _postAttributeClass.mentionedUserList = finalMentionDataList;
    debugPrint('final mention data list....${jsonEncode(finalMentionDataList)}');
  }

  void _setTagData() {
    // Combine all mentions into a single list
    final combinedMentions = <MentionData>[
      ..._postAttributeClass.tagDataList ?? [],
      ..._mediaTaggedMap.values.expand((list) => list).toList(),
    ];

    // Use a Set to remove duplicates based on the MentionData object's properties
    final uniqueMentions = <MentionData>{};
    for (final mention in combinedMentions) {
      // You need to override the hashCode and == operators in your MentionData class
      // to correctly check for equality. Without this, the Set will treat every object
      // as unique.
      uniqueMentions.add(mention);
    }

    final finalTagDataList = uniqueMentions.toList();

    _postAttributeClass.tagDataList = finalTagDataList;
    debugPrint('final tag data list....${jsonEncode(finalTagDataList)}');
  }
}
