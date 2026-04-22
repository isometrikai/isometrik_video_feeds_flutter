import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection_config.dart';

class CreateEditPostConfig {
  const CreateEditPostConfig({
    this.createEditPostCallBackConfig,
    this.createEditPostUIConfig,
    this.autoMoveToNextPost = true,
  });

  final CreateEditPostCallBackConfig? createEditPostCallBackConfig;
  final CreateEditPostUIConfig? createEditPostUIConfig;
  final bool autoMoveToNextPost;

  CreateEditPostConfig copyWith({
    CreateEditPostCallBackConfig? createEditPostCallBackConfig,
    CreateEditPostUIConfig? createEditPostUIConfig,
    bool? autoMoveToNextPost,
  }) =>
      CreateEditPostConfig(
        createEditPostCallBackConfig:
            createEditPostCallBackConfig ?? this.createEditPostCallBackConfig,
        createEditPostUIConfig:
            createEditPostUIConfig ?? this.createEditPostUIConfig,
        autoMoveToNextPost: autoMoveToNextPost ?? this.autoMoveToNextPost,
      );
}

/// Main UI configuration for create/edit post screens
class CreateEditPostUIConfig {
  const CreateEditPostUIConfig({
    this.mediaSelectionConfig,
    this.mediaEditConfig,
    this.postAttributeUIConfig,
    this.tagPeopleUIConfig,
    this.searchLocationUIConfig,
  });

  /// Configuration for media selection screen
  final MediaSelectionConfig? mediaSelectionConfig;

  /// Configuration for media edit screen
  final MediaEditConfig? mediaEditConfig;

  /// Configuration for post attribute screen
  final PostAttributeUIConfig? postAttributeUIConfig;

  /// Configuration for tag people and search user screens
  final TagPeopleUIConfig? tagPeopleUIConfig;

  /// Configuration for search location screen
  final SearchLocationUIConfig? searchLocationUIConfig;

  CreateEditPostUIConfig copyWith({
    MediaSelectionConfig? mediaSelectionConfig,
    MediaEditConfig? mediaEditConfig,
    PostAttributeUIConfig? postAttributeUIConfig,
    TagPeopleUIConfig? tagPeopleUIConfig,
    SearchLocationUIConfig? searchLocationUIConfig,
  }) =>
      CreateEditPostUIConfig(
        mediaSelectionConfig: mediaSelectionConfig ?? this.mediaSelectionConfig,
        mediaEditConfig: mediaEditConfig ?? this.mediaEditConfig,
        postAttributeUIConfig:
            postAttributeUIConfig ?? this.postAttributeUIConfig,
        tagPeopleUIConfig: tagPeopleUIConfig ?? this.tagPeopleUIConfig,
        searchLocationUIConfig:
            searchLocationUIConfig ?? this.searchLocationUIConfig,
      );
}

/// Configuration for post attribute view
class PostAttributeUIConfig {
  const PostAttributeUIConfig({
    this.appBarConfig,
    this.mediaPreviewConfig,
    this.captionInputConfig,
    this.optionTileConfig,
    this.switchTileConfig,
    this.postButtonConfig,
    this.schedulePostConfig,
  });

  /// App bar configuration
  final AppBarConfig? appBarConfig;

  /// Media preview configuration
  final MediaPreviewConfig? mediaPreviewConfig;

  /// Caption input configuration
  final CaptionInputConfig? captionInputConfig;

  /// Option tile configuration (for link products, tag people, location, etc.)
  final OptionTileConfig? optionTileConfig;

  /// Switch tile configuration (for allow comments, allow save)
  final SwitchTileConfig? switchTileConfig;

  /// Post button configuration
  final PostButtonConfig? postButtonConfig;

  /// Schedule post configuration
  final SchedulePostConfig? schedulePostConfig;

