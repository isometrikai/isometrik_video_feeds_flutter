import 'package:flutter/material.dart';

class CommentConfig {
  const CommentConfig({
    this.commentUIConfig,
    this.showFloatingcomments = false,
  });

  final CommentUIConfig? commentUIConfig;
  final bool showFloatingcomments;

  CommentConfig copyWith({
    CommentUIConfig? commentUIConfig,
    bool? showFloatingcomments,
  }) =>
      CommentConfig(
        commentUIConfig: commentUIConfig ?? this.commentUIConfig,
        showFloatingcomments: showFloatingcomments ?? this.showFloatingcomments,
      );
}

class CommentUIConfig {
  const CommentUIConfig({
    this.bottomSheetConfig,
    this.headerConfig,
    this.commentItemConfig,
    this.belowCommentsConfig,
    this.replyFieldConfig,
    this.placeholderConfig,
    this.moreOptionsConfig,
  });

  final BottomSheetConfig? bottomSheetConfig;
  final CommentHeaderConfig? headerConfig;
  final CommentItemConfig? commentItemConfig;
  final BelowCommentsConfig? belowCommentsConfig;
  final ReplyFieldConfig? replyFieldConfig;
  final CommentPlaceholderConfig? placeholderConfig;
  final MoreOptionsConfig? moreOptionsConfig;

  CommentUIConfig copyWith({
    BottomSheetConfig? bottomSheetConfig,
    CommentHeaderConfig? headerConfig,
    CommentItemConfig? commentItemConfig,
    BelowCommentsConfig? belowCommentsConfig,
    ReplyFieldConfig? replyFieldConfig,
    CommentPlaceholderConfig? placeholderConfig,
    MoreOptionsConfig? moreOptionsConfig,
  }) =>
      CommentUIConfig(
        bottomSheetConfig: bottomSheetConfig ?? this.bottomSheetConfig,
        headerConfig: headerConfig ?? this.headerConfig,
        commentItemConfig: commentItemConfig ?? this.commentItemConfig,
        belowCommentsConfig: belowCommentsConfig ?? this.belowCommentsConfig,
        replyFieldConfig: replyFieldConfig ?? this.replyFieldConfig,
        placeholderConfig: placeholderConfig ?? this.placeholderConfig,
        moreOptionsConfig: moreOptionsConfig ?? this.moreOptionsConfig,
      );
}

/// Configuration for the bottom sheet container
class BottomSheetConfig {
  const BottomSheetConfig({
    this.backgroundColor,
    this.borderRadius,
    this.maxHeight,
    this.padding,
  });

  /// Background color of the bottom sheet
  final Color? backgroundColor;

  /// Border radius for the top corners
  final double? borderRadius;

  /// Maximum height of the bottom sheet (as percentage of screen height)
  final double? maxHeight;

  /// Padding for the bottom sheet content
  final EdgeInsetsGeometry? padding;

  BottomSheetConfig copyWith({
    Color? backgroundColor,
    double? borderRadius,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
  }) =>
      BottomSheetConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        maxHeight: maxHeight ?? this.maxHeight,
        padding: padding ?? this.padding,
      );
}

/// Configuration for the comments header
class CommentHeaderConfig {
  const CommentHeaderConfig({
    this.titleStyle,
    this.closeIcon,
    this.closeIconSize,
    this.closeIconColor,
    this.headerPadding,
  });

  /// Style for the "All Comments" title
  final TextStyle? titleStyle;

  /// Icon path for the close button
  final String? closeIcon;

  /// Size for the close icon
  final double? closeIconSize;

  /// Color for the close icon
  final Color? closeIconColor;

  /// Padding for the header section
  final EdgeInsetsGeometry? headerPadding;

  CommentHeaderConfig copyWith({
    TextStyle? titleStyle,
    String? closeIcon,
    double? closeIconSize,
    Color? closeIconColor,
    EdgeInsetsGeometry? headerPadding,
  }) =>
      CommentHeaderConfig(
        titleStyle: titleStyle ?? this.titleStyle,
        closeIcon: closeIcon ?? this.closeIcon,
        closeIconSize: closeIconSize ?? this.closeIconSize,
        closeIconColor: closeIconColor ?? this.closeIconColor,
        headerPadding: headerPadding ?? this.headerPadding,
      );
}

