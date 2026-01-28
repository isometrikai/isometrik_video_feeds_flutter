import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/data/data.dart';
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
    Key? key,
  }) : super(key: key);

  final String postId;
  final Function(String)? onTapProfile;
  final Function(String)? onTapHasTag;
  final TimeLineData? postData;
  final TabDataModel? tabData;
  final CommentConfig? commentConfig;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  SocialPostBloc get _socialBloc => context.getOrCreateBloc();
  final _postCommentList = <CommentDataItem>[];
  var _myUserId = '';
  var _isCommentsLoaded = false;
  CommentDataItem? _replyComment;
  var _commentModifiedCount = 0;
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  var _hasMoreComments = true;
  var _isLoadingMore = false;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentItemKeys = {};
  CommentConfig get _commentConfig =>
      widget.commentConfig ?? IsrVideoReelConfig.commentConfig;

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
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _socialBloc
        .add(GetPostCommentsEvent(isLoading: true, postId: widget.postId));
    _scrollController.addListener(_onScroll);
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
    final key = _commentItemKeys[
        '${comment.id}_${comment.comment}_${comment.commentedOn?.millisecondsSinceEpoch}'];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.0, // Scroll to top
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _replyFocusNode.dispose();
    _replyController.dispose();
    _commentItemKeys.clear();
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
              currentState is LoadPostCommentState ||
              currentState is LoadingPostComment ||
              currentState is CommentCountModified,
          listener: (context, state) {
            if (state is LoadPostCommentState) {
              if (!_isCommentsLoaded) {
                _isCommentsLoaded = true;
                _myUserId = state.myUserId ?? '';
              }

              // Only update from server if list changed
              if (state.postCommentsList != null && mounted) {
                // Don't replace entire list, just update from server
                // Bloc already handles merging optimistic comments with server response
                setState(() {
                  _postCommentList
                    ..clear()
                    ..addAll(
                        state.postCommentsList as Iterable<CommentDataItem>);
                });
              }
            } else if (state is CommentCountModified && state.postId == widget.postId) {
              _commentModifiedCount = _commentModifiedCount + state.modifiedValue;
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
                  (_bottomSheetConfig?.borderRadius ?? 20.0)
                      .responsiveDimension,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: _headerConfig?.headerPadding ??
                      IsrDimens.edgeInsetsSymmetric(
                        horizontal: 16.responsiveDimension,
                        vertical: 20.responsiveDimension,
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        IsrTranslationFile.allComments,
                        style: _headerConfig?.titleStyle ??
                            IsrStyles.primaryText18.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TapHandler(
                        onTap: () {
                          context.pop(_commentModifiedCount);
                        },
                        child: AppImage.svg(
                          _headerConfig?.closeIcon ?? AssetConstants.icClose,
                          width: _headerConfig?.closeIconSize,
                          height: _headerConfig?.closeIconSize,
                          color: _headerConfig?.closeIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Comments List
                Expanded(
                  child: Stack(children: [
                    if (_postCommentList.isNotEmpty == true)
                      ListView.separated(
                        controller: _scrollController,
                        padding: _bottomSheetConfig?.padding ??
                            IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                        itemCount: _postCommentList.length,
                        cacheExtent: 500,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        separatorBuilder: (_, __) =>
                            (_commentItemConfig?.commentSpacing ?? 16.0)
                                .responsiveVerticalSpace,
                        itemBuilder: (context, index) =>
                            _buildCommentItem(_postCommentList[index]),
                      )
                    else if (!(state is LoadingPostComment))
                      _buildPlaceHolder(),
                  ]),
                ),
                if (_isCommentsLoaded) _buildReplyField(_replyComment),
                const SafeArea(child: SizedBox(), top: false),
              ],
            ),
          ),
        ),
      );

  GlobalKey? _getOrCreateCommentKey(CommentDataItem comment) {
    _commentItemKeys[
            '${comment.id}_${comment.comment}_${comment.commentedOn?.millisecondsSinceEpoch}'] =
        GlobalKey();
    return _commentItemKeys[
        '${comment.id}_${comment.comment}_${comment.commentedOn?.millisecondsSinceEpoch}'];
  }

  Widget _buildCommentItem(CommentDataItem commentDataItem) {
    final comment = commentDataItem;

    return RepaintBoundary(
      child: StatefulBuilder(
        builder: (context, setState) => Container(
          key: _getOrCreateCommentKey(comment),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: comment.fullName?.isNotEmpty == true
                                    ? comment.fullName!
                                    : comment.commentedBy ?? '',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (widget.onTapProfile != null) {
                                      widget.onTapProfile!(
                                          comment.commentedByUserId ?? '');
                                    }
                                  },
                                style: _commentItemConfig?.usernameStyle ??
                                    IsrStyles.primaryText14.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const TextSpan(text: ' '),
                              ...Utility.buildCommentTextSpans(
                                '${comment.comment ?? ''}',
                                _commentItemConfig?.commentTextStyle ??
                                    IsrStyles.primaryText14,
                                comment.tags,
                                onUsernameTap: (userId) {
                                  widget.onTapProfile?.call(userId);
                                },
                                onHashtagTap: (hashtag) {
                                  widget.onTapHasTag?.call(hashtag);
                                },
                              ),
                            ],
                          ),
                        ),
                        8.responsiveVerticalSpace,
                        Row(
                          spacing: 12.responsiveDimension,
                          children: [
                            if (comment.id.isStringEmptyOrNull &&
                                !comment.status.isStringEmptyOrNull)
                              Text(
                                comment.status ?? '',
                                style: IsrStyles.primaryText12.copyWith(
                                  color: '828282'.toColor(),
                                ),
                              ),
                            if (comment.id != null && comment.id!.isNotEmpty)
                              Text(
                                Utility.getTimeAgoFromDateTime(
                                    comment.commentedOn,
                                    showJustNow: true),
                                style: _commentItemConfig?.timestampStyle ??
                                  IsrStyles.primaryText12.copyWith(
                                    color: '828282'.toColor(),
                                  ),
                            ),
                            if (comment.id != null && comment.id!.isNotEmpty)
                              Text(
                                '${comment.likeCount} ${(comment.likeCount ?? 0) <= 1 ? IsrTranslationFile.like : IsrTranslationFile.likes}',
                                style: _commentItemConfig?.likeCountStyle ??
                                    IsrStyles.primaryText12.copyWith(
                                      color: '828282'.toColor(),
                                    ),
                              ),
                            if (comment.id != null && comment.id!.isNotEmpty)
                              TapHandler(
                                onTap: () {
                                  _setReplyComment(comment);
                                  // Scroll to comment after a brief delay to ensure UI is updated
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToComment(comment);
                                  });
                                },
                                child: Text(
                                  IsrTranslationFile.reply,
                                  style: _commentItemConfig?.replyButtonStyle ??
                                      IsrStyles.primaryText12.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            if (!comment.showReply &&
                                (comment.childCommentCount ?? 0) > 0)
                              TapHandler(
                                onTap: () {
                                  setState(() {
                                    comment.showReply = true;
                                  });
                                  if (comment.id != null &&
                                      comment.childComments.isEmptyOrNull) {
                                    _socialBloc.add(GetPostCommentReplyEvent(
                                        isLoading: true,
                                        parentComment: comment,
                                        postId: widget.postId));
                                  }
                                  // Scroll to comment after a brief delay to ensure UI is updated
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToComment(comment);
                                  });
                                },
                                child: Text(
                                  IsrTranslationFile.viewReplies,
                                  style: _commentItemConfig?.viewRepliesStyle ??
                                      IsrStyles.primaryText12.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: '94A0AF'.toColor()),
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                  4.responsiveHorizontalSpace,
                  if (comment.id != null && comment.id!.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                        8.responsiveHorizontalSpace,
                        TapHandler(
                          padding: 5.responsiveDimension,
                          onTap: () async => await showDialog(
                            context: context,
                            builder: (context) => _buildDialogWrapper(
                              child: _buildMoreOptionUI(comment),
                            ),
                          ),
                          child: AppImage.svg(
                            _commentItemConfig?.moreIcon ??
                                AssetConstants.icVerticalMoreMenu,
                            width: _commentItemConfig?.moreIconSize,
                            height: _commentItemConfig?.moreIconSize,
                            color: _commentItemConfig?.moreIconColor,
                          ),
                        ),
                      ],
                    ),
                ],
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
                          comment.childComments = state.postCommentRepliesList;
                          if (state.postCommentRepliesList?.isNotEmpty !=
                              true) {
                            setState(() {
                              comment.showReply = false;
                            });
                          }
                          break;
                      }
                    },
                    builder: (context, state) => switch (state) {
                          LoadingPostCommentReplies() => Utility.loaderWidget(),
                          _ => (comment.childComments?.isNotEmpty == true)
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
                                                top: 16.responsiveDimension),
                                        child: _buildChildCommentItem(
                                            comment.childComments![index],
                                            false),
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
                                                top: 16.responsiveDimension),
                                        child: Text(
                                          IsrTranslationFile.hideReplies,
                                          style: _commentItemConfig
                                                  ?.hideRepliesStyle ??
                                              IsrStyles.secondaryText12
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          '94A0AF'.toColor()),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              : const SizedBox.shrink(),
                        }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCommentItem(CommentDataItem comment, bool isReply) {
    var likeCount = comment.likeCount ?? 0;
    return RepaintBoundary(
      child: StatefulBuilder(
        builder: (context, setState) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: comment.fullName?.isNotEmpty == true
                              ? comment.fullName!
                              : comment.commentedBy ?? '',
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              if (widget.onTapProfile != null) {
                                widget.onTapProfile!(
                                    comment.commentedByUserId ?? '');
                              }
                            },
                          style: _commentItemConfig?.usernameStyle ??
                              IsrStyles.primaryText14.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const TextSpan(text: ' '),
                        ...Utility.buildCommentTextSpans(
                          '${comment.comment ?? ''}',
                          _commentItemConfig?.commentTextStyle ??
                              IsrStyles.primaryText14,
                          comment.tags,
                          onUsernameTap: (userId) {
                            widget.onTapProfile?.call(userId);
                          },
                          onHashtagTap: (hashtag) {
                            widget.onTapHasTag?.call(hashtag);
                          },
                        ),
                      ],
                    ),
                  ),
                  8.responsiveVerticalSpace,
                  Row(
                    spacing: 12.responsiveDimension,
                    children: [
                      if (comment.id.isStringEmptyOrNull &&
                          !comment.status.isStringEmptyOrNull)
                        Text(
                          comment.status ?? '',
                          style: IsrStyles.primaryText12.copyWith(
                            color: '828282'.toColor(),
                          ),
                        ),
                      if (comment.id != null && comment.id!.isNotEmpty)
                        Text(
                          Utility.getTimeAgoFromDateTime(comment.commentedOn, showJustNow: true),
                          style: _commentItemConfig?.timestampStyle ??
                            IsrStyles.primaryText12.copyWith(
                              color: '828282'.toColor(),
                            ),
                      ),
                      if (comment.id != null && comment.id!.isNotEmpty)
                        Text(
                          '$likeCount ${likeCount <= 1 ? IsrTranslationFile.like : IsrTranslationFile.likes}',
                          style: _commentItemConfig?.likeCountStyle ??
                              IsrStyles.primaryText12.copyWith(
                                color: '828282'.toColor(),
                              ),
                        ),
                      if (isReply) ...[
                        TapHandler(
                          onTap: () {
                            _setReplyComment(comment);
                          },
                          child: Text(
                            IsrTranslationFile.reply,
                            style: _commentItemConfig?.replyButtonStyle ??
                                IsrStyles.primaryText12.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            4.responsiveHorizontalSpace,
            if (comment.id != null && comment.id!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LikeCommentIconView(
                    postId: comment.postId ?? '',
                    commentId: comment.id ?? '',
                    userId: comment.commentedByUserId ?? '',
                    isLiked: comment.isLiked == true,
                    onLikeDisLikeComment: (isLiked) {
                      setState(() {
                        likeCount = isLiked
                            ? likeCount + 1
                            : likeCount == 0
                                ? 0
                                : likeCount - 1;
                        comment.likeCount = likeCount;
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
                  8.responsiveHorizontalSpace,
                  TapHandler(
                    padding: 5.responsiveDimension,
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
                      width: _commentItemConfig?.moreIconSize,
                      height: _commentItemConfig?.moreIconSize,
                      color: _commentItemConfig?.moreIconColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

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
                        await showDialog<dynamic>(
                          context: context,
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
      child: child,
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

  Widget _buildReplyField(CommentDataItem? commentDataItem) {
    final userMentions = <CommentMentionData>[];
    final tagMentions = <CommentMentionData>[];
    return StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (commentDataItem?.commentedBy.isStringEmptyOrNull == false)
            Container(
              padding: IsrDimens.edgeInsetsAll(16.responsiveDimension),
              color: _replyFieldConfig?.replyingToBackgroundColor ??
                  '001E57'.toColor(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${IsrTranslationFile.replyingTo} ',
                            style: _replyFieldConfig?.replyingToTextStyle ??
                                IsrStyles.white14,
                          ),
                          TextSpan(
                            text: commentDataItem?.commentedBy ?? '',
                            style: _replyFieldConfig?.replyingToNameStyle ??
                                IsrStyles.white14
                                    .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TapHandler(
                    onTap: () => _setReplyComment(null),
                    child: AppImage.svg(
                      _replyFieldConfig?.closeReplyIcon ??
                          AssetConstants.icClose,
                      width: _replyFieldConfig?.closeReplyIconSize,
                      height: _replyFieldConfig?.closeReplyIconSize,
                      color: _replyFieldConfig?.closeReplyIconColor ??
                          IsrColors.white,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: _replyFieldConfig?.replyFieldPadding ??
                IsrDimens.edgeInsetsSymmetric(
                    horizontal: 10.responsiveDimension),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CommentTaggingTextField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    minLines: 1,
                    autoFocus: true,
                    hintText: IsrTranslationFile.addAComment,
                    style: _replyFieldConfig?.inputTextStyle,
                    decoration: _replyFieldConfig?.inputDecoration ??
                        const InputDecoration(
                          hintText: IsrTranslationFile.addAComment,
                          border: InputBorder.none,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          alignLabelWithHint: true,
                        ),
                    onRemoveHashTagData: (mentionData) {
                      tagMentions.removeWhere(
                          (_) => _.toJson() == mentionData.toJson());
                    },
                    onRemoveMentionData: (mentionData) {
                      userMentions.removeWhere(
                          (_) => _.toJson() == mentionData.toJson());
                    },
                    onAddHashTagData: (mentionData) {
                      if (!tagMentions
                          .any((_) => _.toJson() == mentionData.toJson())) {
                        tagMentions.add(mentionData);
                      }
                    },
                    onAddMentionData: (mentionData) {
                      if (!userMentions
                          .any((_) => _.toJson() == mentionData.toJson())) {
                        userMentions.add(mentionData);
                      }
                    },
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _replyController,
                  builder: (context, value, child) => AppButton(
                    width: 70.responsiveDimension,
                    title: IsrTranslationFile.post,
                    textStyle: _replyFieldConfig?.postButtonStyle ??
                        IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: value.text.isStringEmptyOrNull
                              ? Theme.of(context)
                                  .primaryColor
                                  .changeOpacity(0.5)
                              : Theme.of(context).primaryColor,
                        ),
                    isDisable: value.text.isStringEmptyOrNull,
                    type: ButtonType.text,
                    onPress: () async {
                      if (value.text.isStringEmptyOrNull) return;

                      final commentText = value.text;
                      final postId = commentDataItem?.postId ?? widget.postId;
                      final parentCommentId = commentDataItem?.id ?? '';

                      // Clear input and hide keyboard immediately for better UX
                      _replyFocusNode.unfocus();
                      _replyController.clear();
                      final currentTagMentions =
                          List<CommentMentionData>.from(tagMentions);
                      final currentUserMentions =
                          List<CommentMentionData>.from(userMentions);
                      tagMentions.clear();
                      userMentions.clear();
                      _setReplyComment(null);

                      // Send to server - Bloc will handle optimistic UI update
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
                            'hashtags': currentTagMentions
                                .map((e) => e.toJson())
                                .toList(),
                            'mentions': currentUserMentions
                                .map((e) => e.toJson())
                                .toList(),
                          },
                          postDataModel: widget.postData,
                          tabDataModel: widget.tabData,
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
