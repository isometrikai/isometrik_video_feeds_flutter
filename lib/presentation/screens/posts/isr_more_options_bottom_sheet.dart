import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrMoreOptionsBottomSheet extends StatefulWidget {
  const IsrMoreOptionsBottomSheet({
    super.key,
    this.onPressSave,
    this.onPressReport,
  });

  final Future<bool> Function()? onPressSave;
  final Future<bool> Function({String message, String reason})? onPressReport;

  @override
  State<IsrMoreOptionsBottomSheet> createState() => _IsrMoreOptionsBottomSheetState();
}

class _IsrMoreOptionsBottomSheetState extends State<IsrMoreOptionsBottomSheet> {
  String? selectedReason;
  bool showReportReasons = false;
  bool isLoadingReasons = false;
  bool isReportLoading = false;
  List<String> reportReasons = [];

  Widget _buildReportOption(
    String title,
    String? selectedReason,
    void Function(String?) onChanged,
  ) =>
      RadioListTile<String>(
        title: Text(
          title,
          style: IsrStyles.primaryText14,
        ),
        value: title,
        groupValue: selectedReason,
        onChanged: onChanged,
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
              crossAxisAlignment: !showReportReasons ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (!showReportReasons) ...[
                  // Initial options dialog
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      IsrTranslationFile.report,
                      style: IsrStyles.primaryText18.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      setState(() {
                        showReportReasons = true;
                        isLoadingReasons = true;
                      });

                      try {
                        final completer = Completer<List<String>>();
                        InjectionUtils.getBloc<PostBloc>().add(GetReasonEvent(
                          onComplete: (reasons) {
                            completer.complete(reasons);
                          },
                        ));

                        final reasons = await completer.future;
                        if (mounted) {
                          setState(() {
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
                        IsrVideoReelUtility.showToastMessage(
                          'Failed to load report reasons',
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      IsrTranslationFile.cancel,
                      style: IsrStyles.primaryText18.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(context),
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
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: reportReasons
                              .map(
                                (reason) => _buildReportOption(
                                  reason,
                                  selectedReason,
                                  (value) {
                                    setState(() => selectedReason = value);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                      child: isReportLoading
                          ? Center(
                              child: SizedBox(
                                width: IsrDimens.twenty,
                                height: IsrDimens.twenty,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            )
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
                                          final success =
                                              await widget.onPressReport!(message: '', reason: selectedReason ?? '');
                                          if (success && context.mounted) {
                                            Navigator.pop(context);
                                          }
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
            ),
          ),
        ),
      );
}
