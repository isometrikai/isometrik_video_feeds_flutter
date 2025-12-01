import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserMentionTextField extends StatefulWidget {
  const UserMentionTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Write a caption...',
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.style,
    this.hintStyle,
    this.decoration,
    this.onAddMentionData,
    this.onRemoveMentionData,
    this.onAddHashTagData,
    this.onRemoveHashTagData,
  }) : super(key: key);
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final Function(MentionData)? onAddMentionData;
  final Function(MentionData)? onRemoveMentionData;
  final Function(MentionData)? onAddHashTagData;
  final Function(MentionData)? onRemoveHashTagData;
  final TextStyle? style;

  final TextStyle? hintStyle;
  final InputDecoration? decoration;

  @override
  State<UserMentionTextField> createState() => _UserMentionTextFieldState();
}

class _UserMentionTextFieldState extends State<UserMentionTextField> {
  final List<SocialUserData> _searchResults = [];
  final List<HashTagData> _hashTagResults = [];
  bool _showLoading = false;
  bool _isSearching = false;
  String _currentSearchTerm = '';
  SearchUserBloc get _searchUserBloc =>
      BlocProvider.of<SearchUserBloc>(context);
  final List<MentionData> _addedHashtags = [];
  final List<MentionData> _addedMentions = [];
  bool _ignoreNextChange = false;
  Timer? _debounce;

  // Track hashtag search state for auto-creation
  bool _isHashtagSearchActive = false;
  String _lastHashtagSearchTerm = '';