  PostAttributeUIConfig copyWith({
    AppBarConfig? appBarConfig,
    MediaPreviewConfig? mediaPreviewConfig,
    CaptionInputConfig? captionInputConfig,
    OptionTileConfig? optionTileConfig,
    SwitchTileConfig? switchTileConfig,
    PostButtonConfig? postButtonConfig,
    SchedulePostConfig? schedulePostConfig,
  }) =>
      PostAttributeUIConfig(
        appBarConfig: appBarConfig ?? this.appBarConfig,
        mediaPreviewConfig: mediaPreviewConfig ?? this.mediaPreviewConfig,
        captionInputConfig: captionInputConfig ?? this.captionInputConfig,
        optionTileConfig: optionTileConfig ?? this.optionTileConfig,
        switchTileConfig: switchTileConfig ?? this.switchTileConfig,
        postButtonConfig: postButtonConfig ?? this.postButtonConfig,
        schedulePostConfig: schedulePostConfig ?? this.schedulePostConfig,
      );
}

/// App bar configuration for post attribute view
class AppBarConfig {
  const AppBarConfig({
    this.backgroundColor,
    this.titleStyle,
  });

  final Color? backgroundColor;
  final TextStyle? titleStyle;

  AppBarConfig copyWith({
    Color? backgroundColor,
    TextStyle? titleStyle,
  }) =>
      AppBarConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        titleStyle: titleStyle ?? this.titleStyle,
      );
}

/// Media preview configuration
class MediaPreviewConfig {
  const MediaPreviewConfig({
    this.height,
    this.aspectRatio,
    this.borderRadius,
    this.backgroundColor,
    this.changeCoverTextStyle,
    this.changeCoverOverlayColor,
  });

  final double? height;
  final double? aspectRatio;
  final double? borderRadius;
  final Color? backgroundColor;
  final TextStyle? changeCoverTextStyle;
  final Color? changeCoverOverlayColor;

  MediaPreviewConfig copyWith({
    double? height,
    double? aspectRatio,
    double? borderRadius,
    Color? backgroundColor,
    TextStyle? changeCoverTextStyle,
    Color? changeCoverOverlayColor,
  }) =>
      MediaPreviewConfig(
        height: height ?? this.height,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        borderRadius: borderRadius ?? this.borderRadius,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        changeCoverTextStyle: changeCoverTextStyle ?? this.changeCoverTextStyle,
        changeCoverOverlayColor:
            changeCoverOverlayColor ?? this.changeCoverOverlayColor,
      );
}

/// Caption input configuration
class CaptionInputConfig {
  const CaptionInputConfig({
    this.hintStyle,
    this.textStyle,
    this.inputUserTagTextStyle,
    this.inputHashtagTextStyle,
    this.maxLength,
    this.hintText,
  });

  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final TextStyle? inputUserTagTextStyle;
  final TextStyle? inputHashtagTextStyle;
  final int? maxLength;
  final String? hintText;

  CaptionInputConfig copyWith({
    TextStyle? hintStyle,
    TextStyle? textStyle,
    TextStyle? inputUserTagTextStyle,
    TextStyle? inputHashtagTextStyle,
    int? maxLength,
    String? hintText,
  }) =>
      CaptionInputConfig(
        hintStyle: hintStyle ?? this.hintStyle,
        textStyle: textStyle ?? this.textStyle,
        inputUserTagTextStyle: inputUserTagTextStyle ?? this.inputUserTagTextStyle,
        inputHashtagTextStyle: inputHashtagTextStyle ?? this.inputHashtagTextStyle,
        maxLength: maxLength ?? this.maxLength,
        hintText: hintText ?? this.hintText,
      );
}

/// Option tile configuration
class OptionTileConfig {
  const OptionTileConfig({
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.trailingIconColor,
    this.padding,
    this.margin,
  });

  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? trailingIconColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  OptionTileConfig copyWith({
    double? iconSize,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    Color? trailingIconColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) =>
      OptionTileConfig(
        iconSize: iconSize ?? this.iconSize,
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        trailingIconColor: trailingIconColor ?? this.trailingIconColor,
        padding: padding ?? this.padding,
        margin: margin ?? this.margin,
      );
}

/// Switch tile configuration
class SwitchTileConfig {
  const SwitchTileConfig({
    this.iconSize,
    this.titleStyle,
    this.activeThumbColor,
    this.inactiveThumbColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.padding,
    this.margin,
  });

