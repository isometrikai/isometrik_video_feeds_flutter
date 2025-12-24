import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class ReportReasonDialog extends StatefulWidget {
  const ReportReasonDialog({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  final Function(ReportReason) onConfirm;

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
        reasonsFor: ReasonsFor.comment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: 50.percentHeight),
          height: null,
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
              _isLoading
                  ? Center(child: Utility.loaderWidget())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header and reasons list
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                IsrTranslationFile.report,
                                style: IsrStyles.primaryText18.copyWith(
                                  fontWeight: FontWeight.w600,
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
                                                height: 12.responsiveDimension,
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
                                    Text(
                                      _reportReasons[index].name ?? '',
                                      style: IsrStyles.primaryText14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  24.responsiveVerticalSpace,
                  AppButton(
                    title: IsrTranslationFile.confirm,
                    onPress: _selectedReason == null
                        ? null
                        : () {
                            widget.onConfirm(_selectedReason!);
                            Navigator.pop(context);
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
}
