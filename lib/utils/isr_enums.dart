enum NetworkRequestType {
  get,
  post,
  put,
  patch,
  delete,
}

enum SavedValueDataType {
  string,
  int,
  double,
  bool,
  stringList,
}

enum LoaderType {
  normal,
  withBackGround,
  withoutBackground,
  animation,
}

enum ErrorViewType {
  none,
  dialog,
  snackBar,
  toast,
  bottomSheet,
}

enum ImageType {
  asset,
  svg,
  file,
  network;
}

enum PostSectionType {
  following,
  trending,
}

enum PostType {
  video,
  photo,
}

enum MediaSource {
  gallery,
  camera,
}

enum LikeAction {
  like,
  unlike,
}

enum ButtonType {
  primary, // Blue background, white text
  secondary, // Outlined button with blue border
  tertiary, // Text only button
  danger, // Red background for destructive actions
  success, // Green background for confirmations
  disabled // Grey, non-interactive
}

enum ButtonSize {
  small, // Height: 32
  medium, // Height: 40
  large // Height: 48
}