  final double? iconSize;
  final TextStyle? titleStyle;
  final Color? activeThumbColor;
  final Color? inactiveThumbColor;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  SwitchTileConfig copyWith({
    double? iconSize,
    TextStyle? titleStyle,
    Color? activeThumbColor,
    Color? inactiveThumbColor,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) =>
      SwitchTileConfig(
        iconSize: iconSize ?? this.iconSize,
        titleStyle: titleStyle ?? this.titleStyle,
        activeThumbColor: activeThumbColor ?? this.activeThumbColor,
        inactiveThumbColor: inactiveThumbColor ?? this.inactiveThumbColor,
        activeTrackColor: activeTrackColor ?? this.activeTrackColor,
        inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
        padding: padding ?? this.padding,
        margin: margin ?? this.margin,
      );
}

/// Post button configuration
class PostButtonConfig {
  const PostButtonConfig({
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.textStyle,
    this.borderRadius,
    this.height,
    this.padding,
  });

  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final TextStyle? textStyle;
  final double? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;

  PostButtonConfig copyWith({
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    TextStyle? textStyle,
    double? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
  }) =>
      PostButtonConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        disabledBackgroundColor:
            disabledBackgroundColor ?? this.disabledBackgroundColor,
        textStyle: textStyle ?? this.textStyle,
        borderRadius: borderRadius ?? this.borderRadius,
        height: height ?? this.height,
        padding: padding ?? this.padding,
      );
}

/// Schedule post configuration
class SchedulePostConfig {
  const SchedulePostConfig({
    this.bottomSheetConfig,
    this.datePickerTheme,
    this.timePickerTheme,
    this.dateFieldConfig,
    this.timeFieldConfig,
    this.saveButtonConfig,
  });

  final BottomSheetConfig? bottomSheetConfig;
  final DatePickerThemeData? datePickerTheme;
  final TimePickerThemeData? timePickerTheme;
  final DateFieldConfig? dateFieldConfig;
  final TimeFieldConfig? timeFieldConfig;
  final SaveButtonConfig? saveButtonConfig;

  SchedulePostConfig copyWith({
    BottomSheetConfig? bottomSheetConfig,
    DatePickerThemeData? datePickerTheme,
    TimePickerThemeData? timePickerTheme,
    DateFieldConfig? dateFieldConfig,
    TimeFieldConfig? timeFieldConfig,
    SaveButtonConfig? saveButtonConfig,
  }) =>
      SchedulePostConfig(
        bottomSheetConfig: bottomSheetConfig ?? this.bottomSheetConfig,
        datePickerTheme: datePickerTheme ?? this.datePickerTheme,
        timePickerTheme: timePickerTheme ?? this.timePickerTheme,
        dateFieldConfig: dateFieldConfig ?? this.dateFieldConfig,
        timeFieldConfig: timeFieldConfig ?? this.timeFieldConfig,
        saveButtonConfig: saveButtonConfig ?? this.saveButtonConfig,
      );
}

/// Date field configuration
class DateFieldConfig {
  const DateFieldConfig({
    this.labelStyle,
    this.fieldStyle,
    this.borderColor,
    this.borderRadius,
    this.padding,
  });

  final TextStyle? labelStyle;
  final TextStyle? fieldStyle;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  DateFieldConfig copyWith({
    TextStyle? labelStyle,
    TextStyle? fieldStyle,
    Color? borderColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) =>
      DateFieldConfig(
        labelStyle: labelStyle ?? this.labelStyle,
        fieldStyle: fieldStyle ?? this.fieldStyle,
        borderColor: borderColor ?? this.borderColor,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
      );
}

/// Time field configuration
class TimeFieldConfig {
  const TimeFieldConfig({
    this.labelStyle,
    this.fieldStyle,
    this.borderColor,
    this.borderRadius,
    this.padding,
  });

  final TextStyle? labelStyle;
  final TextStyle? fieldStyle;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  TimeFieldConfig copyWith({
    TextStyle? labelStyle,
    TextStyle? fieldStyle,
    Color? borderColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) =>
      TimeFieldConfig(
        labelStyle: labelStyle ?? this.labelStyle,
        fieldStyle: fieldStyle ?? this.fieldStyle,
        borderColor: borderColor ?? this.borderColor,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
      );
}

/// Save button configuration
class SaveButtonConfig {
  const SaveButtonConfig({
    this.backgroundColor,
    this.textStyle,
    this.borderRadius,
    this.height,
    this.padding,
  });

  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;

