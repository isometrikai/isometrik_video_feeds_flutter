import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Status-driven post details sheet (rejected, in review, scheduled, resubmitted).
class PostDetailsBottomSheet extends StatelessWidget {
  const PostDetailsBottomSheet({
    super.key,
    required this.data,
    this.delegate,
    this.rejectedResubmitSuccessBuilder,
  });

  final PostDetailsSheetData data;
  final PostDetailsSheetDelegate? delegate;

  /// Optional override for the rejected-post inline resubmit success step.
  final RejectedPostResubmitSuccessBuilder? rejectedResubmitSuccessBuilder;

  static Future<void> show({
    required BuildContext context,
    required PostDetailsSheetData data,
    PostDetailsSheetDelegate? delegate,
    RejectedPostResubmitSuccessBuilder? rejectedResubmitSuccessBuilder,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Align(
          alignment: Alignment.bottomCenter,
          child: PostDetailsBottomSheet(
            data: data,
            delegate: delegate,
            rejectedResubmitSuccessBuilder: rejectedResubmitSuccessBuilder,
          ),
        ),
      );

  Color get _primaryColor =>
      IsrVideoReelConfig.socialConfig.themeConfig?.primaryColor ??
      IsrColors.appColor;

  void _close(BuildContext context) {
    Navigator.of(context).pop();
    delegate?.onClose?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final isRejected = data.status == PostReviewStatus.rejected;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            if (data.status == PostReviewStatus.resubmitted)
              RejectedPostProgressStepper(
                primaryColor: _primaryColor,
                progressLevel: 3,
              ),
            if (isRejected)
              RejectedPostDetailsFlow(
                data: data,
                primaryColor: _primaryColor,
                delegate: delegate,
                onClose: () => delegate?.onClose?.call(data),
                successBuilder: rejectedResubmitSuccessBuilder ??
                    delegate?.buildRejectedResubmitSuccess ??
                    RejectedPostResubmitSuccessView.defaultBuilder,
              )
            else if (data.status == PostReviewStatus.resubmitted)
              Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.sixteen),
                child: _buildResubmittedBody(),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.sixteen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (data.status != PostReviewStatus.resubmitted) ...[
                        _buildPreviewImage(context),
                        IsrDimens.boxHeight(IsrDimens.sixteen),
                      ],
                      _buildStatusBody(context),
                      if (data.status != PostReviewStatus.resubmitted &&
                          data.status != PostReviewStatus.inReview &&
                          data.status != PostReviewStatus.scheduled) ...[
                        IsrDimens.boxHeight(IsrDimens.sixteen),
                        _buildMetaLabel(),
                        IsrDimens.boxHeight(IsrDimens.sixteen),
                      ],
                    ],
                  ),
                ),
              ),
            if (_hasFooterActions) _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  bool get _hasFooterActions =>
      data.status != PostReviewStatus.resubmitted &&
      data.status != PostReviewStatus.rejected;

  Widget _buildHeader(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          IsrDimens.sixteen,
          IsrDimens.sixteen,
          IsrDimens.eight,
          IsrDimens.twelve,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                IsrTranslationFile.postDetails,
                style: IsrStyles.primaryText18.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IsrColors.primaryTextColor,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _close(context),
              icon: Icon(
                Icons.close,
                color: data.status == PostReviewStatus.resubmitted ||
                        data.status == PostReviewStatus.rejected
                    ? const Color(0xFF22C55E)
                    : IsrColors.primaryTextColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildPreviewImage(BuildContext context) {
    final badge = _statusBadge();
    final borderRadius = BorderRadius.circular(IsrDimens.twelve);
    final mediaItems = _previewMediaItems();

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: Color(0xFFEFF0F3)),
      ),
      child: Stack(
        children: [
          _buildPreviewMediaLayout(mediaItems),
          if (badge != null)
            Positioned(
              top: IsrDimens.ten,
              left: IsrDimens.ten,
              child: badge,
            ),
        ],
      ),
    );
  }

  List<_PreviewMediaItem> _previewMediaItems() {
    final postMedia = data.sourcePost?.media ?? [];
    if (postMedia.isNotEmpty) {
      return postMedia
          .map(
            (media) => _PreviewMediaItem(
              url: _mediaDisplayUrl(media),
            ),
          )
          .where((item) => item.url.isNotEmpty)
          .toList();
    }

    final previewUrl = data.previewImageUrl;
    if (previewUrl.isStringEmptyOrNull == false) {
      return [_PreviewMediaItem(url: previewUrl!)];
    }
    return const [];
  }

  String _mediaDisplayUrl(MediaData media) {
    final isVideo = (media.mediaType ?? '').toLowerCase() == 'video';
    if (isVideo) {
      return media.previewUrl?.isNotEmpty == true
          ? media.previewUrl!
          : (media.url ?? '');
    }
    return media.url ?? '';
  }

  Widget _buildPreviewMediaLayout(List<_PreviewMediaItem> items) {
    if (items.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.2,
        child: _previewPlaceholder(),
      );
    }

    if (items.length == 1) {
      return AspectRatio(
        aspectRatio: 1.2,
        child: _previewNetworkImage(items.first.url),
      );
    }

    final secondaryItems = items.skip(1).take(2).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: _previewNetworkImage(items.first.url),
        ),
        const ColoredBox(
          color: Color(0xFFD1D5DB),
          child: SizedBox(height: 1, width: double.infinity),
        ),
        Row(
          children: [
            for (var i = 0; i < secondaryItems.length; i++)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: i > 0
                        ? const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                          )
                        : const BoxDecoration(),
                    child: _previewNetworkImage(secondaryItems[i].url),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _previewPlaceholder() => ColoredBox(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: AppImage.svg(
            AssetConstants.icCoverImagePlaceHolder,
            width: IsrDimens.fortyEight,
            height: IsrDimens.fortyEight,
          ),
        ),
      );

  Widget _previewNetworkImage(String url) => AppImage.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  Widget? _statusBadge() {
    switch (data.status) {
      case PostReviewStatus.rejected:
        return _badge(
          label: IsrTranslationFile.rejected,
          iconAsset: AssetConstants.icRejectedPostIcon,
          background: const Color(0xFFDC2626),
          iconSize: 14,
        );
      case PostReviewStatus.inReview:
        return _badge(
          label: IsrTranslationFile.inReview,
          iconAsset: AssetConstants.icReviewPostIconBlack,
          background: const Color(0xFFF59E0B),
          textColor: const Color(0xFF000000),
        );
      case PostReviewStatus.scheduled:
        return _badge(
          label: IsrTranslationFile.scheduled,
          iconAsset: AssetConstants.icScheduledPostIcon,
          background: _primaryColor,
        );
      case PostReviewStatus.resubmitted:
        return null;
      case PostReviewStatus.processing:
        return _badge(
          label: IsrTranslationFile.optimizingMedia,
          iconAsset: AssetConstants.icReviewPostIconBlack,
          background: const Color(0xFF6B7280),
          iconColor: Colors.white,
        );
    }
  }

  Widget _badge({
    required String label,
    required String iconAsset,
    required Color background,
    double iconSize = 14,
    Color textColor = Colors.white,
    Color? iconColor,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage.svg(
              iconAsset,
              width: iconSize,
              height: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusBody(BuildContext context) {
    switch (data.status) {
      case PostReviewStatus.rejected:
        return const SizedBox.shrink();
      case PostReviewStatus.inReview:
        return _buildInReviewBody();
      case PostReviewStatus.scheduled:
        return _buildScheduledBody();
      case PostReviewStatus.resubmitted:
        return _buildResubmittedBody();
      case PostReviewStatus.processing:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInReviewBody() => Container(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(IsrDimens.twelve),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppImage.svg(
              AssetConstants.icReviewPostIcon,
              width: 24,
              height: 24,
            ),
            IsrDimens.boxWidth(IsrDimens.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    IsrTranslationFile.postDetailsAwaitingReview,
                    style: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  IsrDimens.boxHeight(IsrDimens.six),
                  Text(
                    IsrTranslationFile.postDetailsAwaitingReviewMessage,
                    style: IsrStyles.primaryText12.copyWith(
                      color: IsrColors.secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                  if (data.submittedAtLabel.isStringEmptyOrNull == false) ...[
                    IsrDimens.boxHeight(IsrDimens.eight),
                    Text(
                      data.submittedAtLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF848484),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildScheduledBody() => Container(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(IsrDimens.twelve),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppImage.svg(
              AssetConstants.icScheduledPostIcon,
              width: 24,
              height: 24,
              color: _primaryColor,
            ),
            IsrDimens.boxWidth(IsrDimens.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    IsrTranslationFile.postDetailsScheduledPostTitle,
                    style: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  IsrDimens.boxHeight(IsrDimens.six),
                  Text(
                    IsrTranslationFile.postDetailsScheduledPostMessage,
                    style: IsrStyles.primaryText12.copyWith(
                      color: IsrColors.secondaryTextColor,
                      height: 1.4,
                    ),
                  ),
                  if (_scheduledMetaLabel() != null) ...[
                    IsrDimens.boxHeight(IsrDimens.eight),
                    _scheduledMetaLabel()!,
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget? _scheduledMetaLabel() {
    if (data.scheduledForLabel.isStringEmptyOrNull == false) {
      return Text(
        data.scheduledForLabel!,
        style: IsrStyles.primaryText12.copyWith(
          color: IsrColors.secondaryTextColor,
        ),
      );
    }
    if (data.submittedAtLabel.isStringEmptyOrNull == false) {
      return Text(
        data.submittedAtLabel!,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF848484),
        ),
      );
    }
    return null;
  }

  Widget _buildResubmittedBody() => RejectedPostResubmitSuccessView(
        data: RejectedPostResubmitSuccessData(
          sheetData: data,
          replacedCount: data.resubmittedReplacedCount ?? 0,
        ),
      );

  Widget _buildMetaLabel() {
    final parts = <String>[];
    if (data.submittedAtLabel.isStringEmptyOrNull == false) {
      parts.add(data.submittedAtLabel!);
    }
    if (data.reviewedAtLabel.isStringEmptyOrNull == false) {
      parts.add(data.reviewedAtLabel!);
    }
    if (data.status == PostReviewStatus.scheduled &&
        data.scheduledForLabel.isStringEmptyOrNull == false) {
      return Text(
        data.scheduledForLabel!,
        style: IsrStyles.primaryText12.copyWith(
          color: IsrColors.secondaryTextColor,
        ),
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        parts.join(' • '),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF848484),
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    switch (data.status) {
      case PostReviewStatus.rejected:
        return const SizedBox.shrink();
      case PostReviewStatus.inReview:
        return _footerRow(
          context,
          secondaryLabel: IsrTranslationFile.withdrawPost,
          secondaryColor: '#E7000B'.toColor(),
          onSecondary: () {
            Navigator.of(context).pop();
            final onWithdraw =
                delegate?.onWithdrawPost ?? delegate?.onDeletePost;
            unawaited(onWithdraw?.call(data) ?? Future.value());
          },
          primaryLabel: IsrTranslationFile.editSubmission,
          onPrimary: () {
            Navigator.of(context).pop();
            unawaited(delegate?.onEditSubmission?.call(data) ?? Future.value());
          },
        );
      case PostReviewStatus.scheduled:
        return _footerRow(
          context,
          secondaryLabel: IsrTranslationFile.deletePost,
          secondaryColor: '#E7000B'.toColor(),
          onSecondary: () {
            Navigator.of(context).pop();
            unawaited(delegate?.onDeletePost?.call(data) ?? Future.value());
          },
          primaryLabel: IsrTranslationFile.publishNow,
          onPrimary: () {
            Navigator.of(context).pop();
            unawaited(delegate?.onPublishNow?.call(data) ?? Future.value());
          },
        );
      case PostReviewStatus.resubmitted:
        return const SizedBox.shrink();
      case PostReviewStatus.processing:
        return const SizedBox.shrink();
    }
  }

  Widget _footerRow(
    BuildContext context, {
    required String secondaryLabel,
    required Color secondaryColor,
    required VoidCallback onSecondary,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryColor,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  secondaryLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _PreviewMediaItem {
  const _PreviewMediaItem({required this.url});

  final String url;
}
