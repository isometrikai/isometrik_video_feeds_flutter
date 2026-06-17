import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const CreateTextPostView({super.key});

  /// Character limits, mirroring the backend config:
  /// `{ plain_text_post_limit: 5000, formatted_text_card_limit: 500,
  ///    recommended_card_limit: 250 }`.
  static const int plainLimit = 5000;
  static const int cardLimit = 500;
  static const int recommendedCardLimit = 250;

  /// Plain-post formatting defaults. These mirror the SDK's text-post renderer
  /// (`TextPostFormatting` uses [GoogleFonts] so the family must be a Google
  /// font) so the composer is WYSIWYG with the feed.
  static const String fontFamily = 'Roboto';
  static const int fontSize = 17;
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
  final _controller = TextEditingController();
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

  CreatePostBloc get _createPostBloc =>
      IsmInjectionUtils.getBloc<CreatePostBloc>();

  bool get _useBackgroundPostUi =>
      IsrVideoReelConfig.createEditPostConfig.createEditPostCallBackConfig
          ?.onBackgroundPostOperation !=
      null;

  bool get _canPost => _controller.text.trim().isNotEmpty && !_isPosting;

  int get _currentLimit =>
      _isCard ? CreateTextPostView.cardLimit : CreateTextPostView.plainLimit;

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
    // Reset any stale state left on the shared (singleton) create-post bloc.
    _createPostBloc.add(CreatePostInitialEvent());
    _controller.addListener(_onTextChanged);
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
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
      if (card && _controller.text.length > CreateTextPostView.cardLimit) {
        final trimmed =
            _controller.text.substring(0, CreateTextPostView.cardLimit);
        _controller.value = TextEditingValue(
          text: trimmed,
          selection: TextSelection.collapsed(offset: trimmed.length),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onPost() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;
    _focusNode.unfocus();
    setState(() => _isPosting = true);

    final textFormatting = <String, dynamic>{
      'text': text,
      'font_family': _isCard ? _fontFamily : CreateTextPostView.fontFamily,
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
      visibility: SocialPostVisibility.public,
      textFormatting: textFormatting,
      tags: _taggedPlaces.isEmpty
          ? null
          : Tags(places: List<TaggedPlace>.from(_taggedPlaces)),
    );

    _createPostBloc.add(PostCreateEvent(createPostRequest: request));
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
          IsrVideoReelConfig.socialActionCubit
              .onPostCreated(postId: state.postDataModel?.id);
          _closeComposer(result: state.postDataModel);
        }
      },
      child: Scaffold(
        backgroundColor: IsrColors.scaffoldColor,
        appBar: AppBar(
          backgroundColor: IsrColors.appBarColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 90,
          leading: Center(
            child: TextButton(
              onPressed: _isPosting ? null : _onCancel,
              child: Text(
                IsrTranslationFile.cancel,
                style: TextStyle(
                  fontSize: 16,
                  color: IsrColors.primaryTextColor,
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _PostButton(
                enabled: _canPost,
                isLoading: _isPosting,
                onPressed: _onPost,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: dividerColor),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
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
              Container(height: 1, color: dividerColor),
              _buildComposerToolbar(),
              if (_isCard) _buildCardToolbar(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainEditor() => Row(
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
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLines: null,
              maxLength: CreateTextPostView.plainLimit,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textAlign: TextAlign.left,
              cursorColor: IsrColors.appColor,
              inputFormatters: [
                LengthLimitingTextInputFormatter(CreateTextPostView.plainLimit),
              ],
              style: GoogleFonts.getFont(
                CreateTextPostView.fontFamily,
                fontSize: CreateTextPostView.fontSize.toDouble(),
                height: 1.35,
                color: IsrColors.primaryTextColor,
              ),
              buildCounter: _emptyCounter,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: IsrTranslationFile.whatsHappening,
                hintStyle: GoogleFonts.getFont(
                  CreateTextPostView.fontFamily,
                  fontSize: CreateTextPostView.fontSize.toDouble(),
                  height: 1.35,
                  color: IsrColors.secondaryTextColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      );

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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: IsrColors.primaryTextColor,
                ),
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
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLines: null,
              maxLength: CreateTextPostView.cardLimit,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              textAlign: fmt.textAlignValue,
              cursorColor: textStyle.color ?? Colors.white,
              inputFormatters: [
                LengthLimitingTextInputFormatter(CreateTextPostView.cardLimit),
              ],
              style: textStyle,
              buildCounter: _emptyCounter,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: IsrTranslationFile.whatsHappening,
                hintStyle: textStyle.copyWith(
                  color: (textStyle.color ?? Colors.white)
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _emptyCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    int? maxLength,
  }) =>
      null;

  Widget _buildComposerToolbar() {
    final hasLocation = _taggedPlaces.isNotEmpty;
    final locationIconColor = _isPosting
        ? IsrColors.secondaryTextColor.withValues(alpha: 0.35)
        : IsrColors.appColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _isPosting ? null : _pickLocation,
            icon: Icon(
              hasLocation ? Icons.location_on : Icons.location_on_outlined,
              color: locationIconColor,
            ),
            tooltip: IsrTranslationFile.addLocation,
          ),
        ],
      ),
    );
  }

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

  Widget _buildBottomBar() {
    final length = _controller.text.length;
    final overRecommended =
        _isCard && length > CreateTextPostView.recommendedCardLimit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
      child: Row(
        children: [
          _ModeToggle(isCard: _isCard, onChanged: _setMode),
          const Spacer(),
          Text(
            '$length/$_currentLimit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: overRecommended ? FontWeight.w600 : FontWeight.w400,
              color: overRecommended
                  ? const Color(0xFFFF9F0A)
                  : IsrColors.secondaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardToolbar() => Container(
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
                  onTap: () => setState(() {
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
                  onTap: () => setState(() => _fontFamily = family),
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
                ? () => setState(() => _fontSize -= 2)
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
                ? () => setState(() => _fontSize += 2)
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
              onTap: () => setState(() => _fontStyle = entry[0] as String),
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
              onTap: () => setState(() => _cardTextAlign = entry[0] as String),
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
                onTap: () => setState(() => _textColor = hex),
              ),
            ),
        ],
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: IsrColors.buttonTextColor,
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

  final bool isCard;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final base = IsrColors.dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(label: IsrTranslationFile.text, selected: !isCard, onTap: () => onChanged(false)),
          _segment(label: IsrTranslationFile.card, selected: isCard, onTap: () => onChanged(true)),
        ],
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? IsrColors.appColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : IsrColors.primaryTextColor,
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
