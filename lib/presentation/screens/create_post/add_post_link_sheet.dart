import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Bottom sheet to add or edit a post link (`tags.links`).
class AddPostLinkSheet extends StatefulWidget {
  const AddPostLinkSheet({
    super.key,
    this.initialLink,
  });

  final PostLinkData? initialLink;

  static Future<PostLinkData?> show(
    BuildContext context, {
    PostLinkData? initialLink,
  }) =>
      showModalBottomSheet<PostLinkData?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddPostLinkSheet(initialLink: initialLink),
      );

  @override
  State<AddPostLinkSheet> createState() => _AddPostLinkSheetState();
}

class _AddPostLinkSheetState extends State<AddPostLinkSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  String? _urlError;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialLink?.url ?? '');
    _titleController =
        TextEditingController(text: widget.initialLink?.title ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool _isValidHttpsUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    return uri != null && uri.scheme == 'https';
  }

  void _save() {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    setState(() {
      _urlError = url.isEmpty
          ? IsrTranslationFile.enterLinkUrl
          : (!_isValidHttpsUrl(url)
              ? IsrTranslationFile.enterValidHttpsLinkUrl
              : null);
      _titleError =
          title.isEmpty ? IsrTranslationFile.enterButtonLabel : null;
    });
    if (_urlError != null || _titleError != null) return;
    final link = PostLinkData.forCreate(url: url, title: title);
    if (!link.isValid) return;
    Navigator.pop(context, link);
  }

  void _removeLink() => Navigator.pop(
        context,
        const PostLinkData(url: '', title: ''),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetColor = IsrVideoReelConfig
            .socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
        IsrColors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.responsiveDimension),
          ),
        ),
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: 20.responsiveDimension,
          vertical: 16.responsiveDimension,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      IsrTranslationFile.addLink,
                      style: IsrStyles.primaryText16
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              8.verticalSpace,
              Text(
                IsrTranslationFile.addLinkDescription,
                style: IsrStyles.primaryText12.copyWith(color: IsrColors.grey),
              ),
              16.verticalSpace,
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: IsrTranslationFile.linkUrl,
                  hintText: 'https://example.com',
                  errorText: _urlError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              12.verticalSpace,
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: InputDecoration(
                  labelText: IsrTranslationFile.linkTitle,
                  hintText: IsrTranslationFile.linkTitleHint,
                  errorText: _titleError,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              20.verticalSpace,
              AppButton(
                title: IsrTranslationFile.save,
                onPress: _save,
              ),
              if (widget.initialLink?.isValid == true) ...[
                8.verticalSpace,
                TextButton(
                  onPressed: _removeLink,
                  child: Text(
                    IsrTranslationFile.removeLink,
                    style: IsrStyles.primaryText14.copyWith(
                      color: IsrColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
