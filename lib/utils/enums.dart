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

enum MediaSource {
  gallery,
  camera,
}

enum ButtonType {
  primary, // Blue background, white text
  secondary, // Outlined button with blue border
  tertiary, // Text only button
  danger, // Red background for destructive actions
  success, // Green background for confirmations
  disabled, // Grey, non-interactive
  text, // Simple text button without background or border
}

enum ButtonSize {
  small, // Height: 32
  medium, // Height: 40
  large // Height: 48
}

/// Enum to specify media type
enum MediaType {
  video,
  photo,
  both,
  unknown,
}

enum PostType {
  video,
  photo,
}

enum FollowAction {
  follow,
  unfollow,
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

enum LikeAction {
  like,
  unlike,
}

enum CommentAction {
  like,
  dislike,
  report,
  delete,
  comment,
  edit,
}

enum ReasonsFor {
  socialPost,
  comment,
}

enum PostTabType {
  forYou,
  following,
  trending,
  myPost,
  otherUserPost,
  memberUserPost,
  savedPost,
  tagPost,
}

enum TagType {
  hashtag('hashtag'),
  place('place'),
  product('product'),
  mention('mention');

  const TagType(this.value);

  final String value;
}

enum SearchTabType {
  posts('Posts'),
  account('Accounts'),
  tags('Tags'),
  places('Places');

  const SearchTabType(this.displayName);

  final String displayName;
}
