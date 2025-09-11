import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

enum ImageType {
  asset,
  svg,
  file,
  network;
}

enum ButtonType {
  primary, // Blue background, white text
  secondary, // Outlined button with blue border
  tertiary, // Text only button
  danger, // Red background for destructive actions
  success, // Green background for confirmations
  disabled // Grey, non-interactive
}

enum LikeAction {
  like,
  unlike,
}

enum ButtonSize {
  small, // Height: 32
  medium, // Height: 40
  large // Height: 48
}

enum GradientTextType {
  linear,
  radial,
  sweep;
}

enum NetworkRequestType {
  get,
  post,
  put,
  patch,
  delete,
}

enum LoaderType {
  normal,
  withBackGround,
  withoutBackground,
  animation,
}

enum SavedValueDataType {
  string,
  int,
  double,
  bool,
  stringList,
}

enum ErrorViewType {
  none,
  dialog,
  snackBar,
  toast,
  bottomSheet,
}

enum PostType {
  video,
  photo,
}

enum MediaSource {
  gallery,
  camera,
}

enum MediaType {
  video,
  photo,
  both,
}

enum NavbarType {
  home(
    TranslationFile.homeNavigation,
    AssetConstants.icHomeNavigationIcon,
    AssetConstants.icHomeUnselectedNavigationIcon,
    AppRoutes.home,
    isVisible: true,
  ),
  account(
    TranslationFile.accountNavigation,
    AssetConstants.icAccountNavigationIcon,
    AssetConstants.icAccountUnselectedNavigationIcon,
    AppRoutes.profileView,
    isVisible: true,
  );

  const NavbarType(
    this.label,
    this.outlineIcon,
    this.filledIcon,
    this.route, {
    this.isVisible = true,
  });

  final String label;
  final String outlineIcon;
  final String filledIcon;
  final String route;
  final bool isVisible;

  // Helper method to get visible items
  static List<NavbarType> get visibleItems =>
      NavbarType.values.where((item) => item.isVisible).toList();
}

enum SocialPostAction {
  like,
  unlike,
  comment,
  share,
  report,
  delete,
  save,
  unSave,
}

enum ReasonsFor {
  socialPost,
  comment,
}

enum CommentAction {
  like,
  dislike,
  report,
  delete,
  comment,
  edit,
}

enum FollowAction {
  follow,
  unfollow,
}

class PlaceType {
  const PlaceType(this.apiString);
  final String apiString;

  static const geocode = PlaceType('geocode');
  static const address = PlaceType('address');
  static const establishment = PlaceType('establishment');
  static const region = PlaceType('(region)');
  static const cities = PlaceType('(cities)');
}
