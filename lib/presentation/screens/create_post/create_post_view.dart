import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post/media_preview_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post/upload_media_dialog.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post/upload_progress_bottom_sheet.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({
    super.key,
    this.postData,
  });

  static bool disableAutoDismissForTest = false;

  final TimeLineData? postData;

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _mediaDataList = <MediaData>[];

  CreatePostBloc get _createPostBloc =>
      BlocProvider.of<CreatePostBloc>(context);
  var _coverImage = '';

  bool get _isCreateButtonDisable {
    if (CreatePostView.disableAutoDismissForTest) return false;

    // Enable button only if media is selected (for both create and edit post)
    return _mediaDataList.isEmpty;
  }

  var _isForEdit = false;
  bool _isDialogOpen = false;
  UploadProgressCubit get _progressCubit =>
      BlocProvider.of<UploadProgressCubit>(context);
  var _isCompressing = false;
  final Map<String, bool> _mediaCompressionState = {};

  @override
  void initState() {
    debugPrint('DEBUG: _createPostBloc instance: ${_createPostBloc.hashCode}');
    _onStartInit();
    super.initState();
  }

  void _onStartInit() async {
    if (widget.postData != null) {
      _isForEdit = true;
      _createPostBloc.add(EditPostEvent(postData: widget.postData!));
    } else {
      _createPostBloc.add(CreatePostInitialEvent());
    }
  }

  // Move all private methods above build in _CreatePostViewState
  void _showUploadOptionsDialog(
      BuildContext context, bool isCoverImage, MediaData? mediaData) {
    showDialog(
      context: context,
      builder: (BuildContext context) => UploadMediaDialog(
        mediaType: isCoverImage ? MediaType.photo : MediaType.both,
        onMediaSelected: (result) {
          _createPostBloc.add(
            MediaSourceEvent(
              context: context,
              mediaType: result.mediaType,
              mediaSource: result.source,
              isCoverImage: isCoverImage,
              mediaData: mediaData,
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadSection() => Row(
        children: [
          const AppImage.svg(AssetConstants.icCloudUploadIcon),
          IsrDimens.boxWidth(IsrDimens.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IsrTranslationFile.uploadPhotoOrVideo,
                  style: IsrStyles.primaryText14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                4.verticalSpace,
                Text(
                  IsrTranslationFile.uploadPhotoOrVideoToInspire,
                  style: IsrStyles.secondaryText12,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildSelectedMediaSection(MediaData mediaData) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPreviewWidget(
              key: Key(mediaData.localPath ?? ''), mediaData: mediaData),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaData.fileName ?? '',
                  style: IsrStyles.primaryText14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // 4.verticalSpace,
                // Text(
                //   '${IsrTranslationFile.size}: ${Utility.formatFileSize(_mediaLength)}'
                //   '${mediaData.postType == PostType.video ? '  ${IsrTranslationFile.duration}: ${Utility.formatDuration(Duration(seconds: mediaData.duration?.toInt() ?? 0))}' : ''}',
                //   style: IsrStyles.secondaryText12.copyWith(
                //     color: IsrColors.color909090,
                //   ),
                // ),
                if (!_isForEdit) ...[
                  8.verticalSpace,
                  (_mediaCompressionState[mediaData.localPath] ?? false)
                      ? Text('${IsrTranslationFile.optimizingMedia}...',
                          style: IsrStyles.primaryText10)
                      : AppButton(
                          width: 83.responsiveDimension,
                          size: ButtonSize.small,
                          height: 28.responsiveDimension,
                          backgroundColor: '001E57'.color,
                          title: IsrTranslationFile.change,
                          textStyle: IsrStyles.white12
                              .copyWith(fontWeight: FontWeight.w600),
                          onPress: () {
                            _showUploadOptionsDialog(context, false, mediaData);
                          },
                        ),
                ],
              ],
            ),
          ),
          // 10.horizontalSpace,
          // const AppImage.svg(AssetConstants.icBlueTick),
          // ❌ Remove Button
          if (!_isForEdit)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _createPostBloc.add(RemoveMediaEvent(mediaData: mediaData));
                });
              },
            ),
        ],
      );

  Widget _buildCoverImageSection() => // Cover Section
      BlocBuilder<CreatePostBloc, CreatePostState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${IsrTranslationFile.cover}*',
              style: IsrStyles.primaryText12,
            ),
            8.verticalSpace,
            TapHandler(
              onTap: () {
                _showUploadOptionsDialog(
                    context,
                    true,
                    _mediaDataList.isListEmptyOrNull
                        ? null
                        : _mediaDataList.first);
              },
              child: Container(
                width: IsrDimens.oneHundredTwenty,
                height: IsrDimens.oneHundredSixty,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: IsrColors.colorDBDBDB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Check if postAttributeClass is not null and has a cover image
                    _coverImage.isEmptyOrNull == false
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _coverImage.contains('http')
                                ? AppImage.network(
                                    _coverImage,
                                    width: IsrDimens.oneHundredTwenty,
                                    height: IsrDimens.oneHundredSixty,
                                    fit: BoxFit.cover,
                                    isProfileImage: false,
                                  )
                                : AppImage.file(
                                    width: IsrDimens.oneHundredTwenty,
                                    height: IsrDimens.oneHundredSixty,
                                    _coverImage,
                                    fit: BoxFit.cover,
                                    isProfileImage: false,
                                  ),
                          )
                        : const AppImage.svg(
                            AssetConstants.icCoverImagePlaceHolder,
                          ),
                    // Edit Cover button at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: IsrDimens.forty,
                        decoration: const BoxDecoration(
                          color: IsrColors.colorCCCCCC,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _coverImage.isEmptyOrNull == false
                                ? IsrTranslationFile.editCover
                                : IsrTranslationFile.addCover,
                            style: IsrStyles.secondaryText12
                                .copyWith(color: IsrColors.white),
                          ),
                        ),
                      ),
                    ),

                    // Progress Bar
                    if (state is UploadingCoverImageState &&
                        state.progress > 0 &&
                        state.progress < 99) ...[
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  value: state.progress,
                                  backgroundColor: IsrColors.colorDBDBDB,
                                  color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _showProgressDialog(String title, String message) async {
    await Utility.showBottomSheet(
        child: UploadProgressBottomSheet(message: message),
        isDismissible: false);
    _isDialogOpen = false;
  }

  Widget _buildSuccessBottomSheet({
    required Function() onTapBack,
    required String title,
    required String message,
  }) =>
      Container(
        width: IsrDimens.getScreenWidth(context),
        padding: IsrDimens.edgeInsetsAll(16.responsiveDimension),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: TapHandler(
                onTap: () {
                  Navigator.pop(context);
                  onTapBack();
                },
                child: const AppImage.svg(
                  AssetConstants.icCrossIcon,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  AssetConstants.postUploadedAnimation,
                  animate: true,
                  height: 70.responsiveDimension,
                  width: 70.responsiveDimension,
                  repeat: false,
                ),
                24.verticalSpace,
                Text(
                  message,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.responsiveDimension,
                  ),
                  textAlign: TextAlign.center,
                ),
                8.verticalSpace,
                Text(
                  IsrTranslationFile.yourPostHasBeenSuccessfullyPosted,
                  style: IsrStyles.primaryText14.copyWith(
                    color: Colors.grey,
                    fontSize: 15.responsiveDimension,
                  ),
                  textAlign: TextAlign.center,
                ),
                16.verticalSpace,
              ],
            ),
          ],
        ),
      );

  void _doMediaCaching(List<MediaData>? mediaDataList) async {
    if (mediaDataList.isEmptyOrNull) return;
    final urls = <String>[];
    for (var media in mediaDataList!) {
      if (media.url.isEmptyOrNull == false) {
        urls.add(media.url!);
      }
      if (media.previewUrl.isEmptyOrNull == false) {
        urls.add(media.previewUrl!);
      }
    }
    if (!mounted) return;

    // Use compute for background processing if needed
    await compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      Utility.preCacheImages(urls, context);
    });
  }

  void _onPressCreateButton() async {
    // Navigate to post attribute view and wait for result
    _createPostBloc.add(PostAttributeNavigationEvent(context: context));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CreatePostBloc, CreatePostState>(
        listener: (context, state) {
          if (state is PostCreatedState) {
            Utility.showBottomSheet(
              child: _buildSuccessBottomSheet(
                onTapBack: () {
                  Navigator.pop(context, state.postDataModel);
                  Navigator.pop(context, state.postDataModel);
                },
                title: state.postSuccessTitle ?? '',
                message: state.postSuccessMessage ?? '',
              ),
              isDismissible: false,
            );
            _doMediaCaching(state.mediaDataList);
            if (!CreatePostView.disableAutoDismissForTest) {
              Future.delayed(const Duration(seconds: 2), () async {
                Navigator.pop(context);
                Navigator.pop(context, state.postDataModel);
                Navigator.pop(context, state.postDataModel);
              });
            }
          }
          if (state is ShowProgressDialogState) {
            if (!_isDialogOpen) {
              _isDialogOpen = true;
              _showProgressDialog(state.title ?? '', state.subTitle ?? '');
            } else {
              if (state.isAllFilesUploaded) {
                // Show success animation
                // _progressCubit.showSuccess();
                // Dismiss after 3 seconds
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_isDialogOpen) {
                    _isDialogOpen = false;
                    Navigator.pop(context);
                  }
                });
              }
            }
            // Update all cubit state values
            _progressCubit.updateProgress(state.progress ?? 0);
            _progressCubit.updateTitle(
                state.title ?? IsrTranslationFile.uploadingMediaFiles);
            _progressCubit.updateSubtitle(state.subTitle ?? '');
          }
          if (state is MediaSelectedState) {
            _mediaDataList.clear();
            _mediaDataList.addAll(state.mediaDataList as Iterable<MediaData>);

            // Clean up compression state for removed media
            final currentMediaPaths =
                _mediaDataList.map((e) => e.localPath).toSet();
            _mediaCompressionState
                .removeWhere((key, value) => !currentMediaPaths.contains(key));

            if (_mediaDataList.isEmptyOrNull) {
              _coverImage = '';
              return;
            }
            final mediaData = _mediaDataList.first;
            _coverImage = mediaData.previewUrl ?? '';
            setState(() {});
          }
          if (state is CoverImageSelected) {
            _coverImage = state.coverImage ?? _coverImage;
            setState(() {});
          }

          if (state is CompressionProgressState) {
            _isCompressing = state.progress > 0 && state.progress < 100;
            // Update compression state for specific media
            _mediaCompressionState[state.mediaKey] =
                state.progress > 0 && state.progress < 100;
            setState(() {});
          }
        },
        buildWhen: (previous, current) =>
            previous != current && current is! UploadingMediaState,
        builder: (context, state) => Scaffold(
          appBar: IsmCustomAppBarWidget(
            isBackButtonVisible: true,
            titleText: _isForEdit
                ? IsrTranslationFile.editPost
                : IsrTranslationFile.createPost,
            centerTitle: true,
            isCrossIcon: true,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: IsrDimens.edgeInsetsSymmetric(
                  vertical: IsrDimens.ten, horizontal: IsrDimens.twenty),
              child: AppButton(
                width: IsrDimens.oneHundredForty,
                onPress: _onPressCreateButton,
                isDisable: CreatePostView.disableAutoDismissForTest
                    ? false
                    : (_isCreateButtonDisable || _isCompressing),
                title: IsrTranslationFile.next,
                borderRadius: 25.responsiveDimension,
                height: 50.responsiveDimension,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TapHandler(
                    onTap: _isForEdit ||
                            (_mediaDataList.isEmptyOrNull == false &&
                                AppConstants.isMultipleMediaSelectionEnabled ==
                                    false)
                        ? null
                        : () {
                            _showUploadOptionsDialog(context, false, null);
                          },
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        radius: Radius.circular(12.responsiveDimension),
                        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                        color: IsrColors.colorDBDBDB,
                        strokeWidth: 1,
                        dashPattern: const [6, 3],
                      ),
                      child: _mediaDataList.isEmptyOrNull == false
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(
                                _mediaDataList.length,
                                (index) {
                                  final media = _mediaDataList[index];
                                  return Column(
                                    children: [
                                      _buildSelectedMediaSection(media),
                                      if (index <
                                          _mediaDataList.length - 1) ...[
                                        SizedBox(height: 8.responsiveDimension),
                                        const Divider(
                                            color: IsrColors.colorDBDBDB,
                                            thickness: 1),
                                        SizedBox(height: 8.responsiveDimension),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            )
                          : _buildUploadSection(),
                    ),
                  ),
                  if (_mediaDataList.isEmptyOrNull == false) ...[
                    24.verticalSpace,
                    _buildCoverImageSection(),
                  ],
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      );
}