  void _onTextChanged(String text) async {
    if (_ignoreNextChange) return;

    // If text is empty, clear all mentions and hashtags immediately
    if (text.trim().isEmpty) {
      _clearAllMentionsAndHashtags();
    }

    // Debounce: cancel previous timer and start a new one
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      // 1. Handle empty text immediately
      if (text.trim().length < 4) {
        _currentSearchTerm = '';
        _hideMentionSuggestions();
        _hideTagSuggestions();
        if (_isSearching) {
          _isSearching = false;
          setState(() {});
        }
        return; // Prevent further searching
      }

      widget.onChanged?.call(text);

      final cursorPosition = widget.controller.selection.baseOffset;
      if (cursorPosition < 0) return;

      final textBeforeCursor = text.substring(0, cursorPosition);

      final lastAtIndex = textBeforeCursor.lastIndexOf('@');
      final lastHashIndex = textBeforeCursor.lastIndexOf('#');

      // Determine which trigger is more recent (closer to cursor)
      var shouldSearchMentions = false;
      var shouldSearchHashtags = false;
      var searchTerm = '';

      // Only process the most recent trigger character
      if (lastAtIndex != -1 && lastHashIndex != -1) {
        // Both triggers exist, use the one closer to cursor
        if (lastAtIndex > lastHashIndex) {
          // @ is more recent
          final textFromAt = text.substring(lastAtIndex + 1, cursorPosition);
          final hasMultipleAts =
              lastAtIndex > 0 && textBeforeCursor[lastAtIndex - 1] == '@';

          if (!textFromAt.contains(' ') &&
              !textFromAt.contains('\n') &&
              !hasMultipleAts &&
              !textFromAt.contains('@') &&
              !textFromAt.contains('#')) {
            shouldSearchMentions = true;
            searchTerm = textFromAt;
          }
        } else {
          // # is more recent
          final textFromHash =
              text.substring(lastHashIndex + 1, cursorPosition);
          final hasMultipleHashes =
              lastHashIndex > 0 && textBeforeCursor[lastHashIndex - 1] == '#';

          if (!textFromHash.contains(' ') &&
              !textFromHash.contains('\n') &&
              !hasMultipleHashes &&
              !textFromHash.contains('#') &&
              !textFromHash.contains('@')) {
            shouldSearchHashtags = true;
            searchTerm = textFromHash;
          }
        }
      } else if (lastAtIndex != -1) {
        // Only @ trigger exists
        final textFromAt = text.substring(lastAtIndex + 1, cursorPosition);
        final hasMultipleAts =
            lastAtIndex > 0 && textBeforeCursor[lastAtIndex - 1] == '@';

        if (!textFromAt.contains(' ') &&
            !textFromAt.contains('\n') &&
            !hasMultipleAts &&
            !textFromAt.contains('@') &&
            !textFromAt.contains('#')) {
          shouldSearchMentions = true;
          searchTerm = textFromAt;
        }
      } else if (lastHashIndex != -1) {
        // Only # trigger exists
        final textFromHash = text.substring(lastHashIndex + 1, cursorPosition);
        final hasMultipleHashes =
            lastHashIndex > 0 && textBeforeCursor[lastHashIndex - 1] == '#';

        if (!textFromHash.contains(' ') &&
            !textFromHash.contains('\n') &&
            !hasMultipleHashes &&
            !textFromHash.contains('#') &&
            !textFromHash.contains('@')) {
          shouldSearchHashtags = true;
          searchTerm = textFromHash;
        }
      }

      // Handle search based on which trigger is active
      if (shouldSearchMentions && searchTerm.length > 2) {
        _currentSearchTerm = searchTerm;
        _isHashtagSearchActive = false; // Not in hashtag mode
        _lastHashtagSearchTerm = '';
        _searchUsers(_currentSearchTerm);
        _hideTagSuggestions(); // Hide hashtag suggestions
        if (!_isSearching) {
          _isSearching = true;
          setState(() {});
        }
      } else if (shouldSearchHashtags && searchTerm.length > 2) {
        _currentSearchTerm = searchTerm;
        _isHashtagSearchActive = true; // In hashtag mode
        _lastHashtagSearchTerm = searchTerm;
        await _searchHashtags(_currentSearchTerm);
        _hideMentionSuggestions(); // Hide mention suggestions
        if (!_isSearching) {
          _isSearching = true;
          setState(() {});
        }
      } else {
        // Check if we just finished hashtag search and user pressed space
        if (_isHashtagSearchActive &&
            _lastHashtagSearchTerm.isNotEmpty &&
            text.endsWith(' ')) {
          _addHashtagFromSearch(_lastHashtagSearchTerm);
        }

        // Hide suggestions if search term is too short or no active search
        if (shouldSearchMentions && searchTerm.length <= 2) {
          _hideMentionSuggestions();
        } else if (shouldSearchHashtags && searchTerm.length <= 2) {
          _hideTagSuggestions();
        } else {
          // No active search
          _isHashtagSearchActive = false;
          _lastHashtagSearchTerm = '';
          _hideMentionSuggestions();
          _hideTagSuggestions();
        }

        if (_isSearching) {
          _isSearching = false;
          setState(() {});
        }
      }

      _checkAndRemoveUnusedTags(text);
    });
  }

  /// Add hashtag from search when no results found and user presses space
  void _addHashtagFromSearch(String hashtagText) {
    debugPrint('Adding hashtag from search: "$hashtagText"');

    // Find the position of the hashtag in the text
    final text = widget.controller.text;
    final hashtagWithSymbol = '#$hashtagText';
    final hashtagIndex = text.lastIndexOf(hashtagWithSymbol);

    if (hashtagIndex != -1) {
      final start = hashtagIndex;
      final end = start + hashtagWithSymbol.length;

      final mentionData = MentionData(
        tag: hashtagText.trim(),
        textPosition: TaggedPosition(start: start, end: end),
      );

      // Check if not already added
      if (!_addedHashtags
          .any((existing) => existing.tag == hashtagText.trim())) {
        _addedHashtags.add(mentionData);
        widget.onAddHashTagData?.call(mentionData);
        debugPrint('Hashtag added: ${mentionData.tag}');
      }
    }

    _hideSuggestions();
  }

  void _addHashtag() {
    final start =
        widget.controller.selection.baseOffset - _currentSearchTerm.length - 1;
    final end =
        start + _currentSearchTerm.length + 1; // +1 for the '#' character
    final newTag = HashTagData(
      hashtag: _currentSearchTerm.trim(),
      slug: _currentSearchTerm.trim(),
      usageCount: 0,
      id: Utility.generateRandomId(6),
    );

    final mentionData = MentionData(
      tag: newTag.hashtag,
      textPosition: TaggedPosition(start: start, end: end),
    );
    _addedHashtags.add(mentionData);

    widget.onAddHashTagData?.call(mentionData);
    _hideSuggestions();
  }

  void _clearAllMentionsAndHashtags() {
    // Clear all hashtags one by one
    for (var tag in _addedHashtags) {
      widget.onRemoveHashTagData?.call(tag);
    }
    _addedHashtags.clear();

    // Clear all mentions one by one
    for (var mention in _addedMentions) {
      widget.onRemoveMentionData?.call(mention);
    }
    _addedMentions.clear();
  }

  void _checkAndRemoveUnusedTags(String text) {
    // Check hashtags - only remove if the hashtag is completely missing from text
    final removedHashtags = _addedHashtags.where((tag) {
      final hashtagText = '#${tag.tag}';
      return !text.contains(hashtagText);
    }).toList();
    for (var tag in removedHashtags) {
      _addedHashtags.remove(tag);
      widget.onRemoveHashTagData?.call(tag); // Notify or handle removal
    }

    // Check mentions - only remove if the mention is completely missing from text
    final removedMentions = _addedMentions.where((mention) {
      final mentionText = '@${mention.username}';
      return !text.contains(mentionText);
    }).toList();
    for (var mention in removedMentions) {
      _addedMentions.remove(mention);
      widget.onRemoveMentionData?.call(mention); // Notify or handle removal
    }
  }

  void _hideSuggestions() {
    _currentSearchTerm = '';
    _isSearching = false;
    _isHashtagSearchActive = false;
    _lastHashtagSearchTerm = '';
    setState(() {});
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final completer = Completer<void>();
    _showLoading = true;
    _searchUserBloc.add(
      SearchUserEvent(
        searchText: query,
        isLoading: false,
        onComplete: (userList) {
          _showLoading = false;
          completer.complete();
          _setResult(userList);
        },
      ),
    );
  }

  Future<void> _searchHashtags(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true; // Set to true to indicate searching
      _hashTagResults.clear();
    });

    final completer = Completer<void>();
    _showLoading = true;
    _searchUserBloc.add(
      SearchTagEvent(
        searchText: query,
        isLoading: false,
        onComplete: (tagList) {
          _showLoading = false;
          completer.complete();
          _setHashtagResult(tagList, query);
        },
      ),
    );
  }

  void _setResult(List<SocialUserData> userList) {
    _isSearching = true;
    _searchResults.clear();
    _searchResults.addAll(userList);
    if (mounted) {
      setState(() {});
    }
  }

  void _setHashtagResult(List<HashTagData> userList, String query) {
    _isSearching = true;
    _hashTagResults.clear();
    _hashTagResults.addAll(userList);
    if (mounted) {
      setState(() {});
    }
  }

  void _hideMentionSuggestions() {
    if (_isSearching) {
      _isSearching = false;
      _searchResults.clear();
      setState(() {});
    }
  }

  void _hideTagSuggestions() {
    if (_isSearching) {
      _isSearching = false;
      _hashTagResults.clear();
      setState(() {});
    }
  }

  void _selectUser(SocialUserData user) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // Replace the @searchterm with @username
      final beforeAt = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(cursorPosition);
      final mentionText = '@${user.username} ';
      final newText = '$beforeAt$mentionText$afterCursor';

      // Update the controller text
      widget.controller.text = newText;

      // Set new cursor position after the inserted mention
      final newCursorPosition = lastAtIndex + mentionText.length;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPosition),
      );

      // Calculate the position of the inserted mention
      final start = lastAtIndex;
      final end = start +
          (mentionText
              .trim()
              .length); // trim() to remove trailing space if you don't want it included

      final mentionData = MentionData(
        userId: user.id,
        username: user.username,
        textPosition: TaggedPosition(start: start, end: end),
        avatarUrl: user.avatarUrl,
      );

      _addedMentions.add(mentionData);
      // Add to mentioned users if not already added
      widget.onAddMentionData?.call(mentionData);
      widget.onChanged?.call(text);
    }

    _hideMentionSuggestions();
  }

  void _selectHashTag(HashTagData hashTag) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('#');

    if (lastAtIndex != -1) {
      // Replace the @searchterm with @username
      final beforeAt = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(cursorPosition);
      final tagText = '#${hashTag.hashtag} ';
      final newText = '$beforeAt$tagText$afterCursor';

      _ignoreNextChange = true;

      // Update the controller text
      widget.controller.text = newText;

      // Set new cursor position after the inserted mention
      final newCursorPosition = lastAtIndex + tagText.length;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPosition),
      );

      // Calculate the position of the inserted mention
      final start = lastAtIndex;
      final end = start +
          (tagText
              .trim()
              .length); // trim() to remove trailing space if you don't want it included

      final mentionData = MentionData(
        tag: hashTag.hashtag,
        textPosition: TaggedPosition(start: start, end: end),
      );

      _addedHashtags.add(mentionData);
      // Add to mentioned users if not already added
      widget.onAddHashTagData?.call(mentionData);
      widget.onChanged?.call(text);
      _ignoreNextChange = false;
    }

    _isHashtagSearchActive = false;
    _lastHashtagSearchTerm = '';
    _hideTagSuggestions();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: IsrDimens.edgeInsetsSymmetric(
                horizontal: 10.responsiveDimension),
            child: TextField(
              controller: widget.controller,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: widget.style ??
                  const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ??
                    TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: _onTextChanged,
              onTap: widget.onTap,
            ),
          ),

          // User and Hashtag Suggestions (moved above Generate with AI)
          _buildUserSuggestions(),
          _buildHashtagSuggestions(),

          // AI Generate Section - only show when no suggestions are visible
          // if (!_isSearching || (_searchResults.isEmpty && _hashTagResults.isEmpty))
          //   Container(
          //     margin:
          //        IsrDimens.edgeInsetsSymmetric(horizontal: 20.responsiveDimension, vertical: 10.responsiveDimension),
          //     padding:
          //        IsrDimens.edgeInsetsSymmetric(horizontal: 8.responsiveDimension, vertical: 4.responsiveDimension),
          //     decoration: BoxDecoration(color: 'F4F4F4'.toColor()),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const AppImage.svg(AssetConstants.icGenerateWithAI),
          //         8.horizontalSpace,
          //         Text(
          //           'Generate with AI',
          //           style: IsrStyles.primaryText12.copyWith(color: '202020'.toColor()),
          //         ),
          //       ],
          //     ),
          //   ),
          10.verticalSpace,
          if (_showLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: Colors.blue,
            )
          else
            const Divider(),
        ],
      );

  Widget _buildUserSuggestions() => _isSearching && _searchResults.isNotEmpty
      ? Column(
          children: [
            const Divider(height: 1, thickness: 1),
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.3, // Maximum 40% of screen height
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return InkWell(
                    onTap: () => _selectUser(user),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          !user.avatarUrl.isEmptyOrNull
                              ? AppImage.network(
                                  user.avatarUrl!,
                                  isProfileImage: true,
                                  height: 25.responsiveDimension,
                                  width: 25.responsiveDimension,
                                  border: Border.all(color: '979797'.toColor()),
                                  name: user.username
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      '',
                                )
                              : CircleAvatar(
                                  radius: IsrDimens.twelve,
                                  backgroundColor: IsrColors.white,
                                  child: Text(
                                    Utility.getInitials(
                                      firstName: user.displayName
                                              ?.split(' ')
                                              .firstOrNull ??
                                          '',
                                      lastName: user.displayName
                                              ?.split(' ')
                                              .lastOrNull ??
                                          '',
                                    ),
                                    style: IsrStyles.primaryText12.copyWith(
                                      color: IsrColors.appColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.displayName != user.username) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    user.username ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        )
      : const SizedBox.shrink();

  Widget _buildHashtagSuggestions() =>
      _isSearching && _hashTagResults.isNotEmpty
          ? Column(
              children: [
                const Divider(height: 1, thickness: 1),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height *
                        0.4, // Maximum 40% of screen height
                    // minHeight: 200, // Minimum height to show some items
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _hashTagResults.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Colors.white,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final hasTag = _hashTagResults[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectHashTag(hasTag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              children: [
                                // Hashtag content
                                Expanded(
                                  child: Text(
                                    '#${hasTag.hashtag ?? ''}',
                                    style: IsrStyles.primaryText14
                                        .copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Post count on the right
                                if (hasTag.usageCount != null &&
                                    hasTag.usageCount! > 0)
                                  Text(
                                    '${hasTag.usageCount} Posts',
                                    style: IsrStyles.primaryText14
                                        .copyWith(color: '868686'.toColor()),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const SizedBox.shrink();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
