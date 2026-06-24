import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Text post composer (X / Threads style) with two modes:
///
/// * **Plain** – a simple long-form text post (up to [plainLimit] characters),
///   no background / formatting controls.
/// * **Card** – a short, styled "card" post (up to [cardLimit] characters) with
///   a selectable background (gradient/solid), font family, font size, font
///   style, text alignment and text color.
///
/// Reuses the shared [CreatePostBloc] to publish a `text` type post through the
/// SDK create-post pipeline (no media upload step is required for text posts).
class CreateTextPostView extends StatefulWidget {
  const CreateTextPostView({super.key, this.postData});

  /// When set, the composer opens in edit mode for an existing text post.
  final TimeLineData? postData;

  /// Character limits — see [TextPostComposerLimits] for line / blank-line rules.
  static const int plainLimit = TextPostComposerLimits.plainCharLimit;
  static const int cardLimit = TextPostComposerLimits.cardCharLimit;
  static const int recommendedCardLimit = 250;

  /// Plain-post formatting defaults for the composer and feed payload.
  static const int fontSize = 16;
  static const String fontStyle = 'normal';
  static const String textAlign = 'left';

  /// Selectable font families for card posts (must be Google fonts).
  static const List<String> fontFamilies = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Oswald',
    'Playfair Display',
    'Pacifico',
  ];

  /// Selectable text colors for card posts.
  static const List<String> textColors = [
    '#FFFFFF',
    '#000000',
    '#FFD60A',
    '#FF453A',
    '#0A84FF',
    '#30D158',
    '#FF9F0A',
  ];

  static const int minFontSize = 14;
  static const int maxFontSize = 48;

  @override
  State<CreateTextPostView> createState() => _CreateTextPostViewState();
}

/// A selectable background swatch for card posts.
class _BgOption {
  const _BgOption(this.type, this.value, this.defaultTextColor);

  /// `gradient` or `color` (solid).
  final String type;

  /// Gradient palette key (e.g. `charcoal_grey`) or hex color (e.g. `#1C1C1E`).
  final String value;

  /// Text color applied automatically when this background is picked.
  final String defaultTextColor;
}

class _CreateTextPostViewState extends State<CreateTextPostView> {
  late FlutterTaggerController _controller;
  final _focusNode = FocusNode();

  String _avatarUrl = '';
  String _firstName = '';
  String _lastName = '';
  String _userName = '';
  bool _isPosting = false;
  bool _isClosing = false;

  // Composer mode + card formatting state.
  bool _isCard = false;
  String _bgType = 'gradient';
  String _bgValue = 'blue_purple';
  String _textColor = '#FFFFFF';
  String _fontFamily = 'Roboto';
  int _fontSize = 24;
  String _fontStyle = 'normal';
  String _cardTextAlign = 'center';
  final List<TaggedPlace> _taggedPlaces = [];
  final List<MentionData> _mentionedUsers = [];

  CreatePostBloc get _createPostBloc =>
      IsmInjectionUtils.getBloc<CreatePostBloc>();

  bool get _useBackgroundPostUi =>
      IsrVideoReelConfig.createEditPostConfig.createEditPostCallBackConfig
          ?.onBackgroundPostOperation !=
      null;

  bool get _isEditMode => widget.postData != null;

  bool get _canPost {
    if (_controller.text.trim().isEmpty || _isPosting) return false;
    return TextPostComposerLimits.validate(
      _controller.text,
      isCard: _isCard,
    ).isValid;
  }

  TextPostLimitsConfig get _limits =>
      TextPostComposerLimits.config(isCard: _isCard);

  TextPostValidationResult get _validation =>
      TextPostComposerLimits.validate(_controller.text, isCard: _isCard);

