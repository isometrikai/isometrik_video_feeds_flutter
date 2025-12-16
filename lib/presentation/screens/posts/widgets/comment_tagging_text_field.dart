import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CommentTaggingTextField extends StatefulWidget {
  const CommentTaggingTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Add a comment...',
    this.maxLines,
    this.minLines = 1,
    this.expands = false,
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
    this.autoFocus,
    this.focusNode,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final int? maxLines;
  final int minLines;
  final bool expands;
  final int? maxLength;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final Function(CommentMentionData)? onAddMentionData;
  final Function(CommentMentionData)? onRemoveMentionData;
  final Function(CommentMentionData)? onAddHashTagData;
  final Function(CommentMentionData)? onRemoveHashTagData;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final bool? autoFocus;
  final FocusNode? focusNode;

  @override
  State<CommentTaggingTextField> createState() =>
      _CommentTaggingTextFieldState();
}

class _CommentTaggingTextFieldState extends State<CommentTaggingTextField> {
  final List<SocialUserData> _searchResults = [];
  final List<HashTagData> _hashTagResults = [];
  bool _isSearching = false;
  String _currentSearchTerm = '';
  SearchUserBloc get _searchUserBloc => context.getOrCreateBloc();
  final List<CommentMentionData> _addedHashtags = [];
  final List<CommentMentionData> _addedMentions = [];
  bool _ignoreNextChange = false;
  Timer? _debounce;

  // Track hashtag search state for auto-creation
  bool _isHashtagSearchActive = false;
  String _lastHashtagSearchTerm = '';

  // Overlay for popup suggestions
  OverlayEntry? _overlayEntry;
  final GlobalKey _textFieldKey = GlobalKey();

  void _onTextChanged(String text) async {
    if (_ignoreNextChange) return;

    // If text is empty, clear all mentions and hashtags immediately
    if (text.trim().isEmpty) {
      _clearAllMentionsAndHashtags();
    }

    // Debounce: cancel previous timer and start a new one
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 10), () {
      _searchMentions(text);
    });
  }

  void _searchMentions(String text) async {
    // 1. Handle empty text immediately
    if (text.trim().length < 2) {
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
    if (shouldSearchMentions && searchTerm.length > 1) {
      _currentSearchTerm = searchTerm;
      _isHashtagSearchActive = false; // Not in hashtag mode
      _lastHashtagSearchTerm = '';
      _searchUsers(searchTerm);
      _hideTagSuggestions(); // Hide hashtag suggestions
      if (!_isSearching) {
        _isSearching = true;
        setState(() {});
      }
    } else if (shouldSearchHashtags && searchTerm.length > 1) {
      _currentSearchTerm = searchTerm;
      _isHashtagSearchActive = true; // In hashtag mode
      _lastHashtagSearchTerm = searchTerm;
      await _searchHashtags(searchTerm);
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
      if (shouldSearchMentions && searchTerm.length <= 1) {
        _hideMentionSuggestions();
      } else if (shouldSearchHashtags && searchTerm.length <= 1) {
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

      final mentionData = CommentMentionData(
        tag: hashtagText.trim(),
        textPosition: CommentTaggedPosition(start: start, end: end),
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
    _removeOverlay();
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

    _searchUserBloc.add(
      SearchUserEvent(
        searchText: query,
        isLoading: false,
        onComplete: (userList) {
          completer.complete();
          if (!_isHashtagSearchActive && query == _currentSearchTerm) {
            _setResult(userList);
          }
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

    _searchUserBloc.add(
      SearchTagEvent(
        searchText: query,
        isLoading: false,
        onComplete: (tagList) {
          completer.complete();
          if (_isHashtagSearchActive && query == _currentSearchTerm) {
            _setHashtagResult(tagList, query);
          }
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
      _showOverlay();
    }
  }

  void _setHashtagResult(List<HashTagData> userList, String query) {
    _isSearching = true;
    _hashTagResults.clear();
    _hashTagResults.addAll(userList);
    if (mounted) {
      setState(() {});
      _showOverlay();
    }
  }

  void _hideMentionSuggestions() {
    if (_isSearching) {
      _isSearching = false;
      _searchResults.clear();
      _removeOverlay();
      setState(() {});
    }
  }

  void _hideTagSuggestions() {
    if (_isSearching) {
      _isSearching = false;
      _hashTagResults.clear();
      _removeOverlay();
      setState(() {});
    }
  }

  void _selectUser(SocialUserData user) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // Replace the @searcher with @username
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

      final mentionData = CommentMentionData(
        userId: user.id,
        username: user.username,
        textPosition: CommentTaggedPosition(start: start, end: end),
        avatarUrl: user.avatarUrl,
        name: user.displayName,
      );

      _addedMentions.add(mentionData);
      // Add to mentioned users if not already added
      widget.onAddMentionData?.call(mentionData);
      widget.onChanged?.call(text);
    }

    _hideMentionSuggestions();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    if (!_isSearching || (_searchResults.isEmpty && _hashTagResults.isEmpty)) {
      return;
    }

    final renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        // top: position.dy - 200, // Show above the text field
        bottom: MediaQuery.of(context).size.height - position.dy,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSuggestionsContent(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionsContent() {
    if (_searchResults.isNotEmpty) {
      return _buildUserSuggestionsContent();
    } else if (_hashTagResults.isNotEmpty) {
      return _buildHashtagSuggestionsContent();
    }
    return const SizedBox.shrink();
  }

  Widget _buildUserSuggestionsContent() => ListView.separated(
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
                  AppImage.network(
                    user.avatarUrl!,
                    isProfileImage: true,
                    height: 25.responsiveDimension,
                    width: 25.responsiveDimension,
                    border: Border.all(color: '979797'.toColor()),
                    name: user.username?.substring(0, 1).toUpperCase() ?? '',
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
      );

  Widget _buildHashtagSuggestionsContent() => ListView.separated(
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
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    if (hasTag.usageCount != null && hasTag.usageCount! > 0)
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
      );

  void _selectHashTag(HashTagData hashTag) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('#');

    if (lastAtIndex != -1) {
      // Replace the #searchterm with #hashtag
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

      final mentionData = CommentMentionData(
        tag: hashTag.hashtag,
        textPosition: CommentTaggedPosition(start: start, end: end),
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
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(
          maxHeight: 150,
        ),
        child: SingleChildScrollView(
          child: TextField(
            key: _textFieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            autocorrect: false,
            expands: widget.expands,
            autofocus: widget.autoFocus == true,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: widget.style ??
                const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
            decoration: widget.decoration ??
                InputDecoration(
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
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }
}
