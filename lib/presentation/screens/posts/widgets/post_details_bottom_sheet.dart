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
  });

  final PostDetailsSheetData data;
  final PostDetailsSheetDelegate? delegate;

  static Future<void> show({
    required BuildContext context,
    required PostDetailsSheetData data,
    PostDetailsSheetDelegate? delegate,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostDetailsBottomSheet(
          data: data,
          delegate: delegate,
        ),
      );

  Color get _primaryColor =>
      IsrVideoReelConfig.socialConfig.themeConfig?.primaryColor ?? IsrColors.appColor;

  void _close(BuildContext context) {
    Navigator.of(context).pop();
    delegate?.onClose?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
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
            if (data.status == PostReviewStatus.resubmitted) _buildResubmittedProgress(),
            _buildHeader(context),
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
                    IsrDimens.boxHeight(IsrDimens.sixteen),
                    if (data.status != PostReviewStatus.resubmitted) _buildMetaLabel(),
                    if (data.status != PostReviewStatus.resubmitted)
                      IsrDimens.boxHeight(IsrDimens.sixteen),
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

  bool get _hasFooterActions => data.status != PostReviewStatus.resubmitted;

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
                color: data.status == PostReviewStatus.resubmitted
                    ? const Color(0xFF22C55E)
                    : IsrColors.primaryTextColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildResubmittedProgress() => Padding(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.twentyFour,
          vertical: IsrDimens.twelve,
        ),
        child: Row(
          children: [
            _progressDot(filled: true),
            _progressLine(filled: true),
            _progressDot(filled: true),
            _progressLine(filled: true),
            _progressDot(filled: true),
            _progressLine(filled: true, thick: true),
          ],
        ),
      );

  Widget _progressDot({required bool filled}) => Container(
        width: IsrDimens.eight,
        height: IsrDimens.eight,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? _primaryColor : const Color(0xFFD1D5DB),
        ),
      );

  Widget _progressLine({required bool filled, bool thick = false}) => Expanded(
        child: Container(
          height: thick ? IsrDimens.three : IsrDimens.two,
          margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.four),
          decoration: BoxDecoration(
            color: filled ? _primaryColor : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(IsrDimens.two),
          ),
        ),
      );

  Widget _buildPreviewImage(BuildContext context) {
    final badge = _statusBadge();
    return ClipRRect(
      borderRadius: BorderRadius.circular(IsrDimens.twelve),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: _previewImage(),
          ),
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

  Widget _previewImage() {
    final url = data.previewImageUrl;
    if (url.isStringEmptyOrNull == true) {
      return ColoredBox(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: AppImage.svg(
            AssetConstants.icCoverImagePlaceHolder,
            width: IsrDimens.fortyEight,
            height: IsrDimens.fortyEight,
          ),
        ),
      );
    }
    return AppImage.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

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
          label: IsrTranslationFile.processing,
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
        return _buildRejectedBody();
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

  Widget _buildRejectedBody() {
    final rejected = data.rejectedCount ?? data.rejectedItems.length;
    final total = data.totalMediaCount ??
        (data.rejectedItems.isNotEmpty ? data.rejectedItems.length : rejected);
    final resolvedTotal = total > 0 ? total : rejected;
    final resolvedRejected = rejected > 0 ? rejected : data.rejectedItems.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppImage.svg(
                AssetConstants.icRejectedPostIcon,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resolvedTotal > 0
                      ? IsrTranslationFile.postDetailsRejectedItemsCount(
                          resolvedRejected,
                          resolvedTotal,
                        )
                      : IsrTranslationFile.postDetailsRejectedItemsFallback(
                          resolvedRejected,
                        ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          if (data.rejectedItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < data.rejectedItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _buildRejectedItemRow(data.rejectedItems[i]),
                  ],
                ],
              ),
            ),
          ],
          if (data.rejectedItems.isEmpty && data.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              data.rejectionReason!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF505050),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectedItemRow(PostReviewRejectedItem item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 72,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.expand(
                    child: item.thumbnailUrl.isStringEmptyOrNull == false
                        ? AppImage.network(item.thumbnailUrl!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: const Color(0xFFE5E7EB),
                            child: Center(
                              child: Icon(
                                item.isVideo ? Icons.videocam : Icons.image_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 22,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      item.isVideo ? Icons.videocam : Icons.image_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF182028),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF505050),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

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
              AssetConstants.icReviewPostIconBlack,
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
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildResubmittedBody() {
    final count = data.resubmittedReplacedCount ?? 0;
    final message =
        data.resubmittedMessage ?? IsrTranslationFile.postDetailsResubmittedMessage(count);
    return Column(
      children: [
        Container(
          width: IsrDimens.sixtyFour,
          height: IsrDimens.sixtyFour,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFF22C55E),
            size: 32,
          ),
        ),
        IsrDimens.boxHeight(IsrDimens.sixteen),
        Text(
          IsrTranslationFile.postDetailsResubmittedTitle,
          textAlign: TextAlign.center,
          style: IsrStyles.primaryText18.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        IsrDimens.boxHeight(IsrDimens.twelve),
        Text(
          message,
          textAlign: TextAlign.center,
          style: IsrStyles.primaryText14.copyWith(
            color: IsrColors.secondaryTextColor,
            height: 1.45,
          ),
        ),
        IsrDimens.boxHeight(IsrDimens.twentyFour),
      ],
    );
  }

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
        return _footerRow(
          context,
          secondaryLabel: IsrTranslationFile.deletePost,
          secondaryColor: IsrColors.error,
          onSecondary: () {
            Navigator.of(context).pop();
            unawaited(delegate?.onDeletePost?.call(data) ?? Future.value());
          },
          primaryLabel: IsrTranslationFile.editAndResubmit,
          onPrimary: () {
            Navigator.of(context).pop();
            unawaited(delegate?.onEditAndResubmit?.call(data) ?? Future.value());
          },
        );
      case PostReviewStatus.inReview:
        return _footerRow(
          context,
          secondaryLabel: IsrTranslationFile.withdrawPost,
          secondaryColor: IsrColors.error,
          onSecondary: () {
            Navigator.of(context).pop();
            final onWithdraw = delegate?.onWithdrawPost ?? delegate?.onDeletePost;
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
          secondaryColor: IsrColors.error,
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
