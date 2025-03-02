import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class MoreOptionsBottomSheet extends StatefulWidget {
  const MoreOptionsBottomSheet({
    super.key,
    this.onPressReport,
  });

  final Future<bool> Function({String message, String reason})? onPressReport;

  @override
  State<MoreOptionsBottomSheet> createState() => _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState extends State<MoreOptionsBottomSheet> {
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
          style: Styles.primaryText14,
        ),
        value: title,
        groupValue: selectedReason,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        contentPadding: Dimens.edgeInsetsSymmetric(
          horizontal: Dimens.sixteen,
          vertical: Dimens.four,
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
                      TranslationFile.report,
                      style: Styles.primaryText18.copyWith(
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
                        InjectionUtils.getBloc<HomeBloc>().add(GetReasonEvent(
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
                        Utility.showToastMessage(
                          TranslationFile.failedToLoadReportReasons,
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    titleAlignment: ListTileTitleAlignment.center,
                    title: Text(
                      TranslationFile.cancel,
                      style: Styles.primaryText18.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ] else ...[
                  // Report reasons dialog
                  Padding(
                    padding: Dimens.edgeInsets(
                      left: Dimens.sixteen,
                      top: Dimens.sixteen,
                      bottom: Dimens.eight,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TranslationFile.report,
                          style: Styles.primaryText18.copyWith(
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
                      padding: Dimens.edgeInsetsAll(Dimens.twentyFour),
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
                      padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                      child: isReportLoading
                          ? Center(
                              child: SizedBox(
                                width: Dimens.twenty,
                                height: Dimens.twenty,
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
                                title: TranslationFile.confirm.toUpperCase(),
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