/// Configuration for comment items
class CommentItemConfig {
  const CommentItemConfig({
    this.usernameStyle,
    this.commentTextStyle,
    this.userTagTextStyle,
    this.hashtagTextStyle,
    this.timestampStyle,
    this.likeCountStyle,
    this.replyButtonStyle,
    this.viewRepliesStyle,
    this.hideRepliesStyle,
    this.moreIcon,
    this.moreIconSize,
    this.moreIconColor,
    this.commentPadding,
    this.commentSpacing,
    this.childCommentPadding,
    this.childCommentIndent,
  });

  /// Style for comment author username
  final TextStyle? usernameStyle;

  /// Style for comment text content
  final TextStyle? commentTextStyle;

  /// Style for user tag in comment text content
  final TextStyle? userTagTextStyle;

  /// Style for hashtag in comment text content
  final TextStyle? hashtagTextStyle;

  /// Style for timestamp text
  final TextStyle? timestampStyle;

  /// Style for like count text
  final TextStyle? likeCountStyle;

  /// Style for reply button text
  final TextStyle? replyButtonStyle;

  /// Style for "View Replies" text
  final TextStyle? viewRepliesStyle;

  /// Style for "Hide Replies" text
  final TextStyle? hideRepliesStyle;

  /// Icon path for more options menu
  final String? moreIcon;

  /// Size for more options icon
  final double? moreIconSize;

  /// Color for more options icon
  final Color? moreIconColor;

  /// Padding for each comment item
  final EdgeInsetsGeometry? commentPadding;

  /// Spacing between comments
  final double? commentSpacing;

  /// Padding for child/reply comments
  final EdgeInsetsGeometry? childCommentPadding;

  /// Left indent for child comments
  final double? childCommentIndent;

  CommentItemConfig copyWith({
    TextStyle? usernameStyle,
    TextStyle? commentTextStyle,
    TextStyle? userTagTextStyle,
    TextStyle? hashtagTextStyle,
    TextStyle? timestampStyle,
    TextStyle? likeCountStyle,
    TextStyle? replyButtonStyle,
    TextStyle? viewRepliesStyle,
    TextStyle? hideRepliesStyle,
    String? moreIcon,
    double? moreIconSize,
    Color? moreIconColor,
    EdgeInsetsGeometry? commentPadding,
    double? commentSpacing,
    EdgeInsetsGeometry? childCommentPadding,
    double? childCommentIndent,
  }) =>
      CommentItemConfig(
        usernameStyle: usernameStyle ?? this.usernameStyle,
        commentTextStyle: commentTextStyle ?? this.commentTextStyle,
        userTagTextStyle: userTagTextStyle ?? this.userTagTextStyle,
        hashtagTextStyle: hashtagTextStyle ?? this.hashtagTextStyle,
        timestampStyle: timestampStyle ?? this.timestampStyle,
        likeCountStyle: likeCountStyle ?? this.likeCountStyle,
        replyButtonStyle: replyButtonStyle ?? this.replyButtonStyle,
        viewRepliesStyle: viewRepliesStyle ?? this.viewRepliesStyle,
        hideRepliesStyle: hideRepliesStyle ?? this.hideRepliesStyle,
        moreIcon: moreIcon ?? this.moreIcon,
        moreIconSize: moreIconSize ?? this.moreIconSize,
        moreIconColor: moreIconColor ?? this.moreIconColor,
        commentPadding: commentPadding ?? this.commentPadding,
        commentSpacing: commentSpacing ?? this.commentSpacing,
        childCommentPadding: childCommentPadding ?? this.childCommentPadding,
        childCommentIndent: childCommentIndent ?? this.childCommentIndent,
      );
}

/// Configuration for comments shown below post caption/details
class BelowCommentsConfig {
  const BelowCommentsConfig({
    this.usernameStyle,
    this.commentTextStyle,
    this.userTagTextStyle,
    this.hashtagTextStyle,
    this.viewAllCommentsStyle,
    this.viewAllCommentsText,
    this.commentSpacing,
    this.maxLinesPerComment,
    this.maxVisibleComments,
    this.animationDurationInMilliseconds,
    this.animationOffsetY,
  });

  /// Style for comment author username
  final TextStyle? usernameStyle;

  /// Style for comment text content
  final TextStyle? commentTextStyle;

  /// Style for @user tags in comment text
  final TextStyle? userTagTextStyle;