  SaveButtonConfig copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    double? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
  }) =>
      SaveButtonConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textStyle: textStyle ?? this.textStyle,
        borderRadius: borderRadius ?? this.borderRadius,
        height: height ?? this.height,
        padding: padding ?? this.padding,
      );
}

/// Configuration for tag people and search user screens
class TagPeopleUIConfig {
  const TagPeopleUIConfig({
    this.tagPeopleScreenConfig,
    this.searchUserScreenConfig,
  });

  /// Configuration for tag people screen
  final TagPeopleScreenConfig? tagPeopleScreenConfig;

  /// Configuration for search user screen
  final SearchUserScreenConfig? searchUserScreenConfig;

  TagPeopleUIConfig copyWith({
    TagPeopleScreenConfig? tagPeopleScreenConfig,
    SearchUserScreenConfig? searchUserScreenConfig,
  }) =>
      TagPeopleUIConfig(
        tagPeopleScreenConfig:
            tagPeopleScreenConfig ?? this.tagPeopleScreenConfig,
        searchUserScreenConfig:
            searchUserScreenConfig ?? this.searchUserScreenConfig,
      );
}

/// Configuration for tag people screen
class TagPeopleScreenConfig {
  const TagPeopleScreenConfig({
    this.appBarConfig,
    this.mediaCarouselConfig,
    this.tagButtonConfig,
    this.taggedPeopleListConfig,
  });

  final AppBarConfig? appBarConfig;
  final MediaCarouselConfig? mediaCarouselConfig;
  final TagButtonConfig? tagButtonConfig;
  final TaggedPeopleListConfig? taggedPeopleListConfig;

  TagPeopleScreenConfig copyWith({
    AppBarConfig? appBarConfig,
    MediaCarouselConfig? mediaCarouselConfig,
    TagButtonConfig? tagButtonConfig,
    TaggedPeopleListConfig? taggedPeopleListConfig,
  }) =>
      TagPeopleScreenConfig(
        appBarConfig: appBarConfig ?? this.appBarConfig,
        mediaCarouselConfig: mediaCarouselConfig ?? this.mediaCarouselConfig,
        tagButtonConfig: tagButtonConfig ?? this.tagButtonConfig,
        taggedPeopleListConfig:
            taggedPeopleListConfig ?? this.taggedPeopleListConfig,
      );
}

/// Media carousel configuration
class MediaCarouselConfig {
  const MediaCarouselConfig({
    this.containerDecoration,
    this.pageIndicatorConfig,
    this.mediaCounterConfig,
    this.tagCountIndicatorConfig,
  });

  final BoxDecoration? containerDecoration;
  final PageIndicatorConfig? pageIndicatorConfig;
  final MediaCounterConfig? mediaCounterConfig;
  final TagCountIndicatorConfig? tagCountIndicatorConfig;

  MediaCarouselConfig copyWith({
    BoxDecoration? containerDecoration,
    PageIndicatorConfig? pageIndicatorConfig,
    MediaCounterConfig? mediaCounterConfig,
    TagCountIndicatorConfig? tagCountIndicatorConfig,
  }) =>
      MediaCarouselConfig(
        containerDecoration: containerDecoration ?? this.containerDecoration,
        pageIndicatorConfig: pageIndicatorConfig ?? this.pageIndicatorConfig,
        mediaCounterConfig: mediaCounterConfig ?? this.mediaCounterConfig,
        tagCountIndicatorConfig:
            tagCountIndicatorConfig ?? this.tagCountIndicatorConfig,
      );
}

/// Page indicator configuration
class PageIndicatorConfig {
  const PageIndicatorConfig({
    this.activeColor,
    this.inactiveColor,
    this.activeWidth,
    this.inactiveWidth,
    this.height,
    this.borderRadius,
    this.spacing,
  });

  final Color? activeColor;
  final Color? inactiveColor;
  final double? activeWidth;
  final double? inactiveWidth;
  final double? height;
  final double? borderRadius;
  final double? spacing;

