import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';

class IsmCreatePostView extends StatefulWidget {
  const IsmCreatePostView({super.key});

  @override
  State<IsmCreatePostView> createState() => _IsmCreatePostViewState();
}

class _IsmCreatePostViewState extends State<IsmCreatePostView> {
  final _descriptionController = TextEditingController();
  bool _isNowSelected = true;
  int _descriptionLength = 0;
  final int _maxLength = 200;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const IsmCustomAppBarWidget(
          isBackButtonVisible: true,
          titleText: IsrTranslationFile.createPost,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Section
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                  color: IsrColors.colorDBDBDB,
                  strokeWidth: 1,
                  dashPattern: const [6, 3],
                  child: Column(
                    children: [
                      Row(
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
                                IsrDimens.boxHeight(IsrDimens.four),
                                Text(
                                  IsrTranslationFile.uploadPhotoOrVideoToInspire,
                                  style: IsrStyles.secondaryText12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.twentyFour),

                // Description Section
                Text(
                  IsrTranslationFile.description,
                  style: IsrStyles.secondaryText12,
                ),
                IsrDimens.boxHeight(IsrDimens.eight),
                TextField(
                  controller: _descriptionController,
                  maxLength: _maxLength,
                  maxLines: 4,
                  style: IsrStyles.primaryText14,
                  decoration: InputDecoration(
                    hintText: IsrTranslationFile.writeDescription,
                    hintStyle: IsrStyles.secondaryText14.copyWith(color: IsrColors.colorBBBBBB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: IsrColors.colorDBDBDB), // Added border color
                    ),
                    enabledBorder: OutlineInputBorder(
                      // Added to ensure the color shows in normal state
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: IsrColors.colorDBDBDB), // Added border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      // Added to maintain color when focused
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: IsrColors.colorDBDBDB), // Added border color
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

                IsrDimens.boxHeight(IsrDimens.twentyFour),

                // Cover Section
                Text(
                  '${IsrTranslationFile.cover}*',
                  style: IsrStyles.primaryText12,
                ),
                IsrDimens.boxHeight(IsrDimens.eight),
                Container(
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
                      // Image placeholder
                      const AppImage.svg(
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
                              IsrTranslationFile.editCover,
                              style: IsrStyles.secondaryText12.copyWith(color: IsrColors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                IsrDimens.boxHeight(IsrDimens.twentyFour),

                // When to post Section
                Text(
                  '${IsrTranslationFile.whenToPost}*',
                  style: IsrStyles.primaryText12,
                ),
                IsrDimens.boxHeight(IsrDimens.eight),
                Row(
                  children: [
                    Radio(
                      value: true,
                      groupValue: _isNowSelected,
                      onChanged: (value) {
                        setState(() {
                          _isNowSelected = value!;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    Text(
                      IsrTranslationFile.now,
                      style: IsrStyles.primaryText14,
                    ),
                    const SizedBox(width: 24),
                    Radio(
                      value: false,
                      groupValue: _isNowSelected,
                      onChanged: (value) {
                        setState(() {
                          _isNowSelected = value!;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    Text(
                      IsrTranslationFile.schedule,
                      style: IsrStyles.primaryText14,
                    ),
                  ],
                ),

                IsrDimens.boxHeight(IsrDimens.twentyFour),

                // Link Products Section
                Text(
                  '${IsrTranslationFile.linkProductsToPost}*',
                  style: IsrStyles.primaryText14,
                ),
                IsrDimens.boxHeight(IsrDimens.eight),
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
                  color: IsrColors.colorDBDBDB,
                  strokeWidth: 1,
                  dashPattern: const [6, 3],
                  child: Column(
                    children: [
                      Text(
                        IsrTranslationFile.noProductsLinkedYet,
                        style: IsrStyles.primaryText14.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IsrDimens.boxHeight(IsrDimens.four),
                      Text(
                        IsrTranslationFile.connectProductsToPost,
                        textAlign: TextAlign.center,
                        style: IsrStyles.secondaryText12.copyWith(color: IsrColors.color909090),
                      ),
                      IsrDimens.boxHeight(IsrDimens.sixteen),
                      AppButton(
                        width: IsrDimens.oneHundredForty,
                        onPress: () {
                          // Handle add products
                        },
                        title: IsrTranslationFile.addProducts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
