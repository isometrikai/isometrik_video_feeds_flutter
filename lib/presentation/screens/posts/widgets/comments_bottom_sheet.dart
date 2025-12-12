import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    required this.postId,
    required this.totalCommentsCount,
    this.onTapProfile,
    this.onTapHasTag,
    this.postData,
    this.tabData,
    Key? key,
  }) : super(key: key);

  final String postId;
  final int totalCommentsCount;
  final Function(String)? onTapProfile;
  final Function(String)? onTapHasTag;
  final TimeLineData? postData;
  final TabDataModel? tabData;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  SocialPostBloc get _socialBloc => context.getOrCreateBloc();
  final _postCommentList = <CommentDataItem>[];
  var _myUserId = '';
  var _isCommentsLoaded = false;
  CommentDataItem? _replyComment;
  var _totalCommentsCount = 0;
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  var _hasMoreComments = true;
  var _isLoadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _totalCommentsCount = widget.totalCommentsCount;
    _socialBloc.add(GetPostCommentsEvent(isLoading: true, postId: widget.postId));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrollPosition = _scrollController.position;
      final scrollPercentage = scrollPosition.pixels / scrollPosition.maxScrollExtent;

      if (scrollPercentage >= 0.6 && !_isLoadingMore && _hasMoreComments) {
        _isLoadingMore = true;
        _socialBloc.add(
          GetPostCommentsEvent(
            isLoading: false,
            postId: widget.postId,
            isPagination: true,
            onComplete: (comments) {
              setState(() {
                if (comments.isNotEmpty) {
                  _postCommentList.addAll(comments);
                  _hasMoreComments = true;
                } else {
                  _hasMoreComments = false;
                }
                _isLoadingMore = false;
                _totalCommentsCount = _postCommentList.length;
              });
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _replyFocusNode.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            Navigator.pop(context, _totalCommentsCount);
          }
        },
        child: BlocConsumer<SocialPostBloc, SocialPostState>(
          listenWhen: (previousState, currentState) =>
              currentState is LoadPostCommentState || currentState is LoadingPostComment,
          listener: (context, state) {
            debugPrint(
                'comment: state: $state comments : ${_postCommentList.map((_) => '${_.id}, ${_.comment}')}');
            if (state is LoadPostCommentState) {
              _isCommentsLoaded = true;
              _myUserId = state.myUserId ?? '';
              _postCommentList.clear();
              if (state.postCommentsList.isListEmptyOrNull == false) {
                _postCommentList.addAll(state.postCommentsList as Iterable<CommentDataItem>);
              } else {
                _setReplyComment(null);
              }
              _totalCommentsCount = _postCommentList.length;
            }
          },
          buildWhen: (previousState, currentState) =>
              currentState is LoadPostCommentState || currentState is LoadingPostComment,
          builder: (context, state) => SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: 80.percentHeight,
              ),
              decoration: BoxDecoration(
                color: IsrColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.responsiveDimension),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: IsrDimens.edgeInsetsSymmetric(
                      horizontal: 16.responsiveDimension,
                      vertical: 20.responsiveDimension,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          IsrTranslationFile.allComments,
                          style: IsrStyles.primaryText18.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TapHandler(
                          onTap: () {
                            context.pop(_totalCommentsCount);
                          },
                          child: const AppImage.svg(AssetConstants.icClose),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Products List
                  Expanded(
                    child: Stack(children: [
                      if (_postCommentList.isNotEmpty == true)
                        ListView.separated(
                          controller: _scrollController,
                          padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                          itemCount: _postCommentList.length,
                          separatorBuilder: (_, __) => 16.responsiveVerticalSpace,
                          itemBuilder: (context, index) =>
                              _buildCommentItem(_postCommentList[index]),
                        )
                      else if (!(state is LoadingPostComment))
                        _buildPlaceHolder(),
                    ]),
                  ),
                  if (_isCommentsLoaded) _buildReplyField(_replyComment),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCommentItem(CommentDataItem commentDataItem) {
    final comment = commentDataItem.also((_) => debugPrint('comment: comment tag: ${_.toJson()}'));
    return StatefulBuilder(
      builder: (context, setState) => Column(
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
                            text: comment.commentedBy ?? '',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                if (widget.onTapProfile != null) {
                                  widget.onTapProfile!(comment.commentedByUserId ?? '');
                                }
                              },
                            style: IsrStyles.primaryText14.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          ...Utility.buildCommentTextSpans(
                            '${comment.comment ?? ''}',
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
                        if (comment.id.isStringEmptyOrNull && !comment.status.isStringEmptyOrNull)
                          Text(
                            comment.status ?? '',
                            style: IsrStyles.primaryText12.copyWith(
                              color: '828282'.toColor(),
                            ),
                          ),
                        if (comment.id != null && comment.id!.isNotEmpty)
                          Text(
                            Utility.getTimeAgoFromDateTime(comment.commentedOn, showJustNow: true),
                            style: IsrStyles.primaryText12.copyWith(
                              color: '828282'.toColor(),
                            ),
                          ),
                        if (comment.id != null && comment.id!.isNotEmpty)
                          Text(
                            '${comment.likeCount} ${(comment.likeCount ?? 0) <= 1 ? IsrTranslationFile.like : IsrTranslationFile.likes}',
                            style: IsrStyles.primaryText12.copyWith(
                              color: '828282'.toColor(),
                            ),
                          ),
                        if (comment.id != null && comment.id!.isNotEmpty)
                          TapHandler(
                            onTap: () {
                              _setReplyComment(comment);
                            },
                            child: Text(
                              IsrTranslationFile.reply,
                              style: IsrStyles.primaryText12.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (!comment.showReply && (comment.childCommentCount ?? 0) > 0)
                          TapHandler(
                            onTap: () {
                              setState(() {
                                comment.showReply = true;
                              });
                              if (comment.id != null && comment.childComments.isEmptyOrNull) {
                                _socialBloc.add(GetPostCommentReplyEvent(
                                    isLoading: true,
                                    parentComment: comment,
                                    postId: widget.postId));
                              }
                            },
                            child: Text(
                              IsrTranslationFile.viewReplies,
                              style: IsrStyles.primaryText12
                                  .copyWith(fontWeight: FontWeight.w700, color: '94A0AF'.toColor()),
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
                          builder: (context) => _buildMoreOptionUI(comment),
                        );
                      },
                      child: const AppImage.svg(AssetConstants.icVerticalMoreMenu),
                    ),
                  ],
                ),
            ],
          ),
          // Child comments section
          if (comment.showReply) ...[
            BlocConsumer<SocialPostBloc, SocialPostState>(
                listenWhen: (previousState, currentState) =>
                (currentState is LoadPostCommentRepliesState && currentState.parentCommentId == comment.id) ||
                    (currentState is LoadingPostCommentReplies && currentState.parentCommentId == comment.id),
                buildWhen: (previousState, currentState) =>
                (currentState is LoadPostCommentRepliesState && currentState.parentCommentId == comment.id) ||
                    (currentState is LoadingPostCommentReplies && currentState.parentCommentId == comment.id),
                listener: (context, state) {
                  switch (state) {
                    case LoadPostCommentRepliesState():
                      comment.childComments = state.postCommentRepliesList;
                      if (state.postCommentRepliesList?.isNotEmpty != true) {
                        setState(() {
                          comment.showReply = false;
                        });
                      }
                      break;
                  }
                },
                builder: (context, state) => switch (state) {
                      LoadingPostCommentReplies() => Utility.loaderWidget(),
                      _ => Column(children: [
                          ...List.generate(
                            comment.childComments?.length ?? 0,
                            (index) => Padding(
                              padding: IsrDimens.edgeInsets(
                                  left: 32.responsiveDimension, top: 16.responsiveDimension),
                              child: _buildChildCommentItem(comment.childComments![index], false),
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
                              padding: IsrDimens.edgeInsets(
                                  left: 32.responsiveDimension, top: 16.responsiveDimension),
                              child: Text(
                                IsrTranslationFile.hideReplies,
                                style: IsrStyles.secondaryText12.copyWith(
                                    fontWeight: FontWeight.w700, color: '94A0AF'.toColor()),
                              ),
                            ),
                          )
                        ]),
                    }),
          ],
        ],
      ),
    );
  }

  Widget _buildChildCommentItem(CommentDataItem comment, bool isReply) {
    var likeCount = comment.likeCount ?? 0;
    return StatefulBuilder(
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
                        text: comment.commentedBy ?? '',
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (widget.onTapProfile != null) {
                              widget.onTapProfile!(comment.commentedByUserId ?? '');
                            }
                          },
                        style: IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      ...Utility.buildCommentTextSpans(
                        '${comment.comment ?? ''}',
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
                    if (comment.id.isStringEmptyOrNull && !comment.status.isStringEmptyOrNull)
                      Text(
                        comment.status ?? '',
                        style: IsrStyles.primaryText12.copyWith(
                          color: '828282'.toColor(),
                        ),
                      ),
                    if (comment.id != null && comment.id!.isNotEmpty)
                      Text(
                        Utility.getTimeAgoFromDateTime(comment.commentedOn),
                        style: IsrStyles.primaryText12.copyWith(
                          color: '828282'.toColor(),
                        ),
                      ),
                    if (comment.id != null && comment.id!.isNotEmpty)
                      Text(
                        '$likeCount ${likeCount <= 1 ? IsrTranslationFile.like : IsrTranslationFile.likes}',
                        style: IsrStyles.primaryText12.copyWith(
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
                          style: IsrStyles.primaryText12.copyWith(
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
                    });
                  },
                ),
                8.responsiveHorizontalSpace,
                TapHandler(
                  padding: 5.responsiveDimension,
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => _buildMoreOptionUI(comment),
                    );
                  },
                  child: const AppImage.svg(AssetConstants.icVerticalMoreMenu),
                ),
              ],
            ),
        ],
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
                maxWidth: 300.responsiveDimension,
                maxHeight: 200.responsiveDimension,
              ),
              padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
              margin: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
              decoration: BoxDecoration(
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
                        style: IsrStyles.primaryText18.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(height: 1),
                  ] else ...[
                    TapHandler(
                      onTap: () async {
                        // context.pop();
                        final data = await showDialog<int>(
                          context: context,
                          builder: (_) => ReportReasonDialog(
                            onConfirm: (reportReason) {
                              Navigator.pop(context, _totalCommentsCount);
                              _socialBloc.add(
                                CommentActionEvent(
                                  userId: comment.commentedByUserId,
                                  commentId: comment.id ?? '',
                                  commentAction: CommentAction.report,
                                  reportReason: reportReason.id,
                                  commentMessage: reportReason.name,
                                  postDataModel: widget.postData,
                                  tabDataModel: widget.tabData,
                                ),
                              );
                            },
                          ),
                        );
                        if (data == null) return;
                        Navigator.pop(context, data);
                      },
                      child: Text(
                        IsrTranslationFile.report,
                        style: IsrStyles.primaryText18.copyWith(
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
                      style: IsrStyles.primaryText18.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Close button above the dialog
            Positioned(
              right: 20,
              top: -20, // Adjust as needed
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.changeOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.close, size: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      );

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
              color: '001E57'.toColor(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${IsrTranslationFile.replyingTo} ',
                            style: IsrStyles.white14,
                          ),
                          TextSpan(
                            text: commentDataItem?.commentedBy ?? '',
                            style: IsrStyles.white14.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TapHandler(
                    onTap: () => _setReplyComment(null),
                    child: const AppImage.svg(
                      AssetConstants.icClose,
                      color: IsrColors.white,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: IsrDimens.edgeInsetsSymmetric(horizontal: 10.responsiveDimension),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _replyController,
              builder: (context, value, child) => Row(
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
                      decoration: const InputDecoration(
                        hintText: IsrTranslationFile.addAComment,
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        alignLabelWithHint: true,
                      ),
                      onRemoveHashTagData: (mentionData) {
                        debugPrint('comment: remove hash tag data: ${mentionData.toJson()}');
                        tagMentions.removeWhere((_) => _.toJson() == mentionData.toJson());
                      },
                      onRemoveMentionData: (mentionData) {
                        debugPrint('comment: remove mention data: ${mentionData.toJson()}');
                        userMentions.removeWhere((_) => _.toJson() == mentionData.toJson());
                      },
                      onAddHashTagData: (mentionData) {
                        debugPrint('comment: add hash tag data: ${mentionData.toJson()}');
                        if (!tagMentions.any((_) => _.toJson() == mentionData.toJson())) {
                          tagMentions.add(mentionData);
                        }
                      },
                      onAddMentionData: (mentionData) {
                        debugPrint('comment: add mention data: ${mentionData.toJson()}');
                        if (!userMentions.any((_) => _.toJson() == mentionData.toJson())) {
                          userMentions.add(mentionData);
                        }
                      },
                    ),
                  ),
                  AppButton(
                    width: 70.responsiveDimension,
                    title: IsrTranslationFile.post,
                    textStyle: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: value.text.isStringEmptyOrNull
                          ? Theme.of(context).primaryColor.changeOpacity(0.5)
                          : Theme.of(context).primaryColor,
                    ),
                    isDisable: value.text.isStringEmptyOrNull,
                    type: ButtonType.text,
                    onPress: () {
                      if (value.text.isStringEmptyOrNull) return;
                      final postId = commentDataItem?.postId;
                      _socialBloc.add(
                        CommentActionEvent(
                          userId: commentDataItem?.commentedByUserId,
                          isLoading: false,
                          parentCommentId: commentDataItem?.id ?? '',
                          postId: postId ?? widget.postId,
                          replyText: value.text,
                          commentAction: CommentAction.comment,
                          postedBy: _myUserId,
                          postCommentList: _postCommentList,
                          commentTags: {
                            'hashtags': tagMentions.map((e) => e.toJson()).toList(),
                            'mentions': userMentions.map((e) => e.toJson()).toList(),
                          }.also((_) => debugPrint('comment: comment tag: $_')),
                          postDataModel: widget.postData,
                          tabDataModel: widget.tabData,
                        ),
                      );
                      _replyController.clear();
                      tagMentions.clear();
                      userMentions.clear();
                      _setReplyComment(null);
                    },
                  ),
                ],
              ),
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
                  const AppImage.svg(AssetConstants.icCommentsPlaceHolder),
                  10.responsiveVerticalSpace,
                  Text(
                    IsrTranslationFile.noCommentsYet,
                    style: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  10.responsiveVerticalSpace,
                  Text(
                    IsrTranslationFile.beTheFirstOneToPostAComment,
                    style: IsrStyles.primaryText12.copyWith(
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

  void _logLikeCommentEvent(String eventName, String commentId, String postId) async {
    final eventMap = {
      'post_id': postId,
      'post_type': widget.postData?.type,
      'post_author_id': widget.postData?.userId,
      'feed_type': widget.tabData?.postSectionType.title,
      'interests': widget.postData?.interests ?? [],
      'hashtags': widget.postData?.tags?.hashtags?.map((e) => '#$e').toList(),
      'comment_id': commentId,
    };
    unawaited(EventQueueProvider.instance.addEvent(eventName, eventMap.removeEmptyValues()));
  }
}
