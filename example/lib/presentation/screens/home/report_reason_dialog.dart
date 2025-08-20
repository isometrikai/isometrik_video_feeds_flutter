import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class ReportReasonDialog extends StatefulWidget {
  const ReportReasonDialog({
    Key? key,
    required this.onConfirm,
  }) : super(key: key);

  final Function(String) onConfirm;

  @override
  State<ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<ReportReasonDialog> {
  String _selectedReason = '';
  bool _isLoading = true;
  final _homeBloc = InjectionUtils.getBloc<HomeBloc>();
  final List<String> _reportReasons = [];

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    setState(() => _isLoading = true);
    _homeBloc.add(
      GetReasonEvent(
        onComplete: (reasons) {
          setState(() {
            _reportReasons.clear();
            _reportReasons.addAll(reasons as Iterable<String>);
            _isLoading = false;
          });
        },
        reasonsFor: ReasonsFor.comment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: Dimens.edgeInsetsAll(Dimens.sixteen),
        margin: Dimens.edgeInsetsAll(Dimens.sixteen),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(Dimens.twenty)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TranslationFile.report,
                    style: Styles.primaryText18.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TapHandler(
                    padding: 5.scaledValue,
                    onTap: () => context.pop(),
                    child: AppImage.svg(
                      AssetConstants.icCrossIcon,
                      height: Dimens.sixteen,
                      width: Dimens.sixteen,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              24.verticalSpace,
              if (_isLoading)
                Expanded(child: Center(child: Utility.loaderWidget()))
              else
                ...List.generate(
                  _reportReasons.length,
                  (index) => Padding(
                    padding: Dimens.edgeInsets(bottom: Dimens.twelve),
                    child: _buildReasonTile(_reportReasons[index]),
                  ),
                ),
              24.verticalSpace,
              AppButton(
                title: TranslationFile.confirm,
                onPress: _selectedReason.isEmpty
                    ? null
                    : () {
                        widget.onConfirm(_selectedReason);
                        Navigator.pop(context);
                      },
                isDisable: _selectedReason.isEmpty,
                textColor: AppColors.white,
              ),
              MediaQuery.of(context).padding.bottom.verticalSpace,
            ],
          ),
        ),
      );

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;

    return TapHandler(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      child: Row(
        children: [
          // Custom Radio Circle
          Container(
            width: 24.scaledValue,
            height: 24.scaledValue,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : '838383'.toHexColor,
                width: 2.scaledValue,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12.scaledValue,
                      height: 12.scaledValue,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          12.horizontalSpace,
          // Reason text
          Expanded(
            child: Text(
              reason,
              style: Styles.primaryText14,
            ),
          ),
        ],
      ),
    );
  }
}
