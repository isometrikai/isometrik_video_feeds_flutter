import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  int _descriptionLength = 0;
  final int _maxLength = 200;
  PostAttributeClass? postAttributeClass;
  final _createPostBloc = InjectionUtils.getBloc<CreatePostBloc>();
  var coverImage = '';
  final descriptionController = TextEditingController();
  var _isCreateButtonDisable = false;

  @override
  void initState() {
    coverImage = '';
    super.initState();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const CustomAppBar(
          isBackButtonVisible: true,
          titleText: TranslationFile.createPost,
          centerTitle: true,
          isCrossIcon: true,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.ten, horizontal: Dimens.twenty),
            child: AppButton(
              width: Dimens.oneHundredForty,
              onPress: () {
                _createPostBloc.add(PostCreateEvent());
              },
              isDisable: _isCreateButtonDisable,
              title: TranslationFile.create,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<CreatePostBloc, CreatePostState>(
            listener: (context, state) {
              if (state is PostCreatedState) {
                Utility.showInSnackBar(
                  TranslationFile.socialPostCreatedSuccessfully,
                  context,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.black,
                  isSuccessIcon: true,
                );
                Navigator.pop(context, state.postDataModel);
              }
              if (state is UploadingCoverImageState) {
                setState(() {
                  state.progress >= 99 ? _isCreateButtonDisable = false : _isCreateButtonDisable = true;
                });
              }
              if (state is UploadingMediaState) {
                setState(() {
                  state.progress >= 99 ? _isCreateButtonDisable = false : _isCreateButtonDisable = true;
                });
              }
            },
            builder: (context, state) {
              if (state is MediaSelectedState) {
                postAttributeClass = state.postAttributeClass;
                coverImage = postAttributeClass!.coverImage!;
              }
              if (state is CoverImageSelected) {
                coverImage = state.coverImage ?? coverImage;
                if (postAttributeClass != null) {
                  postAttributeClass!.coverImage = coverImage;
                }
              }
              return SafeArea(
                child: SingleChildScrollView(
                  padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TapHandler(
                        onTap: () => _showUploadOptionsDialog(context, false),
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(12),
                          padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                          color: AppColors.colorDBDBDB,
                          strokeWidth: 1,
                          dashPattern: const [6, 3],
                          child: postAttributeClass != null ? _buildSelectedMediaSection() : _buildUploadSection(),
                        ),
                      ),

                      Dimens.boxHeight(Dimens.twentyFour),

                      // Description Section
                      Text(
                        TranslationFile.description,
                        style: Styles.secondaryText12,
                      ),
                      Dimens.boxHeight(Dimens.eight),
                      TextField(
                        controller: descriptionController,
                        maxLength: _maxLength,
                        maxLines: 4,
                        style: Styles.primaryText14,
                        decoration: InputDecoration(
                          hintText: TranslationFile.writeDescription,
                          hintStyle: Styles.secondaryText14.copyWith(color: AppColors.colorBBBBBB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.colorDBDBDB), // Added border color
                          ),
                          enabledBorder: OutlineInputBorder(
                            // Added to ensure the color shows in normal state
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.colorDBDBDB), // Added border color
                          ),
                          focusedBorder: OutlineInputBorder(
                            // Added to maintain color when focused
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.colorDBDBDB), // Added border color
                          ),
                          counterText: '',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _descriptionLength = value.length;
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$_descriptionLength/$_maxLength',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      Dimens.boxHeight(Dimens.twentyFour),

                      _buildCoverImageSection(),

                      Dimens.boxHeight(Dimens.twentyFour),

                      // When to post Section
                      Text(
                        '${TranslationFile.whenToPost}*',
                        style: Styles.primaryText12,
                      ),
                      Dimens.boxHeight(Dimens.eight),
                      Row(
                        children: [
                          Radio(
                            value: false,
                            groupValue: _createPostBloc.isScheduledPost,
                            onChanged: (value) {
                              setState(() {
                                _createPostBloc.isScheduledPost = value!;
                                _createPostBloc.selectedDate = DateTime.now().add(const Duration(days: 1));
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          Text(
                            TranslationFile.now,
                            style: Styles.primaryText14,
                          ),
                          const SizedBox(width: 24),
                          Radio(
                            value: true,
                            groupValue: _createPostBloc.isScheduledPost,
                            onChanged: (value) {
                              setState(() {
                                _createPostBloc.isScheduledPost = value!;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          Text(
                            TranslationFile.schedule,
                            style: Styles.primaryText14,
                          ),
                        ],
                      ),
                      if (_createPostBloc.isScheduledPost) ...[
                        Dimens.boxHeight(Dimens.twentyFour),
                        GestureDetector(
                          onTap: () => _selectDate(context), // Show date picker on tap
                          child: Container(
                            width: double.infinity, // Make the container full width
                            padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.sixteen, vertical: Dimens.eight),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.colorDBDBDB),
                              borderRadius: Dimens.borderRadiusAll(Dimens.twelve),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _createPostBloc.selectedDate == null
                                      ? TranslationFile.selectDate
                                      : DateFormat('dd MMM yyyy HH:mm').format(_createPostBloc.selectedDate!),
                                  style: Styles.primaryText14,
                                ),
                                const AppImage.svg(AssetConstants.icCalendarIcon),
                              ],
                            ),
                          ),
                        ),
                      ],

                      Dimens.boxHeight(Dimens.twentyFour),

                      // Link Products Section
                      Text(
                        '${TranslationFile.linkProductsToPost}*',
                        style: Styles.primaryText14,
                      ),
                      Dimens.boxHeight(Dimens.eight),
                      DottedBorder(
                        borderType: BorderType.RRect,
                        radius: Radius.circular(Dimens.twelve),
                        padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                        color: AppColors.colorDBDBDB,
                        strokeWidth: 1,
                        dashPattern: const [6, 3],
                        child: Column(
                          children: [
                            Text(
                              TranslationFile.noProductsLinkedYet,
                              style: Styles.primaryText14.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Dimens.boxHeight(Dimens.four),
                            Text(
                              TranslationFile.connectProductsToPost,
                              textAlign: TextAlign.center,
                              style: Styles.secondaryText12.copyWith(color: AppColors.color909090),
                            ),
                            Dimens.boxHeight(Dimens.sixteen),
                            AppButton(
                              width: Dimens.oneHundredForty,
                              onPress: () {
                                // Handle add products
                              },
                              title: TranslationFile.addProducts,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

  void _showUploadOptionsDialog(BuildContext context, bool isCoverImage) {
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadSection() => Row(
        children: [
          const AppImage.svg(AssetConstants.icCloudUploadIcon),
          Dimens.boxWidth(Dimens.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationFile.uploadPhotoOrVideo,
                  style: Styles.primaryText14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Dimens.boxHeight(Dimens.four),
                Text(
                  TranslationFile.uploadPhotoOrVideoToInspire,
                  style: Styles.secondaryText12,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildSelectedMediaSection() => Row(
        children: [
          MediaPreviewWidget(postAttributeClass: postAttributeClass),
          Dimens.boxWidth(Dimens.twelve),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Preview
                // AspectRatio(
                //   aspectRatio: 1,
                //   child: ClipRRect(
                //     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                //     child: mediaInfoClass?.mediaType == MediaType.photo
                //         ? AppImage.file(mediaInfoClass?.mediaFile!.path.toString() ?? '')
                //         : MediaPreviewWidget(mediaInfoClass: mediaInfoClass),
                //   ),
                // ),
                Text(
                  postAttributeClass?.file?.path.split('/').last ?? '',
                  style: Styles.primaryText14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Dimens.boxHeight(Dimens.four),

                Text(
                  '${TranslationFile.size}: ${Utility.formatFileSize(File(postAttributeClass?.file?.path ?? '').lengthSync())} ${postAttributeClass?.postType == MediaType.video ? '  ${TranslationFile.duration}: ${Utility.formatDuration(Duration(seconds: postAttributeClass?.duration ?? 0))}' : ''}',
                  style: Styles.secondaryText12.copyWith(
                    color: AppColors.color909090,
                  ),
                ),
                Dimens.boxHeight(Dimens.four),

                // Change Button
                AppButton(
                  width: Dimens.hundred,
                  title: TranslationFile.change,
                  onPress: () {
                    _showUploadOptionsDialog(context, false);
                  },
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCoverImageSection() => // Cover Section
      BlocBuilder<CreatePostBloc, CreatePostState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${TranslationFile.cover}*',
              style: Styles.primaryText12,
            ),
            Dimens.boxHeight(Dimens.eight),
            Container(
              width: Dimens.oneHundredTwenty,
              height: Dimens.oneHundredSixty,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.colorDBDBDB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Check if postAttributeClass is not null and has a cover image
                  coverImage.isEmptyOrNull == false
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppImage.file(
                            width: Dimens.oneHundredTwenty,
                            height: Dimens.oneHundredSixty,
                            coverImage,
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
                      height: Dimens.forty,
                      decoration: const BoxDecoration(
                        color: AppColors.colorCCCCCC,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: TapHandler(
                          onTap: () {
                            _showUploadOptionsDialog(context, true);
                          },
                          child: Text(
                            TranslationFile.editCover,
                            style: Styles.secondaryText12.copyWith(color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // state is UploadingCoverImageState && state.progress > 0 && state.progress < 99
                  // Progress Bar
                  if (state is UploadingCoverImageState && state.progress > 0 && state.progress < 99) ...[
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                value: state.progress,
                                backgroundColor: AppColors.colorDBDBDB,
                                color: Theme.of(context).primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  void _selectDate(BuildContext context) async {
    final pickedDate = await showDialog(
      context: context,
      builder: (BuildContext context) {
        var selectedDate = _createPostBloc.selectedDate ?? DateTime.now().add(const Duration(days: 1));
        var selectedTime = TimeOfDay.fromDateTime(selectedDate);

        return AlertDialog(
          title: Text(TranslationFile.schedulePost, style: Styles.primaryText14),
          backgroundColor: AppColors.white,
          buttonPadding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.five, vertical: Dimens.ten),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Picker
                ListTile(
                  title: Text(
                    'Date: ${DateFormat('d MMM yyyy').format(selectedDate)}',
                    style: Styles.primaryText14,
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime(2101),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: Theme.of(context).primaryColor,
                          colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ));
                    }
                  },
                ),
                // Time Picker
                ListTile(
                  title: Text(
                    'Time: ${selectedTime.format(context)}',
                    style: Styles.primaryText14,
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: Theme.of(context).primaryColor,
                          colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: AppColors.white,
                textStyle: Styles.primaryText14,
              ),
              child: Text(
                TranslationFile.cancel,
                style: Styles.primaryText14,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: AppColors.white,
                textStyle: Styles.primaryText14,
              ),
              child: Text(
                TranslationFile.ok,
                style: Styles.primaryText14,
              ),
            ),
          ],
        );
      },
    ) as DateTime?;

    if (pickedDate != null && pickedDate != _createPostBloc.selectedDate) {
      setState(() {
        _createPostBloc.selectedDate = pickedDate;
      });
    }
  }
}