  PageIndicatorConfig copyWith({
    Color? activeColor,
    Color? inactiveColor,
    double? activeWidth,
    double? inactiveWidth,
    double? height,
    double? borderRadius,
    double? spacing,
  }) =>
      PageIndicatorConfig(
        activeColor: activeColor ?? this.activeColor,
        inactiveColor: inactiveColor ?? this.inactiveColor,
        activeWidth: activeWidth ?? this.activeWidth,
        inactiveWidth: inactiveWidth ?? this.inactiveWidth,
        height: height ?? this.height,
        borderRadius: borderRadius ?? this.borderRadius,
        spacing: spacing ?? this.spacing,
      );
}

/// Media counter configuration
class MediaCounterConfig {
  const MediaCounterConfig({
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
  });

  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  MediaCounterConfig copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) =>
      MediaCounterConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textStyle: textStyle ?? this.textStyle,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
      );
}

/// Tag count indicator configuration
class TagCountIndicatorConfig {
  const TagCountIndicatorConfig({
    this.backgroundColor,
    this.textStyle,
    this.iconColor,
    this.padding,
    this.borderRadius,
  });

  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  TagCountIndicatorConfig copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    Color? iconColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) =>
      TagCountIndicatorConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textStyle: textStyle ?? this.textStyle,
        iconColor: iconColor ?? this.iconColor,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
      );
}

/// Tag button configuration
class TagButtonConfig {
  const TagButtonConfig({
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.borderWidth,
    this.borderRadius,
    this.height,
  });

  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double? borderWidth;
  final double? borderRadius;
  final double? height;

  TagButtonConfig copyWith({
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    double? borderWidth,
    double? borderRadius,
    double? height,
  }) =>
      TagButtonConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderColor: borderColor ?? this.borderColor,
        textStyle: textStyle ?? this.textStyle,
        borderWidth: borderWidth ?? this.borderWidth,
        borderRadius: borderRadius ?? this.borderRadius,
        height: height ?? this.height,
      );
}

/// Tagged people list configuration
class TaggedPeopleListConfig {
  const TaggedPeopleListConfig({
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.listItemConfig,
    this.dividerColor,
  });

  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final TaggedPeopleListItemConfig? listItemConfig;
  final Color? dividerColor;

  TaggedPeopleListConfig copyWith({
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    TaggedPeopleListItemConfig? listItemConfig,
    Color? dividerColor,
  }) =>
      TaggedPeopleListConfig(
        headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
        headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
        listItemConfig: listItemConfig ?? this.listItemConfig,
        dividerColor: dividerColor ?? this.dividerColor,
      );
}

/// Tagged people list item configuration
class TaggedPeopleListItemConfig {
  const TaggedPeopleListItemConfig({
    this.avatarSize,
    this.nameStyle,
    this.usernameStyle,
    this.removeIconColor,
    this.padding,
  });

  final double? avatarSize;
  final TextStyle? nameStyle;
  final TextStyle? usernameStyle;
  final Color? removeIconColor;
  final EdgeInsetsGeometry? padding;

  TaggedPeopleListItemConfig copyWith({
    double? avatarSize,
    TextStyle? nameStyle,
    TextStyle? usernameStyle,
    Color? removeIconColor,
    EdgeInsetsGeometry? padding,
  }) =>
      TaggedPeopleListItemConfig(
        avatarSize: avatarSize ?? this.avatarSize,
        nameStyle: nameStyle ?? this.nameStyle,
        usernameStyle: usernameStyle ?? this.usernameStyle,
        removeIconColor: removeIconColor ?? this.removeIconColor,
        padding: padding ?? this.padding,
      );
}

/// Configuration for search user screen
class SearchUserScreenConfig {
  const SearchUserScreenConfig({
    this.appBarConfig,
    this.searchBarConfig,
    this.selectedUsersConfig,
    this.searchResultsConfig,
    this.emptyStateConfig,
  });

  final AppBarConfig? appBarConfig;
  final SearchBarConfig? searchBarConfig;
  final SelectedUsersConfig? selectedUsersConfig;
  final SearchResultsConfig? searchResultsConfig;
  final EmptyStateConfig? emptyStateConfig;

