import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class UserMentionTextField extends StatefulWidget {
  const UserMentionTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Write a caption...',
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
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
  bool _isSearching = false;
  String _currentSearchTerm = '';
  final _searchUserBloc = InjectionUtils.getBloc<SearchUserBloc>();
  final List<MentionData> _addedHashtags = [];
  final List<MentionData> _addedMentions = [];
  bool _ignoreNextChange = false;

  void _onTextChanged(String text) async {
    if (_ignoreNextChange) return;

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
    if (shouldSearchMentions) {
      _currentSearchTerm = searchTerm;
      _searchUsers(_currentSearchTerm);
      _hideTagSuggestions(); // Hide hashtag suggestions
      if (!_isSearching) {
        _isSearching = true;
        setState(() {});
      }
    } else if (shouldSearchHashtags) {
      _currentSearchTerm = searchTerm;
      await _searchHashtags(_currentSearchTerm);
      _hideMentionSuggestions(); // Hide mention suggestions
      if (!_isSearching) {
        _isSearching = true;
        setState(() {});
      }
    } else {
      // No active search
      _hideMentionSuggestions();
      _hideTagSuggestions();
      if (_isSearching) {
        _isSearching = false;
        setState(() {});
      }
    }

    // Handle automatic hashtag creation when space is pressed
    if (text.endsWith(' ') &&
        shouldSearchHashtags &&
        searchTerm.isNotEmpty &&
        _hashTagResults.isEmpty) {
      _addHashtag();
    }

    _checkAndRemoveUnusedTags(text);
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
        textPosition: TaggedPosition(start: start, end: end));
    _addedHashtags.add(mentionData);

    widget.onAddHashTagData?.call(mentionData);
    _hideSuggestions();
  }

  void _checkAndRemoveUnusedTags(String text) {
    // Check hashtags
    final removedHashtags =
        _addedHashtags.where((tag) => !text.contains('#${tag.tag}')).toList();
    for (var tag in removedHashtags) {
      _addedHashtags.remove(tag);
      widget.onRemoveHashTagData?.call(tag); // Notify or handle removal
    }

    // Check mentions
    final removedMentions = _addedMentions
        .where((mention) => !text.contains('@${mention.name}'))
        .toList();
    for (var mention in removedMentions) {
      _addedMentions.remove(mention);
      widget.onRemoveMentionData?.call(mention); // Notify or handle removal
    }
  }

  void _hideSuggestions() {
    _currentSearchTerm = '';
    _isSearching = false;
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
      _isSearching = false;
      _searchResults.clear();
    });

    final completer = Completer<void>();
    _searchUserBloc.add(
      SearchUserEvent(
        searchText: query,
        onComplete: (userList) {
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
      _isSearching = false;
      _searchResults.clear();
    });

    final completer = Completer<void>();
    _searchUserBloc.add(
      SearchTagEvent(
        searchText: query,
        onComplete: (tagList) {
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

    _hideTagSuggestions();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
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
            ),
            _buildUserSuggestions(),
            _buildHashtagSuggestions(),
          ],
        ),
      );

  Widget _buildUserSuggestions() => _isSearching && _searchResults.isNotEmpty
      ? Column(
          children: [
            const Divider(height: 1, thickness: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
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
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            backgroundColor: Colors.grey.shade300,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.username
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
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
                                        user.username ?? '',
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
                                    user.displayName ?? '',
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
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _hashTagResults.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final hasTag = _hashTagResults[index];
                      return InkWell(
                        onTap: () => _selectHashTag(hasTag),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              // Circle with '#' icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '#',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Hashtag text and usage count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasTag.hashtag ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${hasTag.usageCount ?? 0} posts',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
}