  /// Selectable backgrounds: every gradient from the palette plus a few solids.
  List<_BgOption> get _backgroundOptions => [
        for (final key in TextPostGradientPalette.gradientKeys)
          _BgOption('gradient', key, '#FFFFFF'),
        const _BgOption('color', '#1C1C1E', '#FFFFFF'),
        const _BgOption('color', '#2F80ED', '#FFFFFF'),
        const _BgOption('color', '#EB5757', '#FFFFFF'),
        const _BgOption('color', '#27AE60', '#FFFFFF'),
        const _BgOption('color', '#F2C94C', '#000000'),
        const _BgOption('color', '#FFFFFF', '#000000'),
      ];

  /// Live formatting model used to render the card preview WYSIWYG.
  TextPostFormatting get _cardFormatting => TextPostFormatting(
        text: _controller.text,
        fontFamily: _fontFamily,
        fontSize: _fontSize.toDouble(),
        fontStyle: _fontStyle,
        textAlign: _cardTextAlign,
        backgroundType: _bgType,
        backgroundValue: _bgValue,
        textColor: _textColor,
      );

  @override
  void initState() {
    super.initState();
    _controller = FlutterTaggerController();
    if (_isEditMode) {
      _createPostBloc.add(EditPostEvent(postData: widget.postData!));
      _hydrateFromPost(widget.postData!);
    } else {
      // Reset any stale state left on the shared (singleton) create-post bloc.
      _createPostBloc.add(CreatePostInitialEvent());
    }
    _controller.addListener(_onTextChanged);
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _hydrateFromPost(TimeLineData post) {
    final formatting = TextPostFormatting.fromTimeline(post);
    final text = formatting.text;
    _isCard = formatting.hasBackground;
    if (_isCard) {
      _bgType = formatting.backgroundType.isNotEmpty
          ? formatting.backgroundType
          : 'gradient';
      _bgValue = formatting.backgroundValue.isNotEmpty
          ? formatting.backgroundValue
          : 'blue_purple';
      _textColor = formatting.textColor;
      _fontFamily = formatting.fontFamily;
      _fontSize = formatting.fontSize
          .round()
          .clamp(CreateTextPostView.minFontSize, CreateTextPostView.maxFontSize);
      _fontStyle = formatting.fontStyle;
      _cardTextAlign = formatting.textAlign;
    }
    final places = post.tags?.places;
    if (places != null && places.isNotEmpty) {
      _taggedPlaces
        ..clear()
        ..addAll(places);
    }
    final mentions = post.tags?.mentions;
    if (mentions != null && mentions.isNotEmpty) {
      _mentionedUsers
        ..clear()
        ..addAll(mentions);
    }
    if (text.contains('@') || text.contains('#')) {
      _controller.dispose();
      _controller = FlutterTaggerController(text: text);
      CommentTaggingTextField.applyPlainTextTagHighlights(_controller);
    } else {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final localData = IsmInjectionUtils.getUseCase<IsmLocalDataUseCase>();
      final url = await localData.getProfilePic();
      final firstName = await localData.getFirstName();
      final lastName = await localData.getLastName();
      final userName = await localData.getUserName();
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _firstName = firstName;
        _lastName = lastName;
        _userName = userName;
      });
    } catch (_) {
      // Profile data is best-effort; fall back to a blank placeholder.
    }
  }

  void _onTextChanged() => setState(() {});

  void _dismissKeyboard() {
    if (!_focusNode.hasFocus) return;
    _focusNode.unfocus();
  }

  /// Runs a card-formatting action after hiding the keyboard so the toolbar stays usable.
  void _runCardControl(VoidCallback action) {
    _dismissKeyboard();
    setState(action);
  }

  void _onCancel() {
    _focusNode.unfocus();
    Navigator.of(context).maybePop();
  }

  /// Switches between plain and card composer modes. When entering card mode the
  /// text is trimmed to the (smaller) card limit so the body stays valid.
  void _setMode(bool card) {
    if (_isCard == card) return;
    setState(() {
      _isCard = card;
      if (card) {
        final sanitized = TextPostComposerLimits.sanitize(
          _controller.text,
          isCard: true,
        );
        if (sanitized != _controller.text) {
          _controller.value = TextEditingValue(
            text: sanitized,
            selection: TextSelection.collapsed(offset: sanitized.length),
          );
        }
      }
    });
    if (card) {
      _dismissKeyboard();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onPost() {
    final validation = _validation;
    if (!validation.isValid) {
      _showValidationMessage(validation);
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;
    _focusNode.unfocus();
    setState(() => _isPosting = true);

    final textFormatting = <String, dynamic>{
      'text': text,
      'font_family': _isCard ? _fontFamily : AppConstants.primaryFontFamily,
      'font_size': _isCard ? _fontSize : CreateTextPostView.fontSize,
      'font_style': _isCard ? _fontStyle : CreateTextPostView.fontStyle,
      'text_align': _isCard ? _cardTextAlign : CreateTextPostView.textAlign,
    };
    if (_isCard) {
      textFormatting['background'] = {
        'type': _bgType,
        'value': _bgValue,
        'text_color': _textColor,
      };
    }

    final request = CreatePostRequest(
      type: SocialPostType.text,
      visibility: widget.postData?.visibility ?? SocialPostVisibility.public,
      textFormatting: textFormatting,
      tags: _buildPostTags(),
    );

    _createPostBloc.add(
      PostCreateEvent(
        isForEdit: _isEditMode,
        createPostRequest: request,
      ),
    );
  }

  Tags? _buildPostTags() {
    if (_taggedPlaces.isEmpty && _mentionedUsers.isEmpty) return null;
    return Tags(
      places: _taggedPlaces.isEmpty
          ? null
          : List<TaggedPlace>.from(_taggedPlaces),
      mentions: _mentionedUsers.isEmpty
          ? null
          : List<MentionData>.from(_mentionedUsers),
    );
  }

  MentionData _mentionDataFromComment(CommentMentionData c) => MentionData(
        userId: c.userId,
        username: c.username,
        tag: c.tag,
        name: c.name,
        avatarUrl: c.avatarUrl,
        textPosition: c.textPosition == null
            ? null
            : TaggedPosition(
                start: c.textPosition!.start,
                end: c.textPosition!.end,
              ),
      );

  void _insertMentionTrigger() {
    if (_isPosting) return;
    final text = _controller.text;
    final selection = _controller.selection;
    final offset = selection.isValid ? selection.baseOffset : text.length;
    final safeOffset = offset.clamp(0, text.length);
    final needsLeadingSpace = safeOffset > 0 &&
        !RegExp(r'\s').hasMatch(text[safeOffset - 1]);
    final insertion = needsLeadingSpace ? ' @' : '@';
    final newText =
        text.substring(0, safeOffset) + insertion + text.substring(safeOffset);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: safeOffset + insertion.length),
    );
    _focusNode.requestFocus();
  }

  void _onMentionAdded(CommentMentionData mentionData) {
    final md = _mentionDataFromComment(mentionData);
    if (!_mentionedUsers.any((u) => u.userId == md.userId)) {
      setState(() => _mentionedUsers.add(md));
    }
  }

  void _onMentionRemoved(CommentMentionData mentionData) {
    final md = _mentionDataFromComment(mentionData);
    setState(() => _mentionedUsers.removeWhere((u) => u.userId == md.userId));
  }

  TextStyle get _plainTextStyle => TextStyle(
        fontFamily: AppConstants.primaryFontFamily,
        fontSize: CreateTextPostView.fontSize.toDouble(),
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: IsrColors.primaryTextColor,
      );

  TextStyle get _plainHintStyle => TextStyle(
        fontFamily: AppConstants.primaryFontFamily,
        fontSize: CreateTextPostView.fontSize.toDouble(),
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: IsrColors.secondaryTextColor.withValues(alpha: 0.6),
      );

  TextStyle get _usernameStyle => TextStyle(
        fontFamily: AppConstants.primaryFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: IsrColors.primaryTextColor,
      );

  TextStyle get _plainMentionStyle => _plainTextStyle.copyWith(
        color: IsrColors.appColor,
        fontWeight: FontWeight.w600,
      );

  InputDecoration get _plainInputDecoration => InputDecoration(
        isCollapsed: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        counterText: '',
        hintText: IsrTranslationFile.whatsHappening,
        hintStyle: _plainHintStyle,
      );

  Widget _buildTaggingTextField({
    required TextStyle style,
    required TextStyle hintStyle,
    TextStyle? mentionStyle,
    TextAlign textAlign = TextAlign.start,
  }) =>
      CommentTaggingTextField(
        controller: _controller,
        focusNode: _focusNode,
        autoFocus: true,
        maxLines: null,
        maxLength: _limits.charLimit,
        inlineSuggestionsBelow: true,
        wrapFieldInScrollView: false,
        enableSuggestions: true,
        minSearchQueryLength: 2,
        textAlign: textAlign,
        textStyle: style,
        userTagTextStyle: mentionStyle ?? _plainMentionStyle,
        hintStyle: hintStyle,
        decoration: _plainInputDecoration.copyWith(hintStyle: hintStyle),
        onChanged: (_) => setState(() {}),
        buildCounter: _hiddenLengthCounter,
        onAddMentionData: _onMentionAdded,
        onRemoveMentionData: _onMentionRemoved,
      );

  Widget? _hiddenLengthCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    int? maxLength,
  }) =>
      null;

  void _showValidationMessage(TextPostValidationResult validation) {
    final limit = validation.limit;
    if (limit == null || validation.issue == null) return;
    final message = switch (validation.issue!) {
      TextPostValidationIssue.tooManyCharacters =>
        IsrTranslationFile.textPostCharacterLimitReached.replaceAll(
          '%s',
          '$limit',
        ),
      TextPostValidationIssue.tooManyLines =>
        IsrTranslationFile.textPostLineLimitReached.replaceAll('%s', '$limit'),
      TextPostValidationIssue.tooManyBlankLines =>
        IsrTranslationFile.textPostBlankLineLimitReached.replaceAll(
          '%s',
          '$limit',
        ),
    };
    Utility.showToastMessage(message);
  }

  Future<void> _pickLocation() async {
    if (_isPosting) return;
    _focusNode.unfocus();
    final result = await IsrAppNavigator.goToSearchLocation(
      context,
      taggedPlaceList: List<TaggedPlace>.from(_taggedPlaces),
    );
    if (!mounted || result == null) return;
    setState(() {
      _taggedPlaces
        ..clear()
        ..addAll(result);
    });
  }

  void _removeLocation() {
    if (_taggedPlaces.isEmpty) return;
    setState(_taggedPlaces.clear);
  }

  TaggedPlace? get _selectedPlace =>
      _taggedPlaces.isEmpty ? null : _taggedPlaces.first;

  String _locationLabel(TaggedPlace place) {
    final name = place.placeName?.trim() ?? '';
    final city = place.city?.trim() ?? '';
    if (name.isEmpty) return city;
    if (city.isEmpty || name == city) return name;
    return '$name, $city';
  }

  /// Pops the composer exactly once, after the current frame, to avoid
  /// removing screens beneath it (e.g. when the bloc emits both the dismiss
  /// and created states back-to-back for an instant text post).
  void _closeComposer({Object? result}) {
    if (_isClosing) return;
    _isClosing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = IsrColors.dividerColor;
    return BlocListener<CreatePostBloc, CreatePostState>(
      bloc: _createPostBloc,
      listenWhen: (_, current) =>
          current is PostCreatedState ||
          current is DismissCreatePostFlowForBackgroundState,
      listener: (context, state) {
        if (_useBackgroundPostUi) {
          // In background mode the bloc fires onPostCreated + the upload overlay
          // itself; the composer only needs to step out of the way once.
          if (state is DismissCreatePostFlowForBackgroundState) {
            _closeComposer();
          }
          return;
        }
        if (state is PostCreatedState) {
          if (_isEditMode) {
            IsrVideoReelConfig.socialActionCubit.onPostEdited(
              postId: state.postDataModel?.id ?? widget.postData?.id,
              postData: state.postDataModel,
            );
          } else {
            IsrVideoReelConfig.socialActionCubit
                .onPostCreated(postId: state.postDataModel?.id);
          }
          _closeComposer(result: state.postDataModel);
        }
      },
      child: Scaffold(
        backgroundColor: IsrColors.scaffoldColor,
        appBar: AppBar(
          backgroundColor: IsrColors.scaffoldColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 90,
          toolbarHeight: 44,
          leading: Center(
            child: SizedBox(
              height: 26,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _isPosting ? null : _onCancel,
                child: Text(
                  IsrTranslationFile.cancel,
                  style: TextStyle(
                    fontFamily: AppConstants.primaryFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: IsrColors.primaryTextColor,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  height: 26,
                  child: _PostButton(
                    enabled: _canPost,
                    isLoading: _isPosting,
                    onPressed: _onPost,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _dismissKeyboard,
                  behavior: HitTestBehavior.translucent,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isCard ? _buildCardEditor() : _buildPlainEditor(),
                        if (_taggedPlaces.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildLocationChip(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: dividerColor),
              if (_isCard) _buildCardToolbar(),
              _buildBottomBar(),
              // Scaffold already shrinks the body above the keyboard — pin Done
              // to the column bottom (do not offset by viewInsets again).
              if (MediaQuery.viewInsetsOf(context).bottom > 0)
                _buildKeyboardAccessoryBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainEditor() {
    final fullName = '$_firstName $_lastName'.trim();
    final displayName = _userName.isNotEmpty ? _userName : fullName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          url: _avatarUrl,
          firstName: _firstName,
          lastName: _lastName,
          userName: _userName,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayName.isNotEmpty)
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _usernameStyle,
                ),
              if (displayName.isNotEmpty) const SizedBox(height: 8),
              _buildTaggingTextField(
                style: _plainTextStyle,
                hintStyle: _plainHintStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardEditor() {
    final fmt = _cardFormatting;
    final gradient = fmt.backgroundGradient;
    final textStyle = fmt.buildTextStyle();
    final fullName = '$_firstName $_lastName'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Avatar(
              url: _avatarUrl,
              firstName: _firstName,
              lastName: _lastName,
              userName: _userName,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _userName.isNotEmpty ? _userName : fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _usernameStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 300),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? fmt.fallbackBackgroundColor : null,
            ),
            child: SizedBox(
              width: double.infinity,
              child: _buildTaggingTextField(
                style: textStyle,
                hintStyle: textStyle.copyWith(
                  color:
                      (textStyle.color ?? Colors.white).withValues(alpha: 0.55),
                ),
                mentionStyle: textStyle,
                textAlign: fmt.textAlignValue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final length = _controller.text.length;
    final limits = _limits;
    final overRecommended =
        _isCard && length > CreateTextPostView.recommendedCardLimit;
    final nearCharLimit = length >= limits.charLimit - 100;
    final hasLocation = _taggedPlaces.isNotEmpty;
    final iconColor = _isPosting
        ? IsrColors.secondaryTextColor.withValues(alpha: 0.35)
        : IsrColors.primaryTextColor;
    final activeIconColor = _isPosting
        ? IsrColors.secondaryTextColor.withValues(alpha: 0.35)
        : IsrColors.appColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
      child: Row(
        children: [
          _ModeToggle(isCard: _isCard, onChanged: _setMode),
          const SizedBox(width: 8),
          _ComposerActionIcon(
            asset: AssetConstants.icPostLocation,
            color: hasLocation ? activeIconColor : iconColor,
            onPressed: _isPosting ? null : _pickLocation,
            tooltip: IsrTranslationFile.addLocation,
          ),
          _ComposerActionIcon(
            asset: AssetConstants.icTagUser,
            color: iconColor,
            onPressed: _isPosting ? null : _insertMentionTrigger,
            tooltip: IsrTranslationFile.tagPeople,
          ),
          const Spacer(),
          Text(
            '$length/${limits.charLimit}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  overRecommended || nearCharLimit ? FontWeight.w600 : FontWeight.w400,
              color: overRecommended || nearCharLimit
                  ? const Color(0xFFFF9F0A)
                  : IsrColors.secondaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardAccessoryBar() => Material(
        elevation: 2,
        color: IsrColors.appBarColor,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: IsrColors.dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: _dismissKeyboard,
                child: Text(
                  IsrTranslationFile.done,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IsrColors.appColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLocationChip() {
    final place = _selectedPlace;
    if (place == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: IsrColors.appColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IsrColors.appColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 16, color: IsrColors.appColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _locationLabel(place),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: IsrColors.appColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isPosting ? null : _removeLocation,
            child: Icon(
              Icons.close,
              size: 16,
              color: IsrColors.appColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardToolbar() => GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: Container(
        color: IsrColors.appBarColor,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackgroundRow(),
            const SizedBox(height: 12),
            _buildFontFamilyRow(),
            const SizedBox(height: 12),
            _buildControlsRow(),
          ],
        ),
      ),
      );

  Widget _buildBackgroundRow() => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final opt in _backgroundOptions)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _BackgroundSwatch(
                  option: opt,
                  selected: _bgType == opt.type && _bgValue == opt.value,
                  onTap: () => _runCardControl(() {
                    _bgType = opt.type;
                    _bgValue = opt.value;
                    _textColor = opt.defaultTextColor;
                  }),
                ),
              ),
          ],
        ),
      );

  Widget _buildFontFamilyRow() => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final family in CreateTextPostView.fontFamilies)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  selected: _fontFamily == family,
                  onTap: () => _runCardControl(() => _fontFamily = family),
                  child: Text(
                    family,
                    style: GoogleFonts.getFont(
                      family,
                      fontSize: 14,
                      color: _fontFamily == family
                          ? IsrColors.appColor
                          : IsrColors.primaryTextColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildControlsRow() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildFontSizeStepper(),
            const SizedBox(width: 10),
            _buildStyleSelector(),
            const SizedBox(width: 10),
            _buildAlignSelector(),
            const SizedBox(width: 10),
            _buildTextColorRow(),
          ],
        ),
      );

  Widget _buildFontSizeStepper() => _ControlGroup(
        children: [
          _IconBtn(
            icon: Icons.remove,
            onTap: _fontSize > CreateTextPostView.minFontSize
                ? () => _runCardControl(() => _fontSize -= 2)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$_fontSize',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: IsrColors.primaryTextColor,
              ),
            ),
          ),
          _IconBtn(
            icon: Icons.add,
            onTap: _fontSize < CreateTextPostView.maxFontSize
                ? () => _runCardControl(() => _fontSize += 2)
                : null,
          ),
        ],
      );

  Widget _buildStyleSelector() => _ControlGroup(
        children: [
          for (final entry in const [
            ['normal', 'Aa', FontWeight.normal, FontStyle.normal],
            ['bold', 'B', FontWeight.bold, FontStyle.normal],
            ['italic', 'I', FontWeight.normal, FontStyle.italic],
          ])
            _SegItem(
              selected: _fontStyle == entry[0],
              onTap: () => _runCardControl(() => _fontStyle = entry[0] as String),
              child: Text(
                entry[1] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: entry[2] as FontWeight,
                  fontStyle: entry[3] as FontStyle,
                  color: _fontStyle == entry[0]
                      ? IsrColors.appColor
                      : IsrColors.primaryTextColor,
                ),
              ),
            ),
        ],
      );

  Widget _buildAlignSelector() => _ControlGroup(
        children: [
          for (final entry in const [
            ['left', Icons.format_align_left],
            ['center', Icons.format_align_center],
            ['right', Icons.format_align_right],
          ])
            _SegItem(
              selected: _cardTextAlign == entry[0],
              onTap: () =>
                  _runCardControl(() => _cardTextAlign = entry[0] as String),
              child: Icon(
                entry[1] as IconData,
                size: 18,
                color: _cardTextAlign == entry[0]
                    ? IsrColors.appColor
                    : IsrColors.primaryTextColor,
              ),
            ),
        ],
      );

  Widget _buildTextColorRow() => Row(
        children: [
          for (final hex in CreateTextPostView.textColors)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ColorDot(
                hex: hex,
                selected: _textColor.toUpperCase() == hex.toUpperCase(),
                onTap: () => _runCardControl(() => _textColor = hex),
              ),
            ),
        ],
      );
}

class _ComposerActionIcon extends StatelessWidget {
  const _ComposerActionIcon({
    required this.asset,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  final String asset;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: AppImage.svg(
          asset,
          width: 24,
          height: 24,
          color: color,
        ),
      );
}

class _PostButton extends StatelessWidget {
  const _PostButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled
        ? IsrColors.buttonBackgroundColor
        : IsrColors.buttonDisabledBackgroundColor;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        IsrColors.buttonTextColor,
                      ),
                    ),
                  )
                : Text(
                    IsrTranslationFile.post,
                    style: TextStyle(
                      fontFamily: AppConstants.primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: IsrColors.buttonTextColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.firstName,
    required this.lastName,
    required this.userName,
  });

  final String url;
  final String firstName;
  final String lastName;
  final String userName;

  static const double _size = 44;

  /// Same initials logic as the feed (first + last name), falling back to the
  /// username (e.g. `nikunj_text` -> `NT`) so the avatar is never blank.
  String _resolveInitials() {
    final fromName =
        Utility.getInitials(firstName: firstName, lastName: lastName);
    if (fromName.isNotEmpty) return fromName;
    final tokens = userName
        .trim()
        .split(RegExp(r'[\s_.\-]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return '';
    if (tokens.length == 1) return tokens.first[0].toUpperCase();
    return '${tokens[0][0]}${tokens[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _resolveInitials();
    final fullName = '$firstName $lastName'.trim();
    final seed =
        fullName.isNotEmpty ? fullName : (userName.isNotEmpty ? userName : initials);
    final placeholder = FeedProfileInitialsPlaceholder(
      initials: initials,
      size: _size,
      seed: seed,
    );

    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: url.isEmptyOrNull
            ? placeholder
            : AppImage.network(
                url,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                isProfileImage: true,
                name: fullName.isNotEmpty ? fullName : userName,
                placeHolderWidget: (h, w) => placeholder,
              ),
      ),
    );
  }
}

/// Segmented toggle to switch between plain and card composer modes.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isCard, required this.onChanged});

  static const double _toggleHeight = 32;
  static const double _tapHeight = 44;

  final bool isCard;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tapHeight,
      child: Center(
        child: Container(
          height: _toggleHeight,
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: IsrColors.appColor,
            borderRadius: BorderRadius.circular(_toggleHeight / 2),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(
                label: IsrTranslationFile.text,
                selected: !isCard,
                onTap: () => onChanged(false),
              ),
              _segment(
                label: IsrTranslationFile.card,
                selected: isCard,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: _tapHeight),
          alignment: Alignment.center,
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 28,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1,
                color: selected ? IsrColors.appColor : Colors.white,
              ),
            ),
          ),
        ),
      );
}

/// A circular/rounded swatch previewing a card background option.
class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _BgOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGradient = option.type == 'gradient';
    final gradient = isGradient
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: TextPostGradientPalette.colorsFor(option.value),
          )
        : null;
    final color = isGradient ? null : _parseHex(option.value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? IsrColors.appColor : IsrColors.dividerColor,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Rounded selectable chip used for font families.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? IsrColors.appColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? IsrColors.appColor : IsrColors.dividerColor,
            ),
          ),
          child: child,
        ),
      );
}

/// Pill container grouping segmented controls (size / style / align).
class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IsrColors.dividerColor),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
}

class _SegItem extends StatelessWidget {
  const _SegItem({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          alignment: Alignment.center,
          child: child,
        ),
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 30,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? IsrColors.secondaryTextColor.withValues(alpha: 0.4)
                : IsrColors.primaryTextColor,
          ),
        ),
      );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? IsrColors.appColor : IsrColors.dividerColor,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

Color _parseHex(String raw) {
  var value = raw.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? Colors.black : Color(parsed);
}
