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
import 'package:lottie/lottie.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({
    super.key,
    this.postData,
  });

  final TimeLineData? postData;

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  int _descriptionLength = 0;
  final int _maxLength = 200;

  // PostAttributeClass? postAttributeClass;
  final _mediaDataList = <MediaData>[];
  final _createPostBloc = InjectionUtils.getBloc<CreatePostBloc>();
  var _coverImage = '';
  final _descriptionController = TextEditingController();
  var _isCreateButtonDisable = true;
  final _linkedProducts = <ProductDataModel>[];
  var _mediaLength = 0;
  var _isForEdit = false;
  bool _isDialogOpen = false;
  final _progressCubit = InjectionUtils.getBloc<UploadProgressCubit>();
  var _isCompressing = false;

  @override
  void initState() {
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CreatePostBloc, CreatePostState>(
        listener: (context, state) {
          if (state is PostCreatedState) {
            Utility.showBottomSheet(
              child: _buildSuccessBottomSheet(
                onTapBack: () {
                  Navigator.pop(context, state.postDataModel);
                },
                title: state.postSuccessTitle ?? '',
                message: state.postSuccessMessage ?? '',
              ),
              isDismissible: false,
            );
            // Auto-dismiss after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(context);
              Navigator.pop(context, state.postDataModel);
            });
          }
          if (state is LoadLinkedProductsState) {
            _linkedProducts.clear();
            _linkedProducts.addAll(state.productList as Iterable<ProductDataModel>);
            setState(() {});
          }
          if (state is ShowProgressDialogState) {
            if (!_isDialogOpen) {
              _isDialogOpen = true;
              _showProgressDialog(state.title ?? '', state.subTitle ?? '');
            } else {
              if (state.progress == 100) {
                _isDialogOpen = false;
                Navigator.pop(context);
              }
            }
            _progressCubit.updateProgress(state.progress ?? 0);
          }
          if (state is MediaSelectedState) {
            _mediaDataList.clear();
            _mediaDataList.addAll(state.mediaDataList as Iterable<MediaData>);
            if (_mediaDataList.isEmptyOrNull) return;
            final mediaData = _mediaDataList.first;
            _coverImage = mediaData.previewUrl ?? '';
            if (mediaData.localPath.isEmptyOrNull == false &&
                Utility.isLocalUrl(mediaData.localPath ?? '') == true) {
              final localFile = File(mediaData.localPath ?? '');
              _mediaLength = localFile.lengthSync();
            }
            if (_isForEdit) {
              _mediaLength = mediaData.size?.toInt() ?? 0;
              _descriptionController.text = _createPostBloc.descriptionText;
              _descriptionLength = _descriptionController.text.length;
            }
            _isCreateButtonDisable = state.isPostButtonEnable == false;
            setState(() {});
          }
          if (state is CoverImageSelected) {
            _coverImage = state.coverImage ?? _coverImage;
            if (_mediaDataList.isEmptyOrNull == false) {
              // postAttributeClass!.coverImage = _coverImage;
            }
            _isCreateButtonDisable = state.isPostButtonEnable == false;
            setState(() {});
          }

          if (state is CompressionProgressState) {
            _isCompressing = state.progress > 0 && state.progress < 100;
          }
        },
        buildWhen: (previous, current) => previous != current && current is! UploadingMediaState,
        builder: (context, state) => Scaffold(
          appBar: CustomAppBar(
            isBackButtonVisible: true,
            titleText: _isForEdit ? TranslationFile.editPost : TranslationFile.createPost,
            centerTitle: true,
            isCrossIcon: true,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.ten, horizontal: Dimens.twenty),
              child: AppButton(
                width: Dimens.oneHundredForty,
                onPress: () {
                  _createPostBloc.add(PostCreateEvent(isForEdit: _isForEdit));
                },
                isDisable: _isCreateButtonDisable || _isCompressing,
                title: _isForEdit ? TranslationFile.updatePost : TranslationFile.create,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: Dimens.edgeInsetsAll(Dimens.sixteen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TapHandler(
                    onTap: _isForEdit ? null : () => _showUploadOptionsDialog(context, false),
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: Radius.circular(12.scaledValue),
                      padding: Dimens.edgeInsetsAll(Dimens.sixteen),
                      color: AppColors.colorDBDBDB,
                      strokeWidth: 1,
                      dashPattern: const [6, 3],
                      child: _mediaDataList.isEmptyOrNull == false
                          ? _buildSelectedMediaSection(_mediaDataList.first)
                          : _buildUploadSection(),
                    ),
                  ),

                  24.verticalSpace,

                  // Description Section
                  Text(
                    TranslationFile.description,
                    style: Styles.secondaryText12,
                  ),
                  8.verticalSpace,
                  TextField(
                    controller: _descriptionController,
                    maxLength: _maxLength,
                    maxLines: 4,
                    style: Styles.primaryText14,
                    decoration: InputDecoration(
                      hintText: TranslationFile.writeDescription,
                      hintStyle: Styles.secondaryText14.copyWith(color: AppColors.colorBBBBBB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.colorDBDBDB),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.colorDBDBDB),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.colorDBDBDB),
                      ),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      _createPostBloc.descriptionText = value;
                      setState(() {
                        if (_isForEdit) {
                          _isCreateButtonDisable =
                              _descriptionController.text == widget.postData?.caption;
                        }
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

                  24.verticalSpace,

                  _buildCoverImageSection(),

                  if (!_isForEdit) ...[
                    24.verticalSpace,

                    // When to post Section
                    Text(
                      '${TranslationFile.whenToPost}*',
                      style: Styles.primaryText12,
                    ),
                    8.verticalSpace,
                    Row(
                      children: [
                        Radio(
                          value: false,
                          groupValue: _createPostBloc.isScheduledPost,
                          onChanged: (value) {
                            setState(() {
                              _createPostBloc.isScheduledPost = value!;
                              _createPostBloc.selectedDate =
                                  DateTime.now().add(const Duration(hours: 1));
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        Text(
                          TranslationFile.now,
                          style: Styles.primaryText14,
                        ),
                        24.horizontalSpace,
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
                  ],
                  if (_createPostBloc.isScheduledPost) ...[
                    24.verticalSpace,
                    GestureDetector(
                      onTap: () => _selectDate(context), // Show date picker on tap
                      child: Container(
                        width: double.infinity, // Make the container full width
                        padding: Dimens.edgeInsetsSymmetric(
                            horizontal: Dimens.sixteen, vertical: Dimens.eight),
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
                                  : DateFormat('dd MMM yyyy HH:mm')
                                      .format(_createPostBloc.selectedDate!),
                              style: Styles.primaryText14,
                            ),
                            const AppImage.svg(AssetConstants.icCalendarIcon),
                          ],
                        ),
                      ),
                    ),
                  ],

                  24.verticalSpace,

                  // Link Products Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationFile.linkProductsToPost,
                        style: Styles.primaryText14,
                      ),
                      if (_linkedProducts.isNotEmpty)
                        Row(
                          children: [
                            IconButton(
                              onPressed: _getLinkedProducts,
                              icon: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Theme.of(context).primaryColor,
                                    size: 15.scaledValue,
                                  ),
                                  Text(
                                    TranslationFile.addProducts,
                                    style: Styles.primaryText12.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  8.verticalSpace,
                  if (_linkedProducts.isEmptyOrNull)
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
                          4.verticalSpace,
                          Text(
                            TranslationFile.connectProductsToPost,
                            textAlign: TextAlign.center,
                            style: Styles.secondaryText12.copyWith(color: AppColors.color909090),
                          ),
                          16.verticalSpace,
                          AppButton(
                            width: Dimens.oneHundredForty,
                            onPress: () async {
                              _getLinkedProducts();
                            },
                            title: TranslationFile.addProducts,
                          ),
                        ],
                      ),
                    ),
                  if (!_linkedProducts.isEmptyOrNull)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.scaledValue,
                      crossAxisSpacing: 8.scaledValue,
                      childAspectRatio: 0.45,
                      children: List.generate(
                        _linkedProducts.length,
                        (index) => _buildLinkedProductItem(
                            _linkedProducts[index], context, 415.scaledValue),
                      ),
                    ),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildLinkedProductItem(
      ProductDataModel productDataModel, BuildContext context, double height) {
    final brandName = productDataModel.brandTitle?.isEmptyOrNull == false
        ? productDataModel.brandTitle
        : productDataModel.brand?.isEmptyOrNull == false
            ? productDataModel.brand
            : productDataModel.storeName?.isEmptyOrNull == false
                ? productDataModel.storeName
                : productDataModel.store?.isEmptyOrNull == false
                    ? productDataModel.store
                    : '';
    final dynamic productImages = productDataModel.images;
    var imageUrl = productImages == null
        ? ''
        : (productImages is List<ImageData> && (productImages).isEmptyOrNull == false)
            ? (productImages[0].small?.isEmpty == true
                ? productImages[0].medium ?? ''
                : productImages[0].small ?? '')
            : (productImages is ImageData)
                ? (productImages.small?.isEmpty == true
                    ? productImages.medium ?? ''
                    : productImages.small ?? '')
                : productImages.toString();
    if (imageUrl.isEmpty) {
      imageUrl = productDataModel.productImage ?? '';
    }
    final isAutoShipProduct = productDataModel.sellerPlanDetails != null &&
        productDataModel.sellerPlanDetails?.frequencies.isEmptyOrNull == false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.colorDBDBDB),
        borderRadius: BorderRadius.circular(Dimens.twelve),
        color: AppColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with fixed height
          SizedBox(
            height: 186.scaledValue,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(Dimens.twelve),
                  ),
                  child: AppImage.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isAutoShipProduct)
                  _buildTag(
                      productDataModel.sellerPlanDetails?.sellerPlanName ?? '', '00000'.toHexColor),
                if ((productDataModel.rewardFinalPrice?.toDouble() ?? 0) > 0)
                  _buildEarnTalentTag(productDataModel.rewardFinalPrice?.toDouble() ?? 0),
              ],
            ),
          ),
          // Content Section
          Expanded(
            child: Padding(
              padding: Dimens.edgeInsetsAll(12.scaledValue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brandName.isEmptyOrNull == false)
                    Text(
                      brandName?.toUpperCase() ?? '',
                      style: Styles.primaryText10.copyWith(
                        color: '838383'.toHexColor,
                      ),
                    ),
                  4.verticalSpace,
                  Text(
                    productDataModel.productName ?? '',
                    style: Styles.primaryText12.copyWith(
                      fontWeight: FontWeight.w500,
                      color: '333333'.toHexColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Prices
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Non member',
                        style: Styles.primaryText10.copyWith(
                          color: '868686'.toHexColor,
                        ),
                      ),
                      Text(
                        Utility.getFormattedPrice(
                          productDataModel.finalPriceList?.msrpPrice?.toDouble() ?? 0,
                          productDataModel.currencySymbol,
                        ),
                        style: Styles.primaryText12.copyWith(
                          color: '868686'.toHexColor,
                        ),
                      ),
                    ],
                  ),
                  4.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Member',
                        style: Styles.primaryText10.copyWith(
                          color: '333333'.toHexColor,
                        ),
                      ),
                      Text(
                        Utility.getFormattedPrice(
                          productDataModel.finalPriceList?.basePrice?.toDouble() ?? 0,
                          productDataModel.currencySymbol,
                        ),
                        style: Styles.primaryText12.copyWith(
                          color: '333333'.toHexColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Remove Button
          AppButton(
            margin: Dimens.edgeInsetsSymmetric(horizontal: 12.scaledValue, vertical: 8.scaledValue),
            title: TranslationFile.remove,
            onPress: () {
              setState(() {
                _linkedProducts.remove(productDataModel);
              });
              _checkForChangesInLinkedProducts();
            },
            backgroundColor: AppColors.white,
            textColor: AppColors.black,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

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
                4.verticalSpace,
                Text(
                  TranslationFile.uploadPhotoOrVideoToInspire,
                  style: Styles.secondaryText12,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildSelectedMediaSection(MediaData mediaData) => Row(
        children: [
          MediaPreviewWidget(key: Key(mediaData.localPath ?? ''), mediaData: mediaData),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaData.fileName ?? '',
                  style: Styles.primaryText14.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  '${TranslationFile.size}: ${Utility.formatFileSize(_mediaLength)}'
                  '${mediaData.postType == PostType.video ? '  ${TranslationFile.duration}: ${Utility.formatDuration(Duration(seconds: mediaData.duration?.toInt() ?? 0))}' : ''}',
                  style: Styles.secondaryText12.copyWith(
                    color: AppColors.color909090,
                  ),
                ),
                if (!_isForEdit) ...[
                  8.verticalSpace,
                  _isCompressing
                      ? Text('${TranslationFile.optimizingMedia}...', style: Styles.primaryText10)
                      : AppButton(
                          width: 83.scaledValue,
                          size: ButtonSize.small,
                          backgroundColor: '001E57'.toHexColor,
                          title: TranslationFile.change,
                          onPress: () {
                            _showUploadOptionsDialog(context, false);
                          },
                        ),
                ],
              ],
            ),
          ),
          // const AppImage.svg(AssetConstants.icBlueTick),
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
            8.verticalSpace,
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
                  _coverImage.isEmptyOrNull == false
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _coverImage.contains('http')
                              ? AppImage.network(
                                  _coverImage,
                                  width: Dimens.oneHundredTwenty,
                                  height: Dimens.oneHundredSixty,
                                  fit: BoxFit.cover,
                                  isProfileImage: false,
                                )
                              : AppImage.file(
                                  width: Dimens.oneHundredTwenty,
                                  height: Dimens.oneHundredSixty,
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
        var selectedDate = _createPostBloc.selectedDate ?? _createPostBloc.getBufferedDate();
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
                    '${TranslationFile.date}: ${DateFormat('d MMM yyyy').format(selectedDate)}',
                    style: Styles.primaryText14,
                  ),
                  trailing: const AppImage.svg(AssetConstants.icCalendarIcon),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: _createPostBloc.getBufferedDate(),
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
                      if (!DateTimeUtil.isTodayDate(picked)) {
                        // If not today's date, set current time
                        selectedTime = TimeOfDay.fromDateTime(DateTime.now());
                      }
                      setState(
                        () => selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        ),
                      );
                    }
                  },
                ),
                // Time Picker
                ListTile(
                  title: Text(
                    '${TranslationFile.time}: ${selectedTime.format(context)}',
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
                      final nowDT = DateTime.now();
                      final pickedDT = DateTime(
                        nowDT.year,
                        nowDT.month,
                        nowDT.day,
                        picked.hour,
                        picked.minute,
                      );
                      if (pickedDT.isBefore(nowDT)) {
                        Navigator.pop(context, selectedDate);
                        Utility.showAppDialog(message: TranslationFile.pleaseSelectAFutureTime);
                      } else {
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

  Widget _buildTag(String tagName, Color backgroundColor) => Positioned(
        top: 5,
        left: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6.scaledValue)),
          child: Container(
            padding: Dimens.edgeInsetsSymmetric(
              horizontal: Dimens.eight,
              vertical: Dimens.four,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(6.scaledValue)),
            ),
            child: Text(
              tagName,
              textAlign: TextAlign.center,
              style:
                  Styles.white10.copyWith(fontWeight: FontWeight.w500, color: '001E57'.toHexColor),
            ),
          ),
        ),
      );

  Widget _buildEarnTalentTag(double talentValue) => Positioned(
        bottom: Dimens.twelve,
        left: Dimens.twelve,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6.scaledValue)),
          child: Container(
            padding: Dimens.edgeInsetsSymmetric(
              horizontal: Dimens.eight,
              vertical: Dimens.four,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Dimens.borderRadiusAll(25.scaledValue),
              border: Border.all(color: AppColors.black.applyOpacity(0.3), width: 0.5.scaledValue),
            ),
            child: Row(
              children: [
                Text(
                  'Earn ',
                  textAlign: TextAlign.center,
                  style: Styles.white10
                      .copyWith(fontWeight: FontWeight.w500, color: '333333'.toHexColor),
                ),
                3.horizontalSpace,
                // AppImage.asset(
                //   AssetConstants.icTalentIcon,
                //   height: 11.scaledValue,
                //   width: 11.scaledValue,
                // ),
                2.horizontalSpace,
                Text(
                  talentValue.toString(),
                  textAlign: TextAlign.center,
                  style: Styles.white10
                      .copyWith(fontWeight: FontWeight.w500, color: '333333'.toHexColor),
                ),
                3.horizontalSpace,
                Text(
                  'Talents',
                  textAlign: TextAlign.center,
                  style: Styles.white10
                      .copyWith(fontWeight: FontWeight.w500, color: '333333'.toHexColor),
                ),
              ],
            ),
          ),
        ),
      );

  void _getLinkedProducts() async {
    // final result = await InjectionUtils.getRouteManagement()
    //     .goToLinkProductScreen(linkedProducts: _linkedProducts);
    // setState(() {
    //   _linkedProducts.clear();
    //   _linkedProducts.addAll(result ?? []);
    // });
    // _createPostBloc.resetApiCall();
    // _checkForChangesInLinkedProducts();
  }

  void _checkForChangesInLinkedProducts() {
    final hasAnyChanges = _createPostBloc.checkForChangesInLinkedProducts(_linkedProducts);
    final mediaData = _mediaDataList.firstWhere((element) =>
        element.url.isEmptyOrNull == true || Utility.isLocalUrl(element.url ?? '') == true);
    debugPrint('hasAnyChanges: $hasAnyChanges');
    setState(() {
      _isCreateButtonDisable = _isForEdit ? !hasAnyChanges : mediaData != null;
    });
  }

  void _showProgressDialog(String title, String message) async {
    await Utility.showBottomSheet(
        child: UploadProgressBottomSheet(message: message), isDismissible: false);
    _isDialogOpen = false;
  }

  Widget _buildSuccessBottomSheet(
          {required Function() onTapBack, required String title, required String message}) =>
      Container(
        width: Dimens.getScreenWidth(context),
        padding: Dimens.edgeInsetsAll(16.scaledValue),
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
                  height: 70.scaledValue,
                  width: 70.scaledValue,
                  repeat: false,
                ),
                24.verticalSpace,
                Text(
                  message,
                  style: Styles.primaryText16.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.scaledValue,
                  ),
                  textAlign: TextAlign.center,
                ),
                8.verticalSpace,
                Text(
                  TranslationFile.yourPostHasBeenSuccessfullyPosted,
                  style: Styles.primaryText14.copyWith(
                    color: Colors.grey,
                    fontSize: 15.scaledValue,
                  ),
                  textAlign: TextAlign.center,
                ),
                16.verticalSpace,
              ],
            ),
          ],
        ),
      );
}
