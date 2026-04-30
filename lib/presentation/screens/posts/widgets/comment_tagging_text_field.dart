import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertagger/fluttertagger.dart';
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
    this.textStyle,
    this.userTagTextStyle,
    this.hashtagTextStyle,
    this.hintStyle,
    this.decoration,
    this.onAddMentionData,
    this.onRemoveMentionData,
    this.onAddHashTagData,
    this.onRemoveHashTagData,
    this.overlayPosition = OverlayPosition.top,
    /// Width of the floating suggestion overlay (user + hashtag). When null, content uses
    /// the full width of the text field (fluttertagger default).
    this.overlayWidth,
    this.autoFocus,
    this.focusNode,
    /// Puts @ / # suggestion lists below the field (create-post caption) instead of a floating overlay.
    this.inlineSuggestionsBelow = false,
    /// Puts @ / # suggestion lists above the field (comments sheet) instead of a floating overlay.
    this.inlineSuggestionsAbove = false,
    this.searchDebounce = const Duration(milliseconds: 10),
    /// When set, search is skipped while the whole field text is shorter than this (caption UX).
    this.minTotalTextLengthForSearch,
    /// Search runs only when `query.length > minSearchQueryLength`. Default `1` matches comments (need 2+ query chars).
    /// Use `2` for create-post (need 3+ chars after @/#), matching the previous caption field behavior.
    this.minSearchQueryLength = 1,
    /// Padding around the text field only (e.g. horizontal inset for caption).
    this.textFieldPadding,
    /// Max height of the outer wrapper when not inline. Defaults to `150` when null (comment sheet).
    this.maxOuterHeight,
    /// Wraps the field in a [SingleChildScrollView] (comment box); caption turns this off.
    this.wrapFieldInScrollView = true,
    /// Maximum viewport fraction used by inline suggestions list(s).
    this.inlineSuggestionMaxHeightFactor = 0.3,
  }) : super(key: key);

  final FlutterTaggerController controller;
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
  final TextStyle? textStyle;
  final TextStyle? userTagTextStyle;
  final TextStyle? hashtagTextStyle;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final bool? autoFocus;
  final FocusNode? focusNode;
  final bool inlineSuggestionsBelow;
  final bool inlineSuggestionsAbove;
  final OverlayPosition overlayPosition;
  final double? overlayWidth;
  final Duration searchDebounce;
  final int? minTotalTextLengthForSearch;
  final int minSearchQueryLength;
  final EdgeInsetsGeometry? textFieldPadding;
  final double? maxOuterHeight;
  final bool wrapFieldInScrollView;
  final double inlineSuggestionMaxHeightFactor;

  /// Registers plain `@name` / `#tag` segments in the tagger trie so they render with tag styling.
  ///
  /// Must be called on a **new** [FlutterTaggerController] whose text is already set, **before**
  /// that controller is attached to a [FlutterTagger] (e.g. recreate the controller when loading
  /// edit-post caption). Otherwise [FlutterTaggerController.formatTags] runs too late and the
  /// package will not apply custom patterns.
  static void applyPlainTextTagHighlights(FlutterTaggerController controller) {
    final t = controller.text;
    if (t.isEmpty) return;
    controller.formatTags(
      pattern: RegExp(r'(@[^\s@#]+|#[^\s@#]+)'),
      parser: (String value) {
        if (value.startsWith('@')) {
          final name = value.substring(1);
          return <String>[name, name];
        }
        if (value.startsWith('#')) {
          final tag = value.substring(1);
          return <String>[tag, tag];
        }
        return <String>['', value];
      },
    );
  }

  @override
  State<CommentTaggingTextField> createState() =>
      _CommentTaggingTextFieldState();
}

class _CommentTaggingTextFieldState extends State<CommentTaggingTextField> {
  final List<SocialUserData> _searchResults = [];
  final List<HashTagData> _hashTagResults = [];
  final Map<String, SocialUserData> _userMetaById = {};
  final List<CommentMentionData> _addedHashtags = [];
  final List<CommentMentionData> _addedMentions = [];
  Timer? _debounce;
  String _activeTrigger = '';
  var _committingTag = false;
  var _showLoading = false;

  SearchUserBloc get _searchUserBloc => context.getOrCreateBloc();

  bool get _useInlineSuggestions =>
      widget.inlineSuggestionsBelow || widget.inlineSuggestionsAbove;