  SearchUserScreenConfig copyWith({
    AppBarConfig? appBarConfig,
    SearchBarConfig? searchBarConfig,
    SelectedUsersConfig? selectedUsersConfig,
    SearchResultsConfig? searchResultsConfig,
    EmptyStateConfig? emptyStateConfig,
  }) =>
      SearchUserScreenConfig(
        appBarConfig: appBarConfig ?? this.appBarConfig,
        searchBarConfig: searchBarConfig ?? this.searchBarConfig,
        selectedUsersConfig: selectedUsersConfig ?? this.selectedUsersConfig,
        searchResultsConfig: searchResultsConfig ?? this.searchResultsConfig,
        emptyStateConfig: emptyStateConfig ?? this.emptyStateConfig,
      );
}

/// Search bar configuration
class SearchBarConfig {
  const SearchBarConfig({
    this.backgroundColor,
    this.hintStyle,
    this.textStyle,
    this.borderRadius,
    this.prefixIconColor,
    this.suffixIconColor,
    this.padding,
  });

  final Color? backgroundColor;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final double? borderRadius;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final EdgeInsetsGeometry? padding;

  SearchBarConfig copyWith({
    Color? backgroundColor,
    TextStyle? hintStyle,
    TextStyle? textStyle,
    double? borderRadius,
    Color? prefixIconColor,
    Color? suffixIconColor,
    EdgeInsetsGeometry? padding,
  }) =>
      SearchBarConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        hintStyle: hintStyle ?? this.hintStyle,
        textStyle: textStyle ?? this.textStyle,
        borderRadius: borderRadius ?? this.borderRadius,
        prefixIconColor: prefixIconColor ?? this.prefixIconColor,
        suffixIconColor: suffixIconColor ?? this.suffixIconColor,
        padding: padding ?? this.padding,
      );
}

/// Selected users configuration
class SelectedUsersConfig {
  const SelectedUsersConfig({
    this.headerTitleStyle,
    this.chipConfig,
  });

  final TextStyle? headerTitleStyle;
  final SelectedUserChipConfig? chipConfig;

  SelectedUsersConfig copyWith({
    TextStyle? headerTitleStyle,
    SelectedUserChipConfig? chipConfig,
  }) =>
      SelectedUsersConfig(
        headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
        chipConfig: chipConfig ?? this.chipConfig,
      );
}

/// Selected user chip configuration
class SelectedUserChipConfig {
  const SelectedUserChipConfig({
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.avatarSize,
    this.removeButtonColor,
    this.padding,
    this.borderRadius,
    this.borderWidth,
  });

  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double? avatarSize;
  final Color? removeButtonColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? borderWidth;

  SelectedUserChipConfig copyWith({
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    double? avatarSize,
    Color? removeButtonColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? borderWidth,
  }) =>
      SelectedUserChipConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderColor: borderColor ?? this.borderColor,
        textStyle: textStyle ?? this.textStyle,
        avatarSize: avatarSize ?? this.avatarSize,
        removeButtonColor: removeButtonColor ?? this.removeButtonColor,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
        borderWidth: borderWidth ?? this.borderWidth,
      );
}

/// Search results configuration
class SearchResultsConfig {
  const SearchResultsConfig({
    this.listItemConfig,
    this.dividerColor,
  });

  final SearchResultItemConfig? listItemConfig;
  final Color? dividerColor;

  SearchResultsConfig copyWith({
    SearchResultItemConfig? listItemConfig,
    Color? dividerColor,
  }) =>
      SearchResultsConfig(
        listItemConfig: listItemConfig ?? this.listItemConfig,
        dividerColor: dividerColor ?? this.dividerColor,
      );
}

/// Search result item configuration
class SearchResultItemConfig {
  const SearchResultItemConfig({
    this.avatarSize,
    this.nameStyle,
    this.usernameStyle,
    this.checkboxConfig,
    this.padding,
  });

  final double? avatarSize;
  final TextStyle? nameStyle;
  final TextStyle? usernameStyle;
  final CheckboxConfig? checkboxConfig;
  final EdgeInsetsGeometry? padding;

  SearchResultItemConfig copyWith({
    double? avatarSize,
    TextStyle? nameStyle,
    TextStyle? usernameStyle,
    CheckboxConfig? checkboxConfig,
    EdgeInsetsGeometry? padding,
  }) =>
      SearchResultItemConfig(
        avatarSize: avatarSize ?? this.avatarSize,
        nameStyle: nameStyle ?? this.nameStyle,
        usernameStyle: usernameStyle ?? this.usernameStyle,
        checkboxConfig: checkboxConfig ?? this.checkboxConfig,
        padding: padding ?? this.padding,
      );
}