  /// Style for #hashtag tags in comment text
  final TextStyle? hashtagTextStyle;

  /// Style for "View all comments" action
  final TextStyle? viewAllCommentsStyle;

  /// Override for "View all comments" text
  final String? viewAllCommentsText;

  /// Spacing between comment rows
  final double? commentSpacing;

  /// Max lines for each comment row
  final int? maxLinesPerComment;

  /// Number of comments to show below the post
  final int? maxVisibleComments;

  /// Animation duration for comments update
  final int? animationDurationInMilliseconds;

  /// Vertical offset used by slide animation
  final double? animationOffsetY;

  BelowCommentsConfig copyWith({
    TextStyle? usernameStyle,
    TextStyle? commentTextStyle,
    TextStyle? userTagTextStyle,
    TextStyle? hashtagTextStyle,
    TextStyle? viewAllCommentsStyle,
    String? viewAllCommentsText,
    double? commentSpacing,
    int? maxLinesPerComment,
    int? maxVisibleComments,
    int? animationDurationInMilliseconds,
    double? animationOffsetY,
  }) =>
      BelowCommentsConfig(
        usernameStyle: usernameStyle ?? this.usernameStyle,
        commentTextStyle: commentTextStyle ?? this.commentTextStyle,
        userTagTextStyle: userTagTextStyle ?? this.userTagTextStyle,
        hashtagTextStyle: hashtagTextStyle ?? this.hashtagTextStyle,
        viewAllCommentsStyle: viewAllCommentsStyle ?? this.viewAllCommentsStyle,
        viewAllCommentsText: viewAllCommentsText ?? this.viewAllCommentsText,
        commentSpacing: commentSpacing ?? this.commentSpacing,
        maxLinesPerComment: maxLinesPerComment ?? this.maxLinesPerComment,
        maxVisibleComments: maxVisibleComments ?? this.maxVisibleComments,
        animationDurationInMilliseconds:
            animationDurationInMilliseconds ??
                this.animationDurationInMilliseconds,
        animationOffsetY: animationOffsetY ?? this.animationOffsetY,
      );
}

/// Configuration for the reply input field
class ReplyFieldConfig {
  const ReplyFieldConfig({
    this.replyingToBackgroundColor,
    this.replyingToTextStyle,
    this.replyingToNameStyle,
    this.closeReplyIcon,
    this.closeReplyIconSize,
    this.closeReplyIconColor,
    this.inputDecoration,
    this.inputTextStyle,
    this.inputUserTagTextStyle,
    this.inputHashtagTextStyle,
    this.hintTextStyle,
    this.postButtonStyle,
    this.replyFieldPadding,
  });

  /// Background color for the "Replying to" section
  final Color? replyingToBackgroundColor;

  /// Style for "Replying to" text
  final TextStyle? replyingToTextStyle;

  /// Style for the username in "Replying to" section
  final TextStyle? replyingToNameStyle;

  /// Icon path for close reply button
  final String? closeReplyIcon;

  /// Size for close reply icon
  final double? closeReplyIconSize;

  /// Color for close reply icon
  final Color? closeReplyIconColor;

  /// Decoration for the text input field
  final InputDecoration? inputDecoration;

  /// Style for input text
  final TextStyle? inputTextStyle;

  /// Style for user tag in comment text content
  final TextStyle? inputUserTagTextStyle;

  /// Style for hashtag in comment text content
  final TextStyle? inputHashtagTextStyle;

  /// Style for hint text
  final TextStyle? hintTextStyle;

  /// Style for post button text
  final TextStyle? postButtonStyle;

  /// Padding for the reply field container
  final EdgeInsetsGeometry? replyFieldPadding;

