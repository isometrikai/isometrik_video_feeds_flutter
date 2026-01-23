import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class ReportReasonDialog extends StatefulWidget {
  const ReportReasonDialog({
    Key? key,
    required this.reasonFor,
    required this.contentId,
    this.showToastOnSuccess = true,
    this.onReportSuccess,
    this.onReportInvoked,
    this.onReportCanceled,
  }) : super(key: key);

  final Function(ReportReason)? onReportSuccess;
  final Function(ReportReason)? onReportInvoked;
  final Function(ReportReason)? onReportCanceled;
  final String contentId;
  final ReasonsFor reasonFor;
  final bool showToastOnSuccess;

  @override
  State<ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<ReportReasonDialog> {
  ReportReason? _selectedReason;
  bool _isLoading = true;
  final _socialPostBloc = IsmInjectionUtils.getBloc<SocialPostBloc>();
  final List<ReportReason> _reportReasons = [];

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    setState(() => _isLoading = true);
    _socialPostBloc.add(
      GetReasonEvent(
        onComplete: (reasons) {
          setState(() {
            _reportReasons.clear();
            _reportReasons.addAll(reasons as Iterable<ReportReason>);
            _isLoading = false;
          });
        },
        reasonsFor: widget.reasonFor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: 50.percentHeight),
          padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
          margin: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
          decoration: BoxDecoration(
            color: IsrColors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(IsrDimens.twenty),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row - fixed at top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    IsrTranslationFile.report,
                    style: IsrStyles.primaryText18.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  TapHandler(
                    padding: 5.responsiveDimension,
                    onTap: () {
                      context.pop();
                    },
                    child: AppImage.svg(
                      AssetConstants.icCrossIcon,
                      height: IsrDimens.sixteen,
                      width: IsrDimens.sixteen,
                      color: IsrColors.black,
                    ),
                  ),
                ],
              ),
              24.responsiveVerticalSpace,
              // Scrollable content - wrapped in Flexible to prevent overflow
              Flexible(
                child: _isLoading
                    ? Center(child: Utility.loaderWidget())
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header and reasons list
                            ...List.generate(
                              _reportReasons.length,
                              (index) => Padding(
                                padding: IsrDimens.edgeInsets(
                                    bottom: IsrDimens.twelve),
                                child: TapHandler(
                                  onTap: () {
                                    setState(() {
                                      _selectedReason = _reportReasons[index];
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24.responsiveDimension,
                                        height: 24.responsiveDimension,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _selectedReason ==
                                                    _reportReasons[index]
                                                ? Theme.of(context).primaryColor
                                                : '838383'.toColor(),
                                            width: 2.responsiveDimension,
                                          ),
                                        ),
                                        child: _selectedReason ==
                                                _reportReasons[index]
                                            ? Center(
                                                child: Container(
                                                  width: 12.responsiveDimension,
                                                  height:
                                                      12.responsiveDimension,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                      12.responsiveHorizontalSpace,
                                      Expanded(
                                        child: Text(
                                          _reportReasons[index].name ?? '',
                                          style: IsrStyles.primaryText14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              // Button section - fixed at bottom
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  24.responsiveVerticalSpace,
                  AppButton(
                    title: IsrTranslationFile.confirm,
                    onPress: _selectedReason == null
                        ? null
                        : () async {
                            Navigator.pop(context, true);
                            final confirmation = await _showReportPostDialog(
                              context,
                              _selectedReason?.type ??
                                  widget.reasonFor.reasonsForString,
                            );
                            if (confirmation == true) {
                              widget.onReportInvoked?.call(_selectedReason!);
                              _socialPostBloc.add(ReportEvent(
                                contentId: widget.contentId,
                                reportReason: _selectedReason!,
                                showToastOnSuccess: widget.showToastOnSuccess,
                                onComplete: (success) {
                                  widget.onReportSuccess
                                      ?.call(_selectedReason!);
                                },
                              ));
                            } else {
                              widget.onReportCanceled?.call(_selectedReason!);
                            }
                          },
                    isDisable: _selectedReason == null,
                    textColor: IsrColors.white,
                  ),
                  MediaQuery.of(context).padding.bottom.responsiveVerticalSpace,
                ],
              ),
            ],
          ),
        ),
      );

  Future<bool?> _showReportPostDialog(BuildContext context, String type) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: IsrVideoReelConfig
              .socialConfig.dialogConfig?.backgroundColor ?? Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.reportAlertTitle(type),
                  style: IsrVideoReelConfig
                          .socialConfig.dialogConfig?.titleTextStyle ??
                      IsrStyles.primaryText18
                          .copyWith(fontWeight: FontWeight.w700),
                ),
                16.responsiveVerticalSpace,
                Text(
                  IsrTranslationFile.reportConfirmation(type),
                  style: IsrVideoReelConfig
                          .socialConfig.dialogConfig?.titleTextStyle ??
                      IsrStyles.primaryText14.copyWith(
                        color: '4A4A4A'.toColor(),
                      ),
                ),
                32.responsiveVerticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDialogButton(
                      context: context,
                      title: IsrTranslationFile.report,
                      buttonConfig: IsrVideoReelConfig.socialConfig.primaryButton,
                      onPress: () => Navigator.of(context).pop(true),
                      defaultBackgroundColor: 'E04755'.toColor(),
                    ),
                    _buildDialogButton(
                      context: context,
                      title: IsrTranslationFile.cancel,
                      buttonConfig: IsrVideoReelConfig.socialConfig.secondaryButton,
                      buttonType: ButtonType.secondary,
                      onPress: () => Navigator.of(context).pop(false),
                      defaultBackgroundColor: 'F6F6F6'.toColor(),
                      defaultTextColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDialogButton({
    required BuildContext context,
    required String title,
    ButtonConfig? buttonConfig,
    ButtonType buttonType = ButtonType.primary,
    required VoidCallback? onPress,
    Color? defaultBackgroundColor,
    Color? defaultTextColor,
  }) => AppButton(
      title: title,
      width: 102.responsiveDimension,
      type: buttonType,
      onPress: onPress,
      backgroundColor: buttonConfig?.backgroundColor ?? defaultBackgroundColor,
      textColor: buttonConfig?.textColor ?? defaultTextColor,
      borderColor: buttonConfig?.borderColor,
      borderRadius: buttonConfig?.borderRadius,
    );
}