/// Checkbox configuration
class CheckboxConfig {
  const CheckboxConfig({
    this.selectedColor,
    this.unselectedColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.size,
    this.borderWidth,
    this.borderRadius,
  });

  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final double? size;
  final double? borderWidth;
  final double? borderRadius;

  CheckboxConfig copyWith({
    Color? selectedColor,
    Color? unselectedColor,
    Color? selectedBorderColor,
    Color? unselectedBorderColor,
    double? size,
    double? borderWidth,
    double? borderRadius,
  }) =>
      CheckboxConfig(
        selectedColor: selectedColor ?? this.selectedColor,
        unselectedColor: unselectedColor ?? this.unselectedColor,
        selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
        unselectedBorderColor:
            unselectedBorderColor ?? this.unselectedBorderColor,
        size: size ?? this.size,
        borderWidth: borderWidth ?? this.borderWidth,
        borderRadius: borderRadius ?? this.borderRadius,
      );
}

/// Empty state configuration
class EmptyStateConfig {
  const EmptyStateConfig({
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  EmptyStateConfig copyWith({
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) =>
      EmptyStateConfig(
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      );
}

/// Configuration for search location screen
class SearchLocationUIConfig {
  const SearchLocationUIConfig({
    this.appBarConfig,
    this.searchBarConfig,
    this.selectedLocationsConfig,
    this.searchResultsConfig,
    this.emptyStateConfig,
    this.locationPermissionConfig,
  });

  final AppBarConfig? appBarConfig;
  final SearchBarConfig? searchBarConfig;
  final SelectedLocationsConfig? selectedLocationsConfig;
  final SearchResultsConfig? searchResultsConfig;
  final EmptyStateConfig? emptyStateConfig;
  final LocationPermissionConfig? locationPermissionConfig;

  SearchLocationUIConfig copyWith({
    AppBarConfig? appBarConfig,
    SearchBarConfig? searchBarConfig,
    SelectedLocationsConfig? selectedLocationsConfig,
    SearchResultsConfig? searchResultsConfig,
    EmptyStateConfig? emptyStateConfig,
    LocationPermissionConfig? locationPermissionConfig,
  }) =>
      SearchLocationUIConfig(
        appBarConfig: appBarConfig ?? this.appBarConfig,
        searchBarConfig: searchBarConfig ?? this.searchBarConfig,
        selectedLocationsConfig:
            selectedLocationsConfig ?? this.selectedLocationsConfig,
        searchResultsConfig: searchResultsConfig ?? this.searchResultsConfig,
        emptyStateConfig: emptyStateConfig ?? this.emptyStateConfig,
        locationPermissionConfig:
            locationPermissionConfig ?? this.locationPermissionConfig,
      );
}

/// Selected locations configuration
class SelectedLocationsConfig {
  const SelectedLocationsConfig({
    this.headerTitleStyle,
    this.chipConfig,
  });

  final TextStyle? headerTitleStyle;
  final SelectedLocationChipConfig? chipConfig;

  SelectedLocationsConfig copyWith({
    TextStyle? headerTitleStyle,
    SelectedLocationChipConfig? chipConfig,
  }) =>
      SelectedLocationsConfig(
        headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
        chipConfig: chipConfig ?? this.chipConfig,
      );
}

/// Selected location chip configuration
class SelectedLocationChipConfig {
  const SelectedLocationChipConfig({
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.iconColor,
    this.removeButtonColor,
    this.padding,
    this.borderRadius,
    this.borderWidth,
  });

  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final Color? iconColor;
  final Color? removeButtonColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? borderWidth;

  SelectedLocationChipConfig copyWith({
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    Color? iconColor,
    Color? removeButtonColor,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? borderWidth,
  }) =>
      SelectedLocationChipConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderColor: borderColor ?? this.borderColor,
        textStyle: textStyle ?? this.textStyle,
        iconColor: iconColor ?? this.iconColor,
        removeButtonColor: removeButtonColor ?? this.removeButtonColor,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
        borderWidth: borderWidth ?? this.borderWidth,
      );
}

/// Location permission configuration
class LocationPermissionConfig {
  const LocationPermissionConfig({
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.buttonConfig,
  });

  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final LocationPermissionButtonConfig? buttonConfig;

  LocationPermissionConfig copyWith({
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    LocationPermissionButtonConfig? buttonConfig,
  }) =>
      LocationPermissionConfig(
        iconColor: iconColor ?? this.iconColor,
        titleStyle: titleStyle ?? this.titleStyle,
        subtitleStyle: subtitleStyle ?? this.subtitleStyle,
        buttonConfig: buttonConfig ?? this.buttonConfig,
      );
}

/// Location permission button configuration
class LocationPermissionButtonConfig {
  const LocationPermissionButtonConfig({
    this.backgroundColor,
    this.textStyle,
    this.borderRadius,
    this.height,
    this.padding,
  });

  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;

  LocationPermissionButtonConfig copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    double? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
  }) =>
      LocationPermissionButtonConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textStyle: textStyle ?? this.textStyle,
        borderRadius: borderRadius ?? this.borderRadius,
        height: height ?? this.height,
        padding: padding ?? this.padding,
      );
}

