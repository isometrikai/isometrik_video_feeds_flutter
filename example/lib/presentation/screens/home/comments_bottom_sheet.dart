import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    required this.postId,
    required this.totalCommentsCount,
    this.onTapProfile,
    Key? key,
  }) : super(key: key);

  final String postId;
  final int totalCommentsCount;
  final Function(String)? onTapProfile;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _homeBloc = InjectionUtils.getBloc<HomeBloc>();
  final _postCommentList = <CommentDataItem>[];
  var _myUserId = '';
  var _isCommentsLoaded = false;
  CommentDataItem? _replyComment;
  var _totalCommentsCount = 0;
  final _replyController = TextEditingController();
  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _totalCommentsCount = widget.totalCommentsCount;
    _homeBloc.add(GetPostCommentsEvent(isLoading: true, postId: widget.postId));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) {
            Navigator.pop(context, _totalCommentsCount);
          }
        },
        child: BlocConsumer<HomeBloc, HomeState>(
          listenWhen: (previousState, currentState) =>
              currentState is LoadPostCommentState || currentState is LoadingPostComment,
          listener: (context, state) {
            if (state is LoadPostCommentState) {
              _isCommentsLoaded = true;
              _myUserId = state.myUserId ?? '';
              _postCommentList.clear();
              if (state.postCommentsList.isEmptyOrNull == false) {
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
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimens.twenty),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: Dimens.edgeInsetsSymmetric(
                      horizontal: Dimens.sixteen,
                      vertical: Dimens.twenty,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationFile.allComments,
                          style: Styles.primaryText18.copyWith(
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
                    child: state is LoadingPostComment
                        ? Utility.loaderWidget()
                        : _postCommentList.isEmptyOrNull == true
                            ? _buildPlaceHolder()
                            : ListView.separated(
                                padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                                itemCount: _postCommentList.length,
                                separatorBuilder: (_, __) => 16.verticalSpace,
                                itemBuilder: (context, index) =>
                                    _buildCommentItem(_postCommentList[index]),
                              ),
                  ),
                  if (_isCommentsLoaded) _buildReplyField(_replyComment),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCommentItem(CommentDataItem commentDataItem) {
    final comment = commentDataItem;
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
                            style: Styles.primaryText14.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' ${comment.comment ?? ''}',
                            style: Styles.primaryText14,
                          ),
                        ],
                      ),
                    ),
                    8.verticalSpace,
                    Row(
                      spacing: 12.scaledValue,
                      children: [
                        Text(
                          DateTimeUtil.getTimeAgoFromDateTime(comment.commentedOn),
                          style: Styles.primaryText12.copyWith(
                            color: '828282'.toHexColor,
                          ),
                        ),
                        Text(
                          '${comment.likeCount} ${(comment.likeCount ?? 0) <= 1 ? TranslationFile.like : TranslationFile.likes}',
                          style: Styles.primaryText12.copyWith(
                            color: '828282'.toHexColor,
                          ),
                        ),
                        TapHandler(
                          onTap: () {
                            _setReplyComment(comment);
                          },
                          child: Text(
                            TranslationFile.reply,
                            style: Styles.primaryText12.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              4.horizontalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LikeCommentIconView(
                    postId: comment.postId ?? '',
                    commentId: comment.id ?? '',
                    isLiked: comment.isLiked == true,
                    onLikeDisLikeComment: (isLiked) {
                      if (!context.mounted) return;
                      setState(() {
                        comment.likeCount = isLiked
                            ? (comment.likeCount ?? 0) + 1
                            : comment.likeCount == 0
                                ? 0
                                : (comment.likeCount ?? 0) - 1;
                      });
                    },
                  ),
                  8.horizontalSpace,
                  TapHandler(
                    padding: 5.scaledValue,
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
          if (comment.childComments.isEmptyOrNull == false) ...[
            ...List.generate(
              comment.childComments?.length ?? 0,
              (index) => Padding(
                padding: Dimens.edgeInsets(left: 32.scaledValue, top: 16.scaledValue),
                child: _buildChildCommentItem(comment.childComments![index], false),
              ),
            ),
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
                        style: Styles.primaryText14.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' ${comment.comment ?? ''}',
                        style: Styles.primaryText14,
                      ),
                    ],
                  ),
                ),
                8.verticalSpace,
                Row(
                  spacing: 12.scaledValue,
                  children: [
                    Text(
                      DateTimeUtil.getTimeAgoFromDateTime(comment.commentedOn),
                      style: Styles.primaryText12.copyWith(
                        color: '828282'.toHexColor,
                      ),
                    ),
                    Text(
                      '$likeCount ${likeCount <= 1 ? TranslationFile.like : TranslationFile.likes}',
                      style: Styles.primaryText12.copyWith(
                        color: '828282'.toHexColor,
                      ),
                    ),
                    if (isReply) ...[
                      TapHandler(
                        onTap: () {
                          _setReplyComment(comment);
                        },
                        child: Text(
                          TranslationFile.reply,
                          style: Styles.primaryText12.copyWith(
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
          4.horizontalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LikeCommentIconView(
                postId: comment.postId ?? '',
                commentId: comment.id ?? '',
                isLiked: comment.isLiked == true,
                onLikeDisLikeComment: (isLiked) {
                  if (!context.mounted) return;
                  setState(() {
                    likeCount = isLiked
                        ? likeCount + 1
                        : likeCount == 0
                            ? 0
                            : likeCount - 1;
                  });
                },
              ),
              8.horizontalSpace,
              TapHandler(
                padding: 5.scaledValue,
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
                maxWidth: 300.scaledValue,
                maxHeight: 200.scaledValue,
              ),
              padding: Dimens.edgeInsetsAll(Dimens.sixteen),
              margin: Dimens.edgeInsetsAll(Dimens.sixteen),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(Dimens.twenty),
                ),
              ),
              child: Column(
                spacing: 10.scaledValue,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_myUserId == comment.commentedByUserId) ...[
                    TapHandler(
                      onTap: () {
                        context.pop();
                        _homeBloc.add(
                          CommentActionEvent(
                            commentIds: [comment.id ?? ''],
                            postId: widget.postId,
                            commentAction: CommentAction.delete,
                            onComplete: (commentId, isSuccess) {
                              if (isSuccess) {
                                _homeBloc.add(GetPostCommentsEvent(postId: widget.postId));
                              }
                            },
                          ),
                        );
                      },
                      child: Text(
                        TranslationFile.delete,
                        style: Styles.primaryText18.copyWith(
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
                              _homeBloc.add(
                                CommentActionEvent(
                                  commentId: comment.id ?? '',
                                  commentAction: CommentAction.report,
                                  reportReason: reportReason,
                                  commentMessage: '',
                                ),
                              );
                            },
                          ),
                        );
                        if (data == null) return;
                        Navigator.pop(context, data);
                      },
                      child: Text(
                        TranslationFile.report,
                        style: Styles.primaryText18.copyWith(
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
                      TranslationFile.cancel,
                      style: Styles.primaryText18.copyWith(
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
                        color: Colors.white.applyOpacity(0.2),
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
    if (!mounted) return;
    setState(() {
      _replyComment = comment;
    });
  }

  Widget _buildReplyField(CommentDataItem? commentDataItem) => StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (commentDataItem?.commentedBy.isEmptyOrNull == false)
              Container(
                padding: Dimens.edgeInsetsAll(16.scaledValue),
                color: '001E57'.toHexColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${TranslationFile.replyingTo} ',
                              style: Styles.white14,
                            ),
                            TextSpan(
                              text: commentDataItem?.commentedBy ?? '',
                              style: Styles.white14.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TapHandler(
                      onTap: () => _setReplyComment(null),
                      child: const AppImage.svg(
                        AssetConstants.icClose,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: Dimens.edgeInsetsSymmetric(horizontal: 10.scaledValue),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _replyController,
                builder: (context, value, child) => TextField(
                  controller: _replyController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: TranslationFile.addAComment,
                    border: InputBorder.none,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    alignLabelWithHint: true,
                    suffix: AppButton(
                      width: 70.scaledValue,
                      title: TranslationFile.post,
                      isDisable: value.text.isEmptyOrNull,
                      onPress: () {
                        if (value.text.isEmptyOrNull) return;
                        final postId = commentDataItem?.postId;
                        _homeBloc.add(
                          CommentActionEvent(
                            parentCommentId: commentDataItem?.id ?? '',
                            postId: postId ?? widget.postId,
                            replyText: value.text,
                            commentAction: CommentAction.comment,
                            postedBy: _myUserId,
                          ),
                        );
                        _replyController.clear();
                        _setReplyComment(null);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildPlaceHolder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppImage.svg(AssetConstants.icCommentsPlaceHolder),
          10.verticalSpace,
          Text(
            TranslationFile.noCommentsYet,
            style: Styles.primaryText14.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          10.verticalSpace,
          Text(
            TranslationFile.beTheFirstOneToPostAComment,
            style: Styles.primaryText12.copyWith(
              color: '606060'.toHexColor,
            ),
          ),
        ],
      );

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}