  ReplyFieldConfig copyWith({
    Color? replyingToBackgroundColor,
    TextStyle? replyingToTextStyle,
    TextStyle? replyingToNameStyle,
    String? closeReplyIcon,
    double? closeReplyIconSize,
    Color? closeReplyIconColor,
    InputDecoration? inputDecoration,
    TextStyle? inputTextStyle,
    TextStyle? inputUserTagTextStyle,
    TextStyle? inputHashtagTextStyle,
    TextStyle? hintTextStyle,
    TextStyle? postButtonStyle,
    EdgeInsetsGeometry? replyFieldPadding,
  }) =>
      ReplyFieldConfig(
        replyingToBackgroundColor:
            replyingToBackgroundColor ?? this.replyingToBackgroundColor,
        replyingToTextStyle: replyingToTextStyle ?? this.replyingToTextStyle,
        replyingToNameStyle: replyingToNameStyle ?? this.replyingToNameStyle,
        closeReplyIcon: closeReplyIcon ?? this.closeReplyIcon,
        closeReplyIconSize: closeReplyIconSize ?? this.closeReplyIconSize,
        closeReplyIconColor: closeReplyIconColor ?? this.closeReplyIconColor,
        inputDecoration: inputDecoration ?? this.inputDecoration,
        inputTextStyle: inputTextStyle ?? this.inputTextStyle,
        inputUserTagTextStyle: inputUserTagTextStyle ?? this.inputUserTagTextStyle,
        inputHashtagTextStyle: inputHashtagTextStyle ?? this.inputHashtagTextStyle,
        hintTextStyle: hintTextStyle ?? this.hintTextStyle,
        postButtonStyle: postButtonStyle ?? this.postButtonStyle,
        replyFieldPadding: replyFieldPadding ?? this.replyFieldPadding,
      );
}

/// Configuration for empty state placeholder
class CommentPlaceholderConfig {
  const CommentPlaceholderConfig({
    this.placeholderIcon,
    this.placeholderIconSize,
    this.placeholderIconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  /// Icon path for empty comments placeholder
  final String? placeholderIcon;

  /// Size for placeholder icon
  final double? placeholderIconSize;

  /// Color for placeholder icon
  final Color? placeholderIconColor;

  /// Style for "No comments yet" title
  final TextStyle? titleStyle;

  /// Style for "Be the first one..." subtitle
  final TextStyle? subtitleStyle;

  CommentPlaceholderConfig copyWith({
    String? placeholderIcon,
    double? placeholderIconSize,
    Color? placeholderIconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) =>
      CommentPlaceholderConfig(
        placeholderIcon: placeholderIcon ?? this.placeholderIcon,
        placeholderIconSize: placeholderIconSize ?? this.placeholderIconSize,
        placeholderIconColor: placeholderIconColor ?? this.placeholderIconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      );
}

/// Configuration for more options dialog
class MoreOptionsConfig {
  const MoreOptionsConfig({
    this.dialogDecoration,
    this.dialogPadding,
    this.dialogMargin,
    this.optionTextStyle,
    this.deleteTextStyle,
    this.reportTextStyle,
    this.cancelTextStyle,
    this.maxWidth,
    this.maxHeight,
  });

  /// Decoration for the more options dialog
  final BoxDecoration? dialogDecoration;

  /// Padding inside the dialog
  final EdgeInsetsGeometry? dialogPadding;

  /// Margin around the dialog
  final EdgeInsetsGeometry? dialogMargin;

  /// Style for option text (delete, report, cancel)
  final TextStyle? optionTextStyle;

  /// Style for delete option text
  final TextStyle? deleteTextStyle;

  /// Style for report option text
  final TextStyle? reportTextStyle;

  /// Style for cancel option text
  final TextStyle? cancelTextStyle;

  /// Maximum width for the dialog
  final double? maxWidth;

  /// Maximum height for the dialog
  final double? maxHeight;

  MoreOptionsConfig copyWith({
    BoxDecoration? dialogDecoration,
    EdgeInsetsGeometry? dialogPadding,
    EdgeInsetsGeometry? dialogMargin,
    TextStyle? optionTextStyle,
    TextStyle? deleteTextStyle,
    TextStyle? reportTextStyle,
    TextStyle? cancelTextStyle,
    double? maxWidth,
    double? maxHeight,
  }) =>
      MoreOptionsConfig(
        dialogDecoration: dialogDecoration ?? this.dialogDecoration,
        dialogPadding: dialogPadding ?? this.dialogPadding,
        dialogMargin: dialogMargin ?? this.dialogMargin,
        optionTextStyle: optionTextStyle ?? this.optionTextStyle,
        deleteTextStyle: deleteTextStyle ?? this.deleteTextStyle,
        reportTextStyle: reportTextStyle ?? this.reportTextStyle,
        cancelTextStyle: cancelTextStyle ?? this.cancelTextStyle,
        maxWidth: maxWidth ?? this.maxWidth,
        maxHeight: maxHeight ?? this.maxHeight,
      );
}
