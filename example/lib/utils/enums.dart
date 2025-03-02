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