/// Phase of the create/edit post pipeline when using [CreateEditPostCallBackConfig.onBackgroundPostOperation].
enum BackgroundPostOperationPhase {
  /// Uploading media and previews to cloud storage (includes compression when enabled).
  uploading,

  /// Create-post or edit-post API call in flight.
  creatingPost,

  /// Server-side media processing after create (when applicable).
  processingMedia,

  /// Post published, updated, or scheduled successfully.
  success,

  /// Upload, API, or processing failed — see [BackgroundPostOperationUpdate.failureMessage].
  failure,
}

/// Which step failed when [BackgroundPostOperationPhase] is [BackgroundPostOperationPhase.failure].
enum BackgroundPostFailureKind {
  upload,
  createOrEditApi,
  mediaProcessing,
}

/// Payload for host overlays, notifications, or foreground services during background create post.
class BackgroundPostOperationUpdate {
  const BackgroundPostOperationUpdate({
    required this.phase,
    this.overallProgressPercent = 0,
    this.title,
    this.subtitle,
    this.currentFileIndex = 0,
    this.totalFiles = 0,
    this.currentFileName,
    this.isUploadError = false,
    this.isAllFilesUploaded = false,
    this.failureKind,
    this.failureMessage,
    this.httpStatusCode,
    this.postId,
    this.postData,
    this.successTitle,
    this.successMessage,
    this.mediaDataList,
    this.isEditMode = false,
    this.retry,
  });

  final BackgroundPostOperationPhase phase;

  /// Overall progress for upload phase (0–100). Other phases may use 0 or 100 as appropriate.
  final double overallProgressPercent;

  final String? title;
  final String? subtitle;
  final int currentFileIndex;
  final int totalFiles;
  final String? currentFileName;
  final bool isUploadError;
  final bool isAllFilesUploaded;
  final BackgroundPostFailureKind? failureKind;
  final String? failureMessage;
  final int? httpStatusCode;

  final String? postId;
  final TimeLineData? postData;
  final String? successTitle;
  final String? successMessage;
  final List<MediaData>? mediaDataList;
  final bool isEditMode;

  /// Retries the last create/edit post operation (same request). Only set when failure is recoverable.
  final VoidCallback? retry;
}

class CreateEditPostCallBackConfig {
  const CreateEditPostCallBackConfig({
    this.onLinkProduct,
    this.onBackgroundPostOperation,
  });

  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onLinkProduct;

  /// When set, upload and create/edit post run without the SDK progress bottom sheet.
  /// Use [BackgroundPostOperationUpdate] to drive your own overlay, in-app banner, or notification.
  ///
  /// The SDK invokes this from the create-post bloc so updates continue even if the user leaves the create screen.
  final void Function(BackgroundPostOperationUpdate update)? onBackgroundPostOperation;

  CreateEditPostCallBackConfig copyWith({
    Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
        onLinkProduct,
    void Function(BackgroundPostOperationUpdate update)? onBackgroundPostOperation,
  }) =>
      CreateEditPostCallBackConfig(
        onLinkProduct: onLinkProduct ?? this.onLinkProduct,
        onBackgroundPostOperation:
            onBackgroundPostOperation ?? this.onBackgroundPostOperation,
      );
}
