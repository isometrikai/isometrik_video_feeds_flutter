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
