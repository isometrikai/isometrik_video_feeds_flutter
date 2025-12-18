import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class MoreOptionsBottomSheet extends StatefulWidget {
  const MoreOptionsBottomSheet({
    super.key,
    this.onPressReport,
    this.onDeletePost,
    this.onEditPost,
    this.onShowPostInsight,
    this.isSelfProfile = false,
  });

  final Future<bool> Function({String message, String reason})? onPressReport;
  final Future<bool> Function()? onDeletePost;
  final Future<String> Function()? onEditPost;
  final VoidCallback? onShowPostInsight;
  final bool isSelfProfile;

  @override
  State<MoreOptionsBottomSheet> createState() => _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState extends State<MoreOptionsBottomSheet> {
  ReportReason? selectedReason;
  bool showReportReasons = false;
  bool isLoadingReasons = false;
  bool isReportLoading = false;
  bool isLoadingDelete = false;
  List<ReportReason> reportReasons = [];

  Widget _buildReportOption(ReportReason reason) => RadioListTile<ReportReason>(
        title: Text(
          reason.name ?? '',
          style: IsrStyles.primaryText14,
        ),
        value: reason,
        activeColor: Theme.of(context).primaryColor,
        contentPadding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.sixteen,
          vertical: IsrDimens.four,
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: !showReportReasons
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (widget.isSelfProfile) ...[
                  const Divider(height: 1),
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      IsrTranslationFile.edit,
                      textAlign: TextAlign.center,
                      style: IsrStyles.primaryText16.copyWith(
                          fontWeight: FontWeight.w500, color: IsrColors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onEditPost != null) {
                        widget.onEditPost?.call();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      IsrTranslationFile.postInsight,
                      textAlign: TextAlign.center,
                      style: IsrStyles.primaryText16.copyWith(
                          fontWeight: FontWeight.w500, color: IsrColors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onShowPostInsight != null) {
                        widget.onShowPostInsight?.call();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  isLoadingDelete
                      ? Container(
                          padding: IsrDimens.edgeInsetsSymmetric(
                              vertical: 10.responsiveDimension),
                          child: SizedBox(
                            width: IsrDimens.twenty,
                            height: IsrDimens.twenty,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        )
                      : ListTile(
                          titleAlignment: ListTileTitleAlignment.center,
                          title: Text(
                            IsrTranslationFile.delete,
                            textAlign: TextAlign.center,
                            style: IsrStyles.primaryText16.copyWith(
                                fontWeight: FontWeight.w500,
                                color: IsrColors.black),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              isLoadingDelete = true;
                            });
                            widget.onDeletePost?.call().then((isSuccess) {
                              if (mounted) {
                                setState(() {
                                  isLoadingDelete = false;
                                });
                              }
                            });
                          },
                        ),
                ] else ...[
                  _showReportOption(),
                ],
                if (!showReportReasons) ...[
                  const Divider(height: 1),
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      IsrTranslationFile.cancel,
                      textAlign: TextAlign.center,
                      style: IsrStyles.primaryText16.copyWith(
                          fontWeight: FontWeight.w500, color: IsrColors.black),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _showReportOption() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!showReportReasons) ...[
            // Initial options dialog
            ListTile(
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(
                IsrTranslationFile.report,
                textAlign: TextAlign.center,
                style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w500, color: IsrColors.black),
              ),
              onTap: () async {
                setState(() {
                  showReportReasons = true;
                  isLoadingReasons = true;
                });

                try {
                  final completer = Completer<List<ReportReason>>();
                  IsmInjectionUtils.getBloc<SocialPostBloc>()
                      .add(GetReasonEvent(
                    onComplete: (reasons) {
                      completer.complete(reasons);
                    },
                    reasonsFor: ReasonsFor.socialPost,
                  ));

                  final reasons = await completer.future;
                  if (mounted) {
                    setState(() {
                      if (reasons.isListEmptyOrNull == true) {
                        isLoadingReasons = false;
                        showReportReasons = false;
                        Navigator.pop(context);
                        return;
                      }
                      reportReasons = reasons.map((e) => e).toList();
                      isLoadingReasons = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      isLoadingReasons = false;
                    });
                  }
                  Utility.showToastMessage(
                    IsrTranslationFile.failedToLoadReportReasons,
                  );
                }
              },
            ),
          ] else ...[
            // Report reasons dialog
            Padding(
              padding: IsrDimens.edgeInsets(
                left: IsrDimens.sixteen,
                top: IsrDimens.sixteen,
                bottom: IsrDimens.eight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    IsrTranslationFile.report,
                    style: IsrStyles.primaryText18.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: isReportLoading || isLoadingReasons
                        ? null
                        : () {
                            setState(() {
                              showReportReasons = false;
                              selectedReason = null;
                            });
                          },
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (isLoadingReasons) ...[
              Padding(
                padding: IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...[
              RadioGroup<ReportReason>(
                groupValue: selectedReason,
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reportReasons.length,
                  itemBuilder: (context, index) {
                    final reason = reportReasons[index];
                    return _buildReportOption(reason);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                child: isReportLoading
                    ? const SizedBox()
                    : SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          isDisable: selectedReason == null,
                          onPress: selectedReason == null || isReportLoading
                              ? null
                              : () async {
                                  if (widget.onPressReport == null) return;

                                  setState(() {
                                    isReportLoading = true;
                                  });

                                  try {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                    await widget.onPressReport!(
                                        message: selectedReason?.name ?? '',
                                        reason: selectedReason?.id ?? '');
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isReportLoading = false;
                                      });
                                    }
                                  }
                                },
                          title: IsrTranslationFile.confirm.toUpperCase(),
                        ),
                      ),
              ),
            ],
          ],
        ],
      );
}
