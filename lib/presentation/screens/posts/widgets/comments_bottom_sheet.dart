import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    required this.postId,
    this.onTapProfile,
    this.onTapHasTag,
    this.postData,
    this.tabData,
    this.commentConfig,
    this.highlightCommentId,
    Key? key,
  }) : super(key: key);

  final String postId;
  final Function(String)? onTapProfile;
  final Function(String)? onTapHasTag;
  final TimeLineData? postData;
  final TabDataModel? tabData;
  final CommentConfig? commentConfig;
  final String? highlightCommentId;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  SocialPostBloc get _socialBloc => context.getOrCreateBloc();
  IsmSocialActionCubit get _socialActionCubit => context.getOrCreateBloc();
  final _postCommentList = <CommentDataItem>[];
  var _myUserId = '';
  var _myProfilePic = '';
  var _myDisplayName = '';
  var _isCommentsLoaded = false;
  var _commentModifiedCount = 0;
  static const _defaultQuickEmojis = [
    '❤️',
    '👏',
    '🔥',
    '🙌',
    '😢',
    '😍',
    '😮',
    '😂',
  ];

  // Instagram comment sheet reference colors & typography (logical sp).
  static const _igSecondaryText = Color(0xFF8E8E8E);
  /// Instagram @mention / #hashtag link color in comment body.
  static const _igLinkColor = Color(0xFF0095F6);
  static const _igComposerBorder = Color(0xFFDBDBDB);
  static const _igReplyBanner = Color(0xFFEFEFEF);
  static const double _igUsernameFontSize = 13;
  static const double _igTimestampFontSize = 13;
  static const double _igCommentBodyFontSize = 16;
  static const double _igMetaActionFontSize = 12;
  static const double _igThreadActionFontSize = 13;

  /// Tight stacked text like Instagram (no extra ascent/descent gap).
  static const _igTextHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  /// Vertical gaps inside a comment row (Instagram-like, not congested).
  static const double _igGapUsernameToComment = 3;
  static const double _igGapCommentToReply = 5;

  String? get _commentSheetFontFamily =>
      _commentItemConfig?.usernameStyle?.fontFamily ??
      _commentItemConfig?.commentTextStyle?.fontFamily ??
      AppConstants.primaryFontFamily;

  TextStyle _mergeCommentTextStyle(
    TextStyle defaults,
    TextStyle? override,
  ) =>
      defaults.merge(override);

  TextStyle _resolveUsernameStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igUsernameFontSize,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: IsrColors.primaryTextColor,
        ),
        _commentItemConfig?.usernameStyle,
      );

  TextStyle _resolveTimestampStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igTimestampFontSize,
          fontWeight: FontWeight.w400,
          height: 1.1,
          color: _igSecondaryText,
        ),
        _commentItemConfig?.timestampStyle,
      );

  TextStyle _resolveCommentBodyStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igCommentBodyFontSize,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: IsrColors.primaryTextColor,
        ),
        _commentItemConfig?.commentTextStyle,
      );

  TextStyle _resolveReplyStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igMetaActionFontSize,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: _igSecondaryText,
        ),
        _commentItemConfig?.replyButtonStyle,
      );

  TextStyle _resolveLikeCountStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igMetaActionFontSize,
          fontWeight: FontWeight.w400,
          height: 1.1,
          color: _igSecondaryText,
        ),
        _commentItemConfig?.likeCountStyle,
      );

  TextStyle _resolveThreadActionStyle() => _mergeCommentTextStyle(
        TextStyle(
          fontFamily: _commentSheetFontFamily,
          fontSize: _igThreadActionFontSize,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: _igSecondaryText,
        ),
        _commentItemConfig?.viewRepliesStyle,
      );

  TextStyle _resolveHideRepliesStyle() => _mergeCommentTextStyle(
        _resolveThreadActionStyle(),
        _commentItemConfig?.hideRepliesStyle,
      );

  TextStyle _resolveMentionTagStyle(TextStyle commentStyle) =>
      commentStyle
          .copyWith(
            color: _igLinkColor,
            fontWeight: FontWeight.w400,
          )
          .merge(_commentItemConfig?.userTagTextStyle);

  TextStyle _resolveHashtagTagStyle(TextStyle commentStyle) =>
      commentStyle
          .copyWith(
            color: _igLinkColor,
            fontWeight: FontWeight.w400,
          )
          .merge(_commentItemConfig?.hashtagTextStyle);
  CommentDataItem? _replyComment;
  final _replyController = FlutterTaggerController();
  final _replyFocusNode = FocusNode();
  var _hasMoreComments = true;
  var _isLoadingMore = false;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentItemKeys = {};
  final Set<String> _expandedCommentKeys = {};
  var _highlightResolved = false;
  var _highlightReplySearchIndex = 0;
  String? _pendingReplyParentId;
  String? _pendingHighlightTargetId;
  static const int _commentMaxLength = 100;
  CommentConfig get _commentConfig =>
      widget.commentConfig ?? IsrVideoReelConfig.commentConfig;

  String _commentUniqueKey(CommentDataItem comment) =>
      '${comment.parentCommentId ?? ''}_${comment.commentedOn?.millisecondsSinceEpoch ?? 0}_${comment.postId ?? ''}_${comment.comment ?? ''}';

  List<CommentDataItem> _dedupeComments(Iterable<CommentDataItem> comments) {
    final seen = <String>{};
    final unique = <CommentDataItem>[];
    for (final comment in comments) {
      if (seen.add(_commentUniqueKey(comment))) {
        if (comment.childComments?.isNotEmpty == true) {
          comment.childComments = _dedupeComments(comment.childComments!);
        }
        unique.add(comment);
      }
    }
    return unique;
  }

  void _dedupeCommentListInPlace(List<CommentDataItem> comments) {
    final unique = _dedupeComments(comments);
    comments
      ..clear()
      ..addAll(unique);
  }

  // Config helper getters
  CommentUIConfig? get _uiConfig => _commentConfig.commentUIConfig;
  BottomSheetConfig? get _bottomSheetConfig => _uiConfig?.bottomSheetConfig;
  CommentHeaderConfig? get _headerConfig => _uiConfig?.headerConfig;
  CommentItemConfig? get _commentItemConfig => _uiConfig?.commentItemConfig;
  ReplyFieldConfig? get _replyFieldConfig => _uiConfig?.replyFieldConfig;
  CommentPlaceholderConfig? get _placeholderConfig =>
      _uiConfig?.placeholderConfig;
  MoreOptionsConfig? get _moreOptionsConfig => _uiConfig?.moreOptionsConfig;

  @override
  void initState() {
    super.initState();
    _onStartInit();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final localData = IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();
      final pic = await localData.getProfilePic();
      final name = await localData.getUserName();
      if (!mounted) return;
      setState(() {
        _myProfilePic = pic.trim();
        _myDisplayName = name.trim();
      });
    } catch (_) {}
  }

  void _onStartInit() {
    _socialBloc
        .add(GetPostCommentsEvent(isLoading: true, postId: widget.postId));
    _scrollController.addListener(_onScroll);
  }

  void _dismissCommentKeyboard() {
    if (_replyFocusNode.hasFocus) {
      _replyFocusNode.unfocus();
    }
  }

  bool _onUserScrollNotification(ScrollNotification notification) {
    if (!_replyFocusNode.hasFocus) return false;

    final shouldDismiss = notification is ScrollUpdateNotification ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle);
    if (shouldDismiss) {
      _dismissCommentKeyboard();
    }
    return false;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreComments) {
      return;
    }

    final scrollPosition = _scrollController.position;
    final threshold = scrollPosition.maxScrollExtent * 0.6;

    if (scrollPosition.pixels >= threshold) {
      _isLoadingMore = true;
      _socialBloc.add(
        GetPostCommentsEvent(
          isLoading: false,
          postId: widget.postId,
          isPagination: true,
          onComplete: (comments) {
            if (mounted) {
              setState(() {
                if (comments.isNotEmpty) {
                  _postCommentList.addAll(comments);
                  _dedupeCommentListInPlace(_postCommentList);
                  _hasMoreComments = true;
                } else {
                  _hasMoreComments = false;
                }
                _isLoadingMore = false;
              });
            }
          },
        ),
      );
    }
  }

  void _scrollToComment(CommentDataItem comment) {
    final key = _commentItemKeys[_commentUniqueKey(comment)];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retryKey = _commentItemKeys[_commentUniqueKey(comment)];
      if (retryKey?.currentContext != null && mounted) {
        Scrollable.ensureVisible(
          retryKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  String _normalizeCommentId(String id) {
    const prefix = 'comment_';
    final trimmed = id.trim();
    if (trimmed.startsWith(prefix)) {
      return trimmed.substring(prefix.length);
    }
    return trimmed;
  }

  bool _commentIdsMatch(String? left, String? right) {
    if (left == null || right == null) return false;
    final a = left.trim();
    final b = right.trim();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    return _normalizeCommentId(a) == _normalizeCommentId(b);
  }

  bool _commentIdEquals(String? commentId, String targetId) =>
      _commentIdsMatch(commentId, targetId);

  bool get _shouldResolveHighlight =>
      !_highlightResolved &&
      widget.highlightCommentId?.trim().isNotEmpty == true;

  CommentDataItem? _findCommentInLoadedList(String commentId) {
    for (final comment in _postCommentList) {
      if (_commentIdEquals(comment.id, commentId)) {
        return comment;
      }
      final child = comment.childComments
          ?.where((reply) => _commentIdEquals(reply.id, commentId))
          .firstOrNull;
      if (child != null) {
        return child;
      }
    }
    return null;
  }

  CommentDataItem? _findParentOfComment(String commentId) {
    for (final comment in _postCommentList) {
      if (comment.childComments
              ?.any((reply) => _commentIdEquals(reply.id, commentId)) ==
          true) {
        return comment;
      }
    }
    return null;
  }

  void _finishHighlightResolution() {
    _highlightResolved = true;
    _pendingReplyParentId = null;
    _pendingHighlightTargetId = null;
  }

  void _scrollToResolvedComment(CommentDataItem target) {
    _finishHighlightResolution();

    final parent = _findParentOfComment(target.id ?? '');
    if (parent != null) {
      setState(() {
        parent.showReply = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToComment(target);
      }
    });
  }

  void _loadMoreCommentsForHighlight(String targetId) {
    if (_isLoadingMore || !_hasMoreComments) {
      _searchRepliesForHighlight(targetId);
      return;
    }

    _isLoadingMore = true;
    _socialBloc.add(
      GetPostCommentsEvent(
        isLoading: false,
        postId: widget.postId,
        isPagination: true,
        onComplete: (comments) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (comments.isNotEmpty) {
              _postCommentList.addAll(comments);
              _hasMoreComments = true;
            } else {
              _hasMoreComments = false;
            }
            _isLoadingMore = false;
          });
          _resolveHighlightComment(targetId);
        },
      ),
    );
  }

  void _loadRepliesForHighlight(CommentDataItem parent, String targetId) {
    _pendingReplyParentId = parent.id;
    _pendingHighlightTargetId = targetId;
    parent.showReply = true;
    _socialBloc.add(
      GetPostCommentReplyEvent(
        isLoading: true,
        parentComment: parent,
        postId: widget.postId,
      ),
    );
  }

  void _searchRepliesForHighlight(String targetId) {
    while (_highlightReplySearchIndex < _postCommentList.length) {
      final parent = _postCommentList[_highlightReplySearchIndex++];

      final loadedChild = parent.childComments
          ?.where((reply) => _commentIdEquals(reply.id, targetId))
          .firstOrNull;
      if (loadedChild != null) {
        _scrollToResolvedComment(loadedChild);
        return;
      }

      if ((parent.childCommentCount ?? 0) <= 0) {
        continue;
      }

      if (parent.childComments.isEmptyOrNull) {
        _loadRepliesForHighlight(parent, targetId);
        return;
      }
    }

    _finishHighlightResolution();
  }

  void _resolveHighlightComment([String? targetIdOverride]) {
    if (!_shouldResolveHighlight || !mounted) {
      return;
    }

    final targetId = (targetIdOverride ?? widget.highlightCommentId)?.trim();
    if (targetId == null || targetId.isEmpty) {
      return;
    }

    final target = _findCommentInLoadedList(targetId);
    if (target != null) {
      _scrollToResolvedComment(target);
      return;
    }

    if (_hasMoreComments && !_isLoadingMore) {
      _loadMoreCommentsForHighlight(targetId);
      return;
    }

    _searchRepliesForHighlight(targetId);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _replyFocusNode.dispose();
    _replyController.dispose();
    _commentItemKeys.clear();
    _commentModifiedCount = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            Navigator.pop(context, _commentModifiedCount);
          }
        },
        child: BlocConsumer<SocialPostBloc, SocialPostState>(
          listenWhen: (previousState, currentState) =>
              (currentState is LoadPostCommentState &&
                  currentState.postId == widget.postId) ||
              (currentState is LoadingPostComment &&
                  currentState.postId == widget.postId) ||
              (currentState is CommentCountModified &&
                  currentState.postId == widget.postId) ||
              (currentState is LoadPostCommentRepliesState &&
                  currentState.parentCommentId == _pendingReplyParentId),
          listener: (context, state) {
            if (state is LoadPostCommentState &&
                state.postId == widget.postId) {
              if (!_isCommentsLoaded) {
                _isCommentsLoaded = true;
                _myUserId = state.myUserId ?? '';
              }

              if (state.postCommentsList != null && mounted) {
                setState(() {
                  _postCommentList
                    ..clear()
                    ..addAll(_dedupeComments(
                        state.postCommentsList as Iterable<CommentDataItem>));
                });
                _resolveHighlightComment();
              }
            } else if (state is CommentCountModified &&
                state.postId == widget.postId) {
              _commentModifiedCount =
                  _commentModifiedCount + state.modifiedValue;
            } else if (state is LoadPostCommentRepliesState &&
                state.parentCommentId == _pendingReplyParentId) {
              final targetId = _pendingHighlightTargetId;
              if (targetId == null) {
                return;
              }

              final parent = _postCommentList
                  .where((comment) => comment.id == state.parentCommentId)
                  .firstOrNull;
              parent?.childComments = state.postCommentRepliesList;

              final child = parent?.childComments
                  ?.where((reply) => _commentIdEquals(reply.id, targetId))
                  .firstOrNull;
              if (child != null) {
                _scrollToResolvedComment(child);
              } else {
                _pendingReplyParentId = null;
                _pendingHighlightTargetId = targetId;
                _resolveHighlightComment(targetId);
              }
            }
          },
          builder: (context, state) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: (_bottomSheetConfig?.maxHeight ?? 80.0).percentHeight,
            ),
            decoration: BoxDecoration(
              color: _bottomSheetConfig?.backgroundColor ?? IsrColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  (_bottomSheetConfig?.borderRadius ?? 28.0)
                      .responsiveDimension,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetHeader(context),
                // Comments List
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onUserScrollNotification,
                    child: Stack(children: [
                    if (_postCommentList.isNotEmpty == true)
                      ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: _bottomSheetConfig?.padding ??
                            IsrDimens.edgeInsets(
                              left: IsrDimens.sixteen,
                              right: IsrDimens.sixteen,
                              top: IsrDimens.eight,
                              bottom: IsrDimens.eight,
                            ),
                        itemCount: _postCommentList.length,
                        cacheExtent: 500,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        separatorBuilder: (_, __) =>
                            (_commentItemConfig?.commentSpacing ?? 12.0)
                                .responsiveVerticalSpace,
                        itemBuilder: (context, index) =>
                            _buildCommentItem(_postCommentList[index]),
                      )
                    else if (!(state is LoadingPostComment &&
                        state.postId == widget.postId))
                      _buildPlaceHolder(),
                  ]),
                  ),
                ),
                if (_isCommentsLoaded) _buildReplyField(_replyComment),
                const SafeArea(child: SizedBox(), top: false),
              ],
            ),
          ),
        ),
      );

  GlobalKey? _getOrCreateCommentKey(CommentDataItem comment) {
    final uniqueKey = _commentUniqueKey(comment);
    return _commentItemKeys.putIfAbsent(uniqueKey, GlobalKey.new);
  }

  Widget _buildCommentItem(CommentDataItem commentDataItem) {
    final comment = commentDataItem;

    return RepaintBoundary(
      child: StatefulBuilder(
        builder: (context, setState) => Container(
          key: _getOrCreateCommentKey(comment),
          child: Column(
            children: [
              _buildInstagramCommentRow(
                comment,
                setState,
                showViewReplies: true,
              ),
              // Child comments section
              if (comment.showReply &&
                  comment.id != null &&
                  comment.id!.isNotEmpty) ...[
                BlocConsumer<SocialPostBloc, SocialPostState>(
                  listenWhen: (previousState, currentState) =>
                      (currentState is LoadPostCommentRepliesState &&
                          currentState.parentCommentId == comment.id) ||
                      (currentState is LoadingPostCommentReplies &&
                          currentState.parentCommentId == comment.id),
                  buildWhen: (previousState, currentState) =>
                      (currentState is LoadPostCommentRepliesState &&
                          currentState.parentCommentId == comment.id) ||
                      (currentState is LoadingPostCommentReplies &&
                          currentState.parentCommentId == comment.id),
                  listener: (context, state) {
                    switch (state) {
                      case LoadPostCommentRepliesState():
                        comment.childComments = _dedupeComments(
                          state.postCommentRepliesList ??
                              const <CommentDataItem>[],
                        );
                        if (state.postCommentRepliesList?.isNotEmpty != true) {
                          setState(() {
                            comment.showReply = false;
                          });
                        }
                        break;
                    }
                  },
                  builder: (context, state) => (state
                              is LoadingPostCommentReplies &&
                          state.parentCommentId == comment.id)
                      ? Utility.loaderWidget()
                      : (comment.childComments?.isNotEmpty == true)
                          ? Column(
                              children: [
                                ...List.generate(
                                  comment.childComments?.length ?? 0,
                                  (index) => Padding(
                                    padding: _commentItemConfig
                                            ?.childCommentPadding ??
                                        IsrDimens.edgeInsets(
                                            left: (_commentItemConfig
                                                        ?.childCommentIndent ??
                                                    32.0)
                                                .responsiveDimension,
                                            top: 10.responsiveDimension),
                                    child: _buildChildCommentItem(
                                        comment.childComments![index], false),
                                  ),
                                ),
                                TapHandler(
                                  onTap: () {
                                    setState(() {
                                      comment.showReply = false;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: _commentItemConfig
                                            ?.childCommentPadding ??
                                        IsrDimens.edgeInsets(
                                            left: (_commentItemConfig
                                                        ?.childCommentIndent ??
                                                    32.0)
                                                .responsiveDimension,
                                            top: 10.responsiveDimension),
                                    child: Text(
                                      IsrTranslationFile.hideReplies,
                                      style: _resolveHideRepliesStyle(),
                                    ),
                                  ),
                                )
                              ],
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCommentItem(CommentDataItem comment, bool isReply) =>
      RepaintBoundary(
        child: StatefulBuilder(
          builder: (context, setState) => _buildInstagramCommentRow(
            comment,
            setState,
            showReplyAction: isReply,
          ),
        ),
      );

  Widget _buildMoreOptionUI(CommentDataItem comment) => Center(
        child: Stack(
          clipBehavior: Clip.none, // Allows button to overflow
          children: [
            // Dialog box
            Container(
              constraints: BoxConstraints(
                maxWidth:
                    (_moreOptionsConfig?.maxWidth ?? 300.0).responsiveDimension,
                maxHeight: (_moreOptionsConfig?.maxHeight ?? 200.0)
                    .responsiveDimension,
              ),
              padding: _moreOptionsConfig?.dialogPadding ??
                  IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
              margin: _moreOptionsConfig?.dialogMargin ??
                  IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
              decoration: _moreOptionsConfig?.dialogDecoration ??
                  BoxDecoration(
                    color: IsrColors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(IsrDimens.twenty),
                    ),
                  ),
              child: Column(
                spacing: 10.responsiveDimension,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_myUserId == comment.commentedByUserId) ...[
                    TapHandler(
                      onTap: () {
                        context.pop();
                        _socialBloc.add(
                          CommentActionEvent(
                            userId: comment.commentedByUserId,
                            commentId: comment.id,
                            parentCommentId: comment.parentCommentId,
                            postId: widget.postId,
                            commentAction: CommentAction.delete,
                            postCommentList: _postCommentList.toList(),
                            onComplete: (commentId, isSuccess) {},
                            postDataModel: widget.postData,
                            tabDataModel: widget.tabData,
                          ),
                        );
                      },
                      child: Text(
                        IsrTranslationFile.delete,
                        style: _moreOptionsConfig?.deleteTextStyle ??
                            _moreOptionsConfig?.optionTextStyle ??
                            IsrStyles.primaryText18.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(height: 1),
                  ] else ...[
                    TapHandler(
                      onTap: () async {
                        context.pop();
                        var isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
                        if (!isUserLoggedIn) {
                          await IsrVideoReelConfig.socialConfig.socialCallBackConfig?.onLoginInvoked
                              ?.call();
                        }
                        isUserLoggedIn = await _socialActionCubit.isUserLoggedIn;
                        if (!isUserLoggedIn) return;
                        await showDialog<dynamic>(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => ReportReasonDialog(
                            reasonFor: ReasonsFor.comment,
                            contentId: comment.id ?? '',
                          ),
                        );
                      },
                      child: Text(
                        IsrTranslationFile.report,
                        style: _moreOptionsConfig?.reportTextStyle ??
                            _moreOptionsConfig?.optionTextStyle ??
                            IsrStyles.primaryText18.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  TapHandler(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      IsrTranslationFile.cancel,
                      style: _moreOptionsConfig?.cancelTextStyle ??
                          _moreOptionsConfig?.optionTextStyle ??
                          IsrStyles.primaryText18.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // // Close button above the dialog
            // Positioned(
            //   right: 20,
            //   top: -20, // Adjust as needed
            //   child: GestureDetector(
            //     onTap: () => Navigator.pop(context),
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         shape: BoxShape.circle,
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.white.changeOpacity(0.2),
            //             spreadRadius: 1,
            //             blurRadius: 2,
            //             offset: const Offset(0, 2),
            //           ),
            //         ],
            //       ),
            //       padding: const EdgeInsets.all(6),
            //       child: const Icon(Icons.close, size: 16, color: Colors.black),
            //     ),
            //   ),
            // ),
          ],
        ),
      );

  Widget _buildDialogWrapper({required Widget child}) {
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? IsrDimens.twenty;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    final headerPadding = _headerConfig?.headerPadding ??
        const EdgeInsets.only(top: 8, bottom: 8);
    final titleStyle = IsrStyles.primaryText16
        .copyWith(fontWeight: FontWeight.w700)
        .merge(_headerConfig?.titleStyle);
    final title =
        _headerConfig?.title ?? IsrTranslationFile.allComments;

    return GestureDetector(
      onTap: _dismissCommentKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: headerPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_headerConfig?.showDragHandle ?? true) ...[
            Container(
              width: (_headerConfig?.dragHandleWidth ?? 40).responsiveDimension,
              height:
                  (_headerConfig?.dragHandleHeight ?? 4).responsiveDimension,
              decoration: BoxDecoration(
                color: _headerConfig?.dragHandleColor ??
                    IsrColors.black.changeOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            12.responsiveVerticalSpace,
          ],
          if (_headerConfig?.showCloseButton == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: titleStyle),
                TapHandler(
                  onTap: () => context.pop(_commentModifiedCount),
                  child: AppImage.svg(
                    _headerConfig?.closeIcon ?? AssetConstants.icClose,
                    width: _headerConfig?.closeIconSize,
                    height: _headerConfig?.closeIconSize,
                    color: _headerConfig?.closeIconColor,
                  ),
                ),
              ],
            )
          else
            Center(child: Text(title, style: titleStyle)),
        ],
      ),
      ),
    );
  }

  String _commentDisplayName(CommentDataItem comment) =>
      comment.fullName?.isNotEmpty == true
          ? comment.fullName!
          : comment.commentedBy ?? '';

  String _commentTimeAgo(CommentDataItem comment) {
    if (comment.id.isStringEmptyOrNull) return '';
    return Utility.getTimeAgoFromDateTime(
      comment.commentedOn,
      showJustNow: true,
    );
  }

  String _commentExpansionKey(CommentDataItem comment) =>
      '${comment.id}_${comment.comment}_${comment.commentedOn?.millisecondsSinceEpoch}';

  String _initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final words =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length == 1) {
      final word = words.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return words
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
  }

  Widget _buildInitialsAvatar(String initials, double size) {
    final background = IsrColors.black.changeOpacity(0.08);
    final foreground = IsrColors.black.changeOpacity(0.62);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1,
        ),
        maxLines: 1,
      ),
    );
  }

  Widget _buildCommentAvatar(
    String? imageUrl,
    String displayName, {
    double? size,
  }) {
    final avatarSize =
        (size ?? _commentItemConfig?.avatarSize ?? 36).responsiveDimension;
    final initials = _initialsFromName(displayName);
    final url = (imageUrl ?? '').trim();

    Widget initialsWidget() => _buildInitialsAvatar(initials, avatarSize);

    if (url.isEmpty) {
      return initialsWidget();
    }

    return ClipOval(
      child: SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: AppImage.network(
          url,
          width: avatarSize,
          height: avatarSize,
          name: displayName,
          isProfileImage: true,
          fit: BoxFit.cover,
          placeHolderWidget: (_, __) => initialsWidget(),
        ),
      ),
    );
  }

  InputDecoration _composerInputDecoration(String hintText) {
    if (_replyFieldConfig?.inputDecoration != null) {
      return _replyFieldConfig!.inputDecoration!;
    }
    return InputDecoration(
      hintText: hintText,
      hintStyle: _replyFieldConfig?.hintTextStyle ??
          IsrStyles.primaryText14.copyWith(
            fontWeight: FontWeight.w400,
            color: _igSecondaryText,
          ),
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        vertical: 10.responsiveDimension,
        horizontal: 0,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      alignLabelWithHint: true,
    );
  }

  Widget _buildCommentLikeColumn(
    CommentDataItem comment,
    StateSetter setState,
  ) {
    final likeCount = comment.likeCount ?? 0;
    final likeCountStyle = _resolveLikeCountStyle();

    return Column(
      children: [
        LikeCommentIconView(
          postId: comment.postId ?? '',
          commentId: comment.id ?? '',
          userId: comment.commentedByUserId ?? '',
          isLiked: comment.isLiked == true,
          onLikeDisLikeComment: (isLiked) {
            setState(() {
              comment.likeCount = isLiked
                  ? (comment.likeCount ?? 0) + 1
                  : comment.likeCount == 0
                      ? 0
                      : (comment.likeCount ?? 0) - 1;
              comment.isLiked = isLiked;
            });
            if (isLiked) {
              _logLikeCommentEvent(
                EventType.commentLiked.value,
                comment.id ?? '',
                comment.postId ?? '',
              );
            }
          },
        ),
        if (likeCount > 0) ...[
          2.responsiveVerticalSpace,
          Text(
            Utility.formatEngagementCount(likeCount.toInt()),
            style: likeCountStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildCommentMessageText({
    required String displayName,
    required String timeAgo,
    required CommentDataItem comment,
    required TextStyle usernameStyle,
    required TextStyle timestampStyle,
    required TextStyle commentStyle,
    required StateSetter setState,
  }) {
    final commentText = comment.comment ?? '';
    final hasUsernameLine = displayName.isNotEmpty || timeAgo.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasUsernameLine)
          Text.rich(
            TextSpan(
              children: [
                if (displayName.isNotEmpty)
                  TextSpan(
                    text: displayName,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        widget.onTapProfile?.call(
                          comment.commentedByUserId ?? '',
                        );
                      },
                    style: usernameStyle,
                  ),
                if (timeAgo.isNotEmpty)
                  TextSpan(
                    text: displayName.isNotEmpty ? ' $timeAgo' : timeAgo,
                    style: timestampStyle,
                  ),
              ],
            ),
            textHeightBehavior: _igTextHeightBehavior,
          ),
        if (commentText.isNotEmpty) ...[
          if (hasUsernameLine)
            SizedBox(height: _igGapUsernameToComment.responsiveDimension),
          RichText(
            textHeightBehavior: _igTextHeightBehavior,
            text: TextSpan(
              children: Utility.buildCommentTextSpans(
                commentText,
                commentStyle,
                comment.tags,
                userNameStyle: _resolveMentionTagStyle(commentStyle),
                hashTagStyle: _resolveHashtagTagStyle(commentStyle),
                maxLength: _commentMaxLength,
                isExpanded: _expandedCommentKeys
                    .contains(_commentExpansionKey(comment)),
                onUsernameTap: (userId) {
                  widget.onTapProfile?.call(userId);
                },
                onHashtagTap: (hashtag) {
                  widget.onTapHasTag?.call(hashtag);
                },
                onViewMoreTap: () {
                  setState(() {
                    _expandedCommentKeys.add(_commentExpansionKey(comment));
                  });
                },
                onViewLessTap: () {
                  setState(() {
                    _expandedCommentKeys.remove(
                      _commentExpansionKey(comment),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstagramCommentRow(
    CommentDataItem comment,
    StateSetter setState, {
    bool showViewReplies = false,
    bool showReplyAction = true,
  }) {
    final displayName = _commentDisplayName(comment);
    final timeAgo = _commentTimeAgo(comment);
    final hasCommentId =
        comment.id != null && comment.id!.isNotEmpty;
    final usernameStyle = _resolveUsernameStyle();
    final timestampStyle = _resolveTimestampStyle();
    final commentStyle = _resolveCommentBodyStyle();
    final replyStyle = _resolveReplyStyle();
    final threadActionStyle = _resolveThreadActionStyle();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentAvatar(comment.profilePic, displayName),
        10.responsiveHorizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentMessageText(
                displayName: displayName,
                timeAgo: timeAgo,
                comment: comment,
                usernameStyle: usernameStyle,
                timestampStyle: timestampStyle,
                commentStyle: commentStyle,
                setState: setState,
              ),
              if (comment.id.isStringEmptyOrNull &&
                  !comment.status.isStringEmptyOrNull) ...[
                2.responsiveVerticalSpace,
                Text(
                  comment.status ?? '',
                  style: IsrStyles.primaryText12.copyWith(
                    color: '828282'.toColor(),
                  ),
                ),
              ],
              if (hasCommentId &&
                  (showReplyAction || showViewReplies)) ...[
                SizedBox(
                  height: _igGapCommentToReply.responsiveDimension,
                ),
                Row(
                  spacing: 12.responsiveDimension,
                  children: [
                    if (showReplyAction)
                      TapHandler(
                        onTap: () {
                          _setReplyComment(comment);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToComment(comment);
                          });
                        },
                        child: Text(
                          IsrTranslationFile.reply,
                          style: replyStyle,
                        ),
                      ),
                    if (showViewReplies &&
                        !comment.showReply &&
                        (comment.childCommentCount ?? 0) > 0)
                      TapHandler(
                        onTap: () {
                          setState(() {
                            comment.showReply = true;
                          });
                          if (comment.childComments.isEmptyOrNull) {
                            _socialBloc.add(
                              GetPostCommentReplyEvent(
                                isLoading: true,
                                parentComment: comment,
                                postId: widget.postId,
                              ),
                            );
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToComment(comment);
                          });
                        },
                        child: Text(
                          IsrTranslationFile.viewReplies,
                          style: threadActionStyle,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (hasCommentId) ...[
          8.responsiveHorizontalSpace,
          _buildCommentLikeColumn(comment, setState),
          if (_commentItemConfig?.showMoreMenu ?? true) ...[
            4.responsiveHorizontalSpace,
            TapHandler(
              padding: 4.responsiveDimension,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => _buildDialogWrapper(
                    child: _buildMoreOptionUI(comment),
                  ),
                );
              },
              child: AppImage.svg(
                _commentItemConfig?.moreIcon ??
                    AssetConstants.icVerticalMoreMenu,
                width: _commentItemConfig?.moreIconSize ?? 16,
                height: _commentItemConfig?.moreIconSize ?? 16,
                color: _commentItemConfig?.moreIconColor,
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _appendEmoji(String emoji) {
    final text = _replyController.text;
    final selection = _replyController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _replyController.text = newText;
    final offset = start + emoji.length;
    _replyController.selection = TextSelection.collapsed(offset: offset);
  }

  Future<void> _submitComment(
    String commentText,
    CommentDataItem? commentDataItem,
  ) async {
    if (commentText.isStringEmptyOrNull) return;

    final postId = commentDataItem?.postId ?? widget.postId;
    final parentCommentId = commentDataItem?.id ?? '';

    _replyFocusNode.unfocus();
    _replyController.clear();
    final currentTagMentions = List<CommentMentionData>.from(tagMentions);
    final currentUserMentions = List<CommentMentionData>.from(userMentions);
    tagMentions.clear();
    userMentions.clear();
    _setReplyComment(null);

    _socialBloc.add(
      CommentActionEvent(
        userId: commentDataItem?.commentedByUserId,
        isLoading: false,
        parentCommentId: parentCommentId,
        postId: postId,
        replyText: commentText,
        commentAction: CommentAction.comment,
        postedBy: _myUserId,
        postCommentList: _postCommentList,
        commentTags: {
          'hashtags': currentTagMentions.map((e) => e.toJson()).toList(),
          'mentions': currentUserMentions.map((e) => e.toJson()).toList(),
        },
        postDataModel: widget.postData,
        tabDataModel: widget.tabData,
      ),
    );
  }

  Widget _buildEmojiQuickBar() {
    if (!(_replyFieldConfig?.showEmojiBar ?? true)) {
      return const SizedBox.shrink();
    }

    final emojis =
        _replyFieldConfig?.quickReactionEmojis ?? _defaultQuickEmojis;

    // Instagram distributes quick reactions edge-to-edge, not left-clustered.
    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: 16.responsiveDimension,
        vertical: 4.responsiveDimension,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: emojis
            .map(
              (emoji) => TapHandler(
                onTap: () => _appendEmoji(emoji),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 28.responsiveDimension),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _setReplyComment(CommentDataItem? comment) {
    setState(() {
      _replyComment = comment;
    });

    // Focus on the text field and open keyboard when replying
    if (comment != null) {
      _replyFocusNode.requestFocus();
    }
  }

  final userMentions = <CommentMentionData>[];
  final tagMentions = <CommentMentionData>[];

  bool _isReplyingTo(CommentDataItem? commentDataItem) =>
      commentDataItem?.commentedBy.isStringEmptyOrNull == false;

  String _replyTargetUsername(CommentDataItem? commentDataItem) {
    if (commentDataItem == null) return '';
    final username = commentDataItem.commentedBy?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return _commentDisplayName(commentDataItem);
  }

  Widget _buildReplyingToBanner(CommentDataItem commentDataItem) {
    final bannerColor =
        _replyFieldConfig?.replyingToBackgroundColor ?? _igReplyBanner;
    final labelStyle = _replyFieldConfig?.replyingToTextStyle ??
        IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w400,
          color: _igSecondaryText,
        );
    final nameStyle = _replyFieldConfig?.replyingToNameStyle ??
        IsrStyles.primaryText12.copyWith(
          fontWeight: FontWeight.w600,
          color: _igSecondaryText,
        );
    final closeColor =
        _replyFieldConfig?.closeReplyIconColor ?? _igSecondaryText;

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: 12.responsiveDimension,
        vertical: 8.responsiveDimension,
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${IsrTranslationFile.replyingTo} ',
                    style: labelStyle,
                  ),
                  TextSpan(
                    text: _replyTargetUsername(commentDataItem),
                    style: nameStyle,
                  ),
                ],
              ),
            ),
          ),
          TapHandler(
            onTap: () => _setReplyComment(null),
            child: Icon(
              Icons.close_rounded,
              size: (_replyFieldConfig?.closeReplyIconSize ?? 18)
                  .responsiveDimension,
              color: closeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyField(CommentDataItem? commentDataItem) {
    final isReplying = _isReplyingTo(commentDataItem);
    final hintText = isReplying
        ? (_replyFieldConfig?.replyHintText ?? IsrTranslationFile.addAReply)
        : (_replyFieldConfig?.hintText ?? IsrTranslationFile.addAComment);
    final inputRadius =
        (_replyFieldConfig?.inputBorderRadius ?? 22).responsiveDimension;
    final inputBorderColor =
        _replyFieldConfig?.inputBorderColor ?? _igComposerBorder;
    final sendButtonColor = _replyFieldConfig?.sendButtonColor ??
        Theme.of(context).primaryColor;
    final sendIconColor =
        _replyFieldConfig?.sendButtonIconColor ?? IsrColors.white;
    final composerHeight = 44.0.responsiveDimension;
    final sendButtonSize = 30.0.responsiveDimension;

    return StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmojiQuickBar(),
          Padding(
            padding: _replyFieldConfig?.replyFieldPadding ??
                IsrDimens.edgeInsetsSymmetric(
                  horizontal: 12.responsiveDimension,
                  vertical: 8.responsiveDimension,
                ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildCommentAvatar(
                  _myProfilePic,
                  _myDisplayName,
                  size: 44,
                ),
                10.responsiveHorizontalSpace,
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _replyController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      final inputRow = ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: composerHeight,
                        ),
                        child: Padding(
                          padding: IsrDimens.edgeInsetsSymmetric(
                            horizontal: 14.responsiveDimension,
                            vertical: 2.responsiveDimension,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CommentTaggingTextField(
                                        controller: _replyController,
                                        focusNode: _replyFocusNode,
                                        wrapFieldInScrollView: false,
                                        maxOuterHeight: null,
                                        textFieldPadding: EdgeInsets.zero,
                                        inlineSuggestionsAbove: _replyFieldConfig
                                                ?.showoverlaySuggestions ??
                                            false,
                                        inlineSuggestionMaxHeightFactor: 0.2,
                                        minLines: 1,
                                        maxLines: 4,
                                        autoFocus: false,
                                        hintText: hintText,
                                        textStyle: _replyFieldConfig
                                                ?.inputTextStyle ??
                                            IsrStyles.primaryText14.copyWith(
                                              fontWeight: FontWeight.w400,
                                            ),
                                        userTagTextStyle: _replyFieldConfig
                                                ?.inputUserTagTextStyle ??
                                            IsrStyles.primaryText14.copyWith(
                                              color: _igLinkColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                        hashtagTextStyle: _replyFieldConfig
                                                ?.inputHashtagTextStyle ??
                                            IsrStyles.primaryText14.copyWith(
                                              color: _igLinkColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                        decoration:
                                            _composerInputDecoration(hintText),
                                        onRemoveHashTagData: (mentionData) {
                                          tagMentions.removeWhere(
                                            (_) => _.toJson() ==
                                                mentionData.toJson(),
                                          );
                                        },
                                        onRemoveMentionData: (mentionData) {
                                          userMentions.removeWhere(
                                            (_) => _.toJson() ==
                                                mentionData.toJson(),
                                          );
                                        },
                                        onAddHashTagData: (mentionData) {
                                          if (!tagMentions.any(
                                            (_) => _.toJson() ==
                                                mentionData.toJson(),
                                          )) {
                                            tagMentions.add(mentionData);
                                          }
                                        },
                                        onAddMentionData: (mentionData) {
                                          if (!userMentions.any(
                                            (_) => _.toJson() ==
                                                mentionData.toJson(),
                                          )) {
                                            userMentions.add(mentionData);
                                          }
                                        },
                                      ),
                                    ),
                                    if (hasText) ...[
                                      8.responsiveHorizontalSpace,
                                      TapHandler(
                                        onTap: () => _submitComment(
                                          value.text,
                                          commentDataItem,
                                        ),
                                        child: Container(
                                          width: sendButtonSize,
                                          height: sendButtonSize,
                                          decoration: BoxDecoration(
                                            color: sendButtonColor,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 16.responsiveDimension,
                                            color: sendIconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      );

                      return Material(
                        color: IsrColors.white,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(inputRadius),
                          side: BorderSide(
                            color: inputBorderColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isReplying && commentDataItem != null)
                              _buildReplyingToBanner(commentDataItem),
                            inputRow,
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceHolder() => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppImage.svg(
                    _placeholderConfig?.placeholderIcon ??
                        AssetConstants.icCommentsPlaceHolder,
                    width: _placeholderConfig?.placeholderIconSize,
                    height: _placeholderConfig?.placeholderIconSize,
                    color: _placeholderConfig?.placeholderIconColor,
                  ),
                  10.responsiveVerticalSpace,
                  Text(
                    IsrTranslationFile.noCommentsYet,
                    style: _placeholderConfig?.titleStyle ??
                        IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  10.responsiveVerticalSpace,
                  Text(
                    IsrTranslationFile.beTheFirstOneToPostAComment,
                    style: _placeholderConfig?.subtitleStyle ??
                        IsrStyles.primaryText12.copyWith(
                          color: '606060'.toColor(),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _logLikeCommentEvent(
      String eventName, String commentId, String postId) async {
    final eventMap = {
      'post_id': postId,
      'post_type': widget.postData?.type,
      'post_author_id': widget.postData?.userId,
      'feed_type': widget.tabData?.postSectionType.title,
      'interests': widget.postData?.interests ?? [],
      'hashtags': widget.postData?.tags?.hashtags?.map((e) => '#$e').toList(),
      'comment_id': commentId,
    };
    EventQueueProvider.instance
        .logEvent(eventName, eventMap.removeEmptyValues());
  }
}