  double? get _effectiveMaxOuterHeight =>
      _useInlineSuggestions ? null : (widget.maxOuterHeight ?? 150);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CommentTaggingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    if (!_committingTag) {
      _tryCommitBareHashtagAtEnd();
    }
    if (!_committingTag) {
      _reconcileSearchUiWhenCursorLeftTagQuery();
    }
    widget.onChanged?.call(widget.controller.text);
    _syncMentionDataFromTags();
  }

  /// True while the caret is still inside an unfinished `@query` or `#query` (no space/newline in segment).
  /// Matches the tagger's notion of "search active" so we can hide suggestions after space or backspace.
  bool _isCursorInIncompleteTagSearch(String text, int cursor) {
    if (cursor < 0) return false;
    final textBeforeCursor = text.substring(0, cursor);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    final lastHashIndex = textBeforeCursor.lastIndexOf('#');

    var inAt = false;
    var inHash = false;

    if (lastAtIndex != -1 && lastHashIndex != -1) {
      if (lastAtIndex > lastHashIndex) {
        final textFromAt = text.substring(lastAtIndex + 1, cursor);
        final hasMultipleAts =
            lastAtIndex > 0 && textBeforeCursor[lastAtIndex - 1] == '@';
        if (!textFromAt.contains(' ') &&
            !textFromAt.contains('\n') &&
            !hasMultipleAts &&
            !textFromAt.contains('@') &&
            !textFromAt.contains('#')) {
          inAt = true;
        }
      } else {
        final textFromHash = text.substring(lastHashIndex + 1, cursor);
        final hasMultipleHashes =
            lastHashIndex > 0 && textBeforeCursor[lastHashIndex - 1] == '#';
        if (!textFromHash.contains(' ') &&
            !textFromHash.contains('\n') &&
            !hasMultipleHashes &&
            !textFromHash.contains('#') &&
            !textFromHash.contains('@')) {
          inHash = true;
        }
      }
    } else if (lastAtIndex != -1) {
      final textFromAt = text.substring(lastAtIndex + 1, cursor);
      final hasMultipleAts =
          lastAtIndex > 0 && textBeforeCursor[lastAtIndex - 1] == '@';
      if (!textFromAt.contains(' ') &&
          !textFromAt.contains('\n') &&
          !hasMultipleAts &&
          !textFromAt.contains('@') &&
          !textFromAt.contains('#')) {
        inAt = true;
      }
    } else if (lastHashIndex != -1) {
      final textFromHash = text.substring(lastHashIndex + 1, cursor);
      final hasMultipleHashes =
          lastHashIndex > 0 && textBeforeCursor[lastHashIndex - 1] == '#';
      if (!textFromHash.contains(' ') &&
          !textFromHash.contains('\n') &&
          !hasMultipleHashes &&
          !textFromHash.contains('#') &&
          !textFromHash.contains('@')) {
        inHash = true;
      }
    }

    return inAt || inHash;
  }

  /// Clears user/hashtag suggestion state when the cursor leaves an incomplete @/# search (e.g. space
  /// typed without picking, or backspace). FlutterTagger hides its overlay internally; our inline
  /// lists and [_activeTrigger] must be cleared the same way.
  void _reconcileSearchUiWhenCursorLeftTagQuery() {
    if (_committingTag) return;

    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final len = text.length;
    final cursor = !sel.isValid
        ? len
        : math.min(len, math.max(0, sel.baseOffset));

    if (_isCursorInIncompleteTagSearch(text, cursor)) return;

    if (_activeTrigger.isNotEmpty ||
        _searchResults.isNotEmpty ||
        _hashTagResults.isNotEmpty ||
        _showLoading) {
      _debounce?.cancel();
      setState(() {
        _activeTrigger = '';
        _searchResults.clear();
        _hashTagResults.clear();
        _showLoading = false;
      });
      widget.controller.dismissOverlay();
    }
  }

  /// Ensures a valid collapsed caret before addTag: fluttertagger uses the selection offset and
  /// throws if the field reports an invalid selection (e.g. after tapping the suggestion overlay).
  void _ensureCollapsedSelectionForAddTag() {
    final text = widget.controller.text;
    final len = text.length;
    final sel = widget.controller.selection;
    final offset = sel.baseOffset;
    if (!sel.isValid || offset < 0 || offset > len) {
      widget.controller.selection = TextSelection.collapsed(offset: len);
    }
  }

  /// When the user finishes a hashtag with a space (#tag ), register it as a tag (parity with old behavior).
  void _tryCommitBareHashtagAtEnd() {
    final text = widget.controller.text;
    if (text.isEmpty || !text.endsWith(' ')) return;

    final match = RegExp(r'#([^\s#@]+) $').firstMatch(text);
    if (match == null) return;

    final tagName = match.group(1)!;
    final alreadyTagged = widget.controller.tags.any(
      (t) => t.triggerCharacter == '#' && t.text == tagName,
    );
    if (alreadyTagged) return;

    _committingTag = true;
    try {
      _ensureCollapsedSelectionForAddTag();
      widget.controller.addTag(id: tagName, name: tagName);
    } finally {
      _committingTag = false;
    }
    _scheduleEmitHashtag(tagName);
  }

  void _scheduleEmitHashtag(String tagName) {
    _emitHashtagAfterAddTag(tagName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitHashtagAfterAddTag(tagName);
    });
  }

  void _scheduleEmitUserMention(SocialUserData user) {
    _emitUserMentionAfterAddTag(user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitUserMentionAfterAddTag(user);
    });
  }

  /// Drops tracked mentions/hashtags that no longer appear in the field text. Add callbacks are
  /// emitted from controller text right after addTag — the tagger's tags iterable is unreliable
  /// immediately after a selection.
  void _syncMentionDataFromTags() {
    final text = widget.controller.text;

    if (text.trim().isEmpty) {
      _clearAllMentionsAndHashtags();
      return;
    }

    for (final old in List<CommentMentionData>.from(_addedMentions)) {
      final u = (old.username ?? '').trim();
      if (u.isEmpty) continue;
      if (!text.contains('@$u')) {
        _addedMentions.remove(old);
        widget.onRemoveMentionData?.call(old);
      }
    }
    for (final old in List<CommentMentionData>.from(_addedHashtags)) {
      final t = (old.tag ?? '').trim();
      if (t.isEmpty) continue;
      if (!text.contains('#$t')) {
        _addedHashtags.remove(old);
        widget.onRemoveHashTagData?.call(old);
      }
    }
  }

  bool _hasMentionAt(SocialUserData user, int start, int end) {
    final uid = user.id ?? '';
    final uname = (user.username ?? '').trim();
    return _addedMentions.any(
      (m) =>
          (m.userId ?? '') == uid &&
          (m.username ?? '').trim() == uname &&
          m.textPosition?.start == start &&
          m.textPosition?.end == end,
    );
  }

  bool _hasHashtagAt(String tag, int start, int end) =>
      _addedHashtags.any(
        (m) =>
            (m.tag ?? '').trim() == tag.trim() &&
            m.textPosition?.start == start &&
            m.textPosition?.end == end,
      );

  void _emitUserMentionAfterAddTag(SocialUserData user) {
    final uname = (user.username ?? '').trim();
    if (uname.isEmpty) return;

    final text = widget.controller.text;
    final pattern = '@$uname';
    final start = text.lastIndexOf(pattern);
    if (start < 0) return;
    final end = start + pattern.length;
    if (_hasMentionAt(user, start, end)) return;

    final data = CommentMentionData(
      userId: user.id ?? '',
      username: uname,
      textPosition: CommentTaggedPosition(start: start, end: end),
      avatarUrl: user.avatarUrl,
      name: user.displayName ?? user.fullName,
    );
    _addedMentions.add(data);
    widget.onAddMentionData?.call(data);
  }

  void _emitHashtagAfterAddTag(String rawTag) {
    final tag = rawTag.trim();
    if (tag.isEmpty) return;

    final text = widget.controller.text;
    final pattern = '#$tag';
    final start = text.lastIndexOf(pattern);
    if (start < 0) return;
    final end = start + pattern.length;
    if (_hasHashtagAt(tag, start, end)) return;

    final data = CommentMentionData(
      tag: tag,
      textPosition: CommentTaggedPosition(start: start, end: end),
    );
    _addedHashtags.add(data);
    widget.onAddHashTagData?.call(data);
  }

  void _clearAllMentionsAndHashtags() {
    for (var tag in _addedHashtags) {
      widget.onRemoveHashTagData?.call(tag);
    }
    _addedHashtags.clear();

    for (var mention in _addedMentions) {
      widget.onRemoveMentionData?.call(mention);
    }
    _addedMentions.clear();
    _userMetaById.clear();
  }

  void _onSearch(String query, String triggerCharacter) {
    _debounce?.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      if (!mounted) return;

      _activeTrigger = triggerCharacter;

      final minLen = widget.minTotalTextLengthForSearch;
      if (minLen != null && widget.controller.text.trim().length < minLen) {
        setState(() {
          _activeTrigger = '';
          _searchResults.clear();
          _hashTagResults.clear();
          _showLoading = false;
        });
        widget.controller.dismissOverlay();
        return;
      }

      if (query.length <= widget.minSearchQueryLength) {
        setState(() {
          _activeTrigger = '';
          _searchResults.clear();
          _hashTagResults.clear();
          _showLoading = false;
        });
        widget.controller.dismissOverlay();
        return;
      }

      if (triggerCharacter == '@') {
        setState(() {
          _hashTagResults.clear();
          _searchResults.clear();
        });
        _searchUsers(query);
      } else if (triggerCharacter == '#') {
        setState(() {
          _searchResults.clear();
          _hashTagResults.clear();
        });
        _searchHashtags(query);
      }
    });
  }

  void _searchUsers(String query) {
    if (query.isEmpty) return;

    if (widget.inlineSuggestionsBelow) {
      setState(() => _showLoading = true);
    }

    _searchUserBloc.add(
      SearchUserEvent(
        searchText: query,
        isLoading: false,
        onComplete: (userList) {
          if (!mounted) return;
          if (_activeTrigger != '@') return;
          setState(() {
            _showLoading = false;
            _searchResults
              ..clear()
              ..addAll(userList);
          });
        },
      ),
    );
  }

  void _searchHashtags(String query) {
    if (query.isEmpty) return;

    if (widget.inlineSuggestionsBelow) {
      setState(() => _showLoading = true);
    }

    _searchUserBloc.add(
      SearchTagEvent(
        searchText: query,
        isLoading: false,
        onComplete: (tagList) {
          if (!mounted) return;
          if (_activeTrigger != '#') return;
          setState(() {
            _showLoading = false;
            _hashTagResults
              ..clear()
              ..addAll(tagList);
          });
        },
      ),
    );
  }

  bool _hashTagInResults(String term) {
    final t = term.trim().toLowerCase();
    if (t.isEmpty) return false;
    return _hashTagResults.any(
      (h) => (h.hashtag ?? '').trim().toLowerCase() == t,
    );
  }

  /// Stops showing inline (or overlay) suggestions after a row is chosen. Without this,
  /// `_activeTrigger` stays `#`/`@`, API results are cleared, and "Add tag" still matches
  /// because `_hashTagInResults` is false on an empty list.
  void _endSearchSessionAfterSelection() {
    _debounce?.cancel();
    setState(() {
      _activeTrigger = '';
      _searchResults.clear();
      _hashTagResults.clear();
      _showLoading = false;
    });
  }

  void _selectUser(SocialUserData user) {
    final id = user.id ?? '';
    final name = user.username ?? '';
    if (id.isNotEmpty) {
      _userMetaById[id] = user;
    }
    _committingTag = true;
    try {
      _ensureCollapsedSelectionForAddTag();
      widget.controller.addTag(id: id, name: name);
    } finally {
      _committingTag = false;
    }
    _scheduleEmitUserMention(user);
    widget.controller.dismissOverlay();
    _endSearchSessionAfterSelection();
  }

  void _selectHashTag(HashTagData hashTag) {
    final tag = (hashTag.hashtag ?? '').trim();
    if (tag.isEmpty) return;
    _committingTag = true;
    try {
      _ensureCollapsedSelectionForAddTag();
      widget.controller.addTag(id: tag, name: tag);
    } finally {
      _committingTag = false;
    }
    _scheduleEmitHashtag(tag);
    widget.controller.dismissOverlay();
    _endSearchSessionAfterSelection();
  }

  Widget _buildOverlay() {
    if (_activeTrigger == '@') {
      if (_searchResults.isEmpty) return const SizedBox.shrink();
      return _buildUserSuggestionsContent();
    }
    if (_activeTrigger == '#') {
      return _buildHashtagSuggestionsContent();
    }
    return const SizedBox.shrink();
  }

  /// Best-effort: search query is the text after the last `#` up to the cursor (same as fluttertagger).
  String _currentHashQuery() {
    final text = widget.controller.text;
    final pos = widget.controller.selection.baseOffset;
    if (pos < 0) return '';
    final before = text.substring(0, pos.clamp(0, text.length));
    final hashIdx = before.lastIndexOf('#');
    if (hashIdx < 0) return '';
    return before.substring(hashIdx + 1);
  }

  Widget _buildUserSuggestionsContent() => Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
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
          ),
        ),
      );

  Widget _buildInlineUserSuggestions() {
    if (!_useInlineSuggestions ||
        _activeTrigger != '@' ||
        _searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const Divider(height: 1, thickness: 1),
        Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                widget.inlineSuggestionMaxHeightFactor,
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
                      if (!user.avatarUrl.isEmptyOrNull)
                        AppImage.network(
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
                      else
                        CircleAvatar(
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
    );
  }

  Widget _buildInlineHashtagSuggestions() {
    if (!_useInlineSuggestions || _activeTrigger != '#') {
      return const SizedBox.shrink();
    }
    final query = _currentHashQuery().trim();
    final showHashtagResults = _hashTagResults.isNotEmpty;
    final showAddTagOption = !_showLoading &&
        query.isNotEmpty &&
        !_hashTagInResults(query);
    if (!showHashtagResults && !showAddTagOption) {
      return const SizedBox.shrink();
    }
    final itemCount = _hashTagResults.length + (showAddTagOption ? 1 : 0);

    return Column(
      children: [
        const Divider(height: 1, thickness: 1),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                widget.inlineSuggestionMaxHeightFactor,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: itemCount,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Colors.white,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              if (index < _hashTagResults.length) {
                final hasTag = _hashTagResults[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectHashTag(hasTag),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${hasTag.hashtag ?? ''}',
                              style: IsrStyles.primaryText14
                                  .copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
              }
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectHashTag(
                    HashTagData(hashtag: query),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: IsrColors.appColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add tag #$query',
                            style: IsrStyles.primaryText14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: IsrColors.appColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }

  Widget _buildHashtagSuggestionsContent() {
    final query = _currentHashQuery().trim();
    final showAddTagOption =
        query.isNotEmpty && !_hashTagInResults(query);
    final itemCount = _hashTagResults.length + (showAddTagOption ? 1 : 0);
    if (itemCount == 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
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
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: itemCount,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: Colors.white,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            if (index < _hashTagResults.length) {
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
                        Expanded(
                          child: Text(
                            '#${hasTag.hashtag ?? ''}',
                            style: IsrStyles.primaryText14
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
            }
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectHashTag(
                  HashTagData(hashtag: query),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: IsrColors.appColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add tag #$query',
                          style: IsrStyles.primaryText14.copyWith(
                            fontWeight: FontWeight.w600,
                            color: IsrColors.appColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Applies [CommentTaggingTextField.overlayWidth] to the fluttertagger overlay (shared by
  /// user and hashtag lists). The package still positions using the text field width; this
  /// constrains the suggestion panel width and centers it when narrower than the field.
  Widget _wrapSuggestionOverlay(Widget overlayContent) {
    final w = widget.overlayWidth;
    if (w == null) return overlayContent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final effectiveW = maxW.isFinite && maxW > 0
            ? math.min(w, maxW)
            : w;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: effectiveW,
            child: overlayContent,
          ),
        );
      },
    );
  }

  Widget _buildFlutterTagger() {
    final baseStyle = widget.textStyle ??
        const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        );
    final fieldStyle = widget.inlineSuggestionsBelow
        ? baseStyle.copyWith(color: widget.textStyle?.color ?? Colors.black87)
        : baseStyle;

    return FlutterTagger(
      controller: widget.controller,
      onSearch: _onSearch,
      overlayHeight: _useInlineSuggestions ? 1 : 200,
      overlayPosition: widget.overlayPosition,
      padding: EdgeInsets.zero,
      triggerStrategy: TriggerStrategy.deferred,
      searchRegex: RegExp(r'[^\s@#]'),
      tagTextFormatter: (id, tag, triggerCharacter) =>
          '$triggerCharacter$tag',
      triggerCharacterAndStyles: {
        '@': widget.userTagTextStyle ??
            baseStyle.copyWith(
              color: IsrColors.appColor,
              fontWeight: FontWeight.w600,
            ),
        '#': widget.hashtagTextStyle ??
            baseStyle.copyWith(
              color: IsrColors.appColor,
              fontWeight: FontWeight.w600,
            ),
      },
      overlay: _useInlineSuggestions
          ? const SizedBox.shrink()
          : _wrapSuggestionOverlay(_buildOverlay()),
      builder: (context, textFieldKey) => TextField(
        key: textFieldKey,
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
        style: fieldStyle,
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
        onTap: widget.onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inlineSuggestionsAbove) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: Colors.blue,
            ),
          _buildInlineUserSuggestions(),
          _buildInlineHashtagSuggestions(),
          Padding(
            padding: widget.textFieldPadding ?? EdgeInsets.zero,
            child: _buildFlutterTagger(),
          ),
        ],
      );
    }

    if (widget.inlineSuggestionsBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: widget.textFieldPadding ?? EdgeInsets.zero,
            child: _buildFlutterTagger(),
          ),
          _buildInlineUserSuggestions(),
          _buildInlineHashtagSuggestions(),
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
    }

    var inner = _buildFlutterTagger();
    if (widget.wrapFieldInScrollView) {
      inner = SingleChildScrollView(child: inner);
    }
    final maxH = _effectiveMaxOuterHeight;
    if (maxH != null) {
      return Container(
        constraints: BoxConstraints(maxHeight: maxH),
        child: inner,
      );
    }
    return inner;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }
}
