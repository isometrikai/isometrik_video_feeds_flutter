import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CreateCollectionView extends StatefulWidget {
  const CreateCollectionView({
    Key? key,
    this.collection, // Add collection parameter for edit mode
    this.productOrPostId,
    this.isFromPost = false,
    required this.defaultCollectionImage,
  }) : super(key: key);

  final CollectionData? collection; // Collection data for edit mode
  final String? productOrPostId;
  final bool isFromPost;
  final String defaultCollectionImage;

  @override
  State<CreateCollectionView> createState() => _CreateCollectionViewState();
}

class _CreateCollectionViewState extends State<CreateCollectionView> {
  final TextEditingController _collectionNameController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _collectionNameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final ValueNotifier<bool> _isPrivate = ValueNotifier(false);
  final ValueNotifier<bool> _enableCreateButton = ValueNotifier(false);

  final _collectionBloc = IsmInjectionUtils.getBloc<CollectionBloc>();

  final ValueNotifier<File?> localImage = ValueNotifier<File?>(null);
  final ValueNotifier<String> imageUrl = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    // Initialize fields with collection data if in edit mode
    imageUrl.value = widget.defaultCollectionImage;
    if (widget.collection != null) {
      _collectionNameController.text = widget.collection!.name ?? '';
      _descriptionController.text = widget.collection!.description ?? '';
      _isPrivate.value = widget.collection!.isPrivate ?? true;
      imageUrl.value = widget.collection!.image ?? '';
      // _enableCreateButton.value = true;
    }
  }

  @override
  void dispose() {
    _collectionNameController.dispose();
    _descriptionController.dispose();
    _collectionNameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _isPrivate.dispose();
    imageUrl.dispose();
    super.dispose();
  }

  enableCreatebtn() {
    if (widget.collection != null) {
      if (_collectionNameController.text != widget.collection!.name ||
          _descriptionController.text != widget.collection!.description ||
          _isPrivate.value != widget.collection!.isPrivate ||
          imageUrl.value != widget.collection!.image) {
        _enableCreateButton.value = true;
      } else {
        _enableCreateButton.value = false;
      }
    } else {
      _enableCreateButton.value = _collectionNameController.text.isNotEmpty;
    }
  }

  bool get isEditMode => widget.collection != null;

  @override
  Widget build(BuildContext context) =>
      BlocListener<CollectionBloc, CollectionState>(
        bloc: _collectionBloc,
        listener: (context, state) {
          debugPrint(
              'CreateCollectionView BlocListener received state: $state');

          if (state is CreateCollectionSuccessState) {
            debugPrint(
                'CreateCollectionSuccessState received - dismissing bottom sheet');
            Utility.showToastMessage(state.message);

            if ((widget.productOrPostId ?? '').isNotEmpty) {
              _collectionBloc.add(
                MoveToCollectionEvent(
                  postId: widget.productOrPostId ?? '',
                  collectionId: state.collectionId,
                ),
              );
            } else {
              _collectionBloc.add(GetUserCollectionEvent(
                limit: 20,
                skip: 1,
              ));
            }

            context.pop();
          } else if (state is CreateCollectionErrorState) {
            debugPrint('CreateCollectionErrorState received: ${state.error}');
            Utility.showToastMessage(state.error);
          } else if (state is EditCollectionSuccessState) {
            debugPrint(
                'EditCollectionSuccessState received - dismissing bottom sheet');
            Utility.showToastMessage(state.message);
            context.pop();
          } else if (state is EditCollectionErrorState) {
            debugPrint('EditCollectionErrorState received: ${state.error}');
            Utility.showToastMessage(state.error);
          } else if (state is CollectionImageUpdateSuccessState) {
            imageUrl.value = state.imageString;
            localImage.value = state.localFile;
            FocusManager.instance.primaryFocus?.unfocus();
            enableCreatebtn();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTitleTextWidget(
                title: isEditMode
                    ? IsrTranslationFile.editCollection
                    : IsrTranslationFile.createNewCollection,
                showCloseIcon: true,
                removePadding: true,
              ),
              12.responsiveVerticalSpace,
              // const CustomDivider(
              //   color: IsrColors.colorD4D4D4,
              //   height: 1,
              // ),
              // 16.responsiveVerticalSpace,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      IsrDimens.boxHeight(IsrDimens.twenty),
                      _buildFieldLabel('${IsrTranslationFile.collectionName}*'),
                      _buildInputField(
                        _collectionNameController,
                        _collectionNameFocusNode,
                        IsrTranslationFile.collectionName,
                        inputFormatter: [
                          // FilteringTextInputFormatter.allow(
                          //   RegExp(r'[a-zA-Z0-9 ]'),
                          // ),
                          NoFirstSpaceFormatter(),
                          CapitalizeTextFormatter(
                              capitalizeOnlyFirstLetter: true),
                        ],
                        onChange: (val) {
                          // _collectionNameController.updateTextWithCursor(
                          //     (_) => Utility.capitalizeString(val,
                          //         capitalizeOnlyFirstLetter: true));
                          enableCreatebtn();
                        },
                        maxLength: 42,
                      ),
                      IsrDimens.boxHeight(IsrDimens.twelve),
                      _buildFieldLabel(
                          '${IsrTranslationFile.description}(Optional)'),
                      _buildInputField(
                        _descriptionController,
                        _descriptionFocusNode,
                        IsrTranslationFile.description,
                        maxLines: 5,
                        onChange: (desc) {
                          enableCreatebtn();
                        },
                        maxLength: 200,
                        showCountBuilder: true,
                      ),
                      IsrDimens.boxHeight(IsrDimens.sixteen),
                      // Text(
                      //   IsrTranslationFile.shareSettings,
                      //   style: IsrStyles.primaryText14.copyWith(
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                      // IsrDimens.boxHeight(IsrDimens.sixteen),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const AppImage.svg(
                                AssetConstants.icLockIcon,
                                color: IsrColors.color333333,
                              ),
                              8.responsiveHorizontalSpace,
                              Text(
                                IsrTranslationFile.makeThisCollectionPrivate,
                                style: IsrStyles.secondaryText14.copyWith(
                                  color: IsrColors.color333333,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: _isPrivate,
                            builder: (_, isPrivate, __) => Switch(
                              activeThumbColor: IsrColors.appColor,
                              activeTrackColor:
                                  IsrColors.appColor.applyOpacity(0.1),
                              inactiveTrackColor: 'EBEBEB'.toColor(),
                              inactiveThumbColor: '6B6B6B'.toColor(),
                              trackOutlineWidth: WidgetStateProperty.all(0),
                              trackOutlineColor: WidgetStateProperty.all(
                                  IsrColors.transparent),
                              value: isPrivate,
                              onChanged: (value) {
                                _isPrivate.value = value;
                                enableCreatebtn();
                              },
                            ),
                          ),
                        ],
                      ),
                      // ValueListenableBuilder<bool>(
                      //   valueListenable: _isPrivate,
                      //   builder: (_, isPrivate, __) => IntrinsicHeight(
                      //     child: Row(
                      //       children: [
                      //         _buildSharingOption(
                      //           AssetConstants.icEarth,
                      //           IsrTranslationFile.public,
                      //           IsrTranslationFile.anyoneCanView,
                      //           isPrivate,
                      //           false,
                      //         ),
                      //         8.responsiveHorizontalSpace,
                      //         _buildSharingOption(
                      //           AssetConstants.icLock,
                      //           IsrTranslationFile.private,
                      //           IsrTranslationFile.onlyYouCanView,
                      //           isPrivate,
                      //           true,
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      24.responsiveVerticalSpace,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: IsrDimens.edgeInsets(
                  bottom: MediaQuery.of(context).padding.bottom +
                      14.responsiveDimension,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _enableCreateButton,
                  builder: (context, _enable, _) =>
                      BlocBuilder<CollectionBloc, CollectionState>(
                    bloc: _collectionBloc,
                    buildWhen: (previous, current) =>
                        current is CreateCollectionLoadingState ||
                        current is CreateCollectionSuccessState ||
                        current is CreateCollectionErrorState ||
                        current is EditCollectionLoadingState ||
                        current is EditCollectionSuccessState ||
                        current is EditCollectionErrorState,
                    builder: (context, state) => AppButton(
                      isDisable: !_enable,
                      borderRadius: 6.responsiveDimension,
                      title: isEditMode
                          ? IsrTranslationFile.save
                          : IsrTranslationFile.createCollection,
                      onPress: () {
                        if (isEditMode) {
                          _collectionBloc.add(
                            EditUserCollectionEvent(
                                EditCollectionRequestModel(
                                    isPrivate: _isPrivate.value,
                                    name: _collectionNameController.text,
                                    description: _descriptionController.text,
                                    image: imageUrl.value,
                                    id: widget.collection?.id ?? ''),
                                widget.collection?.id ?? ''),
                          );
                        } else {
                          _collectionBloc.add(
                            CreateUserCollectionEvent(
                              createCollectionRequestModel:
                                  CreateCollectionRequestModel(
                                isPrivate: _isPrivate.value,
                                name: _collectionNameController.text,
                                description: _descriptionController.text,
                                image: imageUrl.value,
                              ),
                            ),
                          );
                        }
                      },
                      isLoading: state is CreateCollectionLoadingState ||
                          state is EditCollectionLoadingState,
                      textStyle: IsrStyles.primaryText14
                          .copyWith(color: IsrColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImagePicker() => DashedBorderContainer(
        radius: 6.responsiveDimension,
        dashSpace: 6.responsiveDimension,
        dashWidth: 6.responsiveDimension,
        color: IsrColors.colorDBDBDB,
        padding: IsrDimens.edgeInsetsAll(12.responsiveDimension),
        child: SizedBox(
          // color: IsrColors.colorEEEEEE,
          child: Center(
            child: Container(
              width: 98.responsiveDimension,
              height: 98.responsiveDimension,
              decoration: BoxDecoration(
                color: IsrColors.colorF4F4F4,
                borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
              ),
              child: ValueListenableBuilder2<String, File?>(
                first: imageUrl,
                second: localImage,
                builder: (context, _imageUrl, _localFile, _) {
                  if (_localFile != null || _imageUrl.isNotEmpty) {
                    final imageWidget = _localFile != null
                        ? AppImage.file(
                            _localFile.path,
                            fit: BoxFit.cover,
                            borderRadius:
                                IsrDimens.borderRadiusAll(IsrDimens.eight),
                          )
                        : AppImage.network(
                            _imageUrl,
                            borderRadius:
                                IsrDimens.borderRadiusAll(IsrDimens.eight),
                          );
                    return Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          imageWidget,
                          Positioned(
                            right: 4.responsiveDimension,
                            bottom: 4.responsiveDimension,
                            child: TapHandler(
                              onTap: () {
                                imageUrl.value = '';
                                localImage.value = null;
                                enableCreatebtn();
                              },
                              child: AppImage.svg(
                                AssetConstants.icEditIcon,
                                color: IsrColors.white,
                                dimensions: 20.responsiveDimension,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return BlocBuilder<CollectionBloc, CollectionState>(
                    bloc: _collectionBloc,
                    buildWhen: (previous, current) =>
                        current is CollectionImageLoadingState ||
                        current is CollectionImageUpdateSuccessState ||
                        current is CollectionImageUpdateErrorState,
                    builder: (context, state) {
                      if (state is CollectionImageLoadingState) {
                        return const AppLoader(
                          loaderType: LoaderType.normal,
                        );
                      }
                      return TapHandler(
                        borderRadius: IsrDimens.eight,
                        onTap: () {
                          Utility.showBottomSheet(
                            child: const ShowProfileImageSelectBottomSheet(),
                          );
                        },
                        child: Center(
                          child: AppImage.svg(
                            AssetConstants.icEmptyImageVector,
                            height: 32.responsiveDimension,
                            width: 32.responsiveDimension,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

  Widget _buildSharingOption(String svgPath, String title, String subtitle,
          bool isPrivate, bool value) =>
      Expanded(
        child: TapHandler(
          onTap: () {
            _isPrivate.value = value;
            enableCreatebtn();
          },
          borderRadius: 6.responsiveDimension,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: isPrivate == value ? 'F3F9FF'.toColor() : IsrColors.white,
              borderRadius: BorderRadius.circular(6.responsiveDimension),
              border: Border.all(
                color: isPrivate == value
                    ? IsrColors.appColor
                    : IsrColors.colorDBDBDB,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                AppImage.svg(
                  svgPath,
                  color: isPrivate == value ? IsrColors.appColor : null,
                  height: IsrDimens.twentyTwo,
                  width: IsrDimens.twentyTwo,
                ),
                IsrDimens.boxWidth(IsrDimens.twelve),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: IsrStyles.primaryText14.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: IsrStyles.primaryText12.copyWith(
                        color: '767676'.toColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFieldLabel(String label) => Padding(
        padding: IsrDimens.edgeInsets(bottom: IsrDimens.four),
        child: Text(label,
            style:
                IsrStyles.primaryText12.copyWith(color: IsrColors.color4A4A4A)),
      );

  Widget _buildInputField(
    TextEditingController controller,
    FocusNode focusNode,
    String hintText, {
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatter,
    Function(String)? onChange,
    bool? showCountBuilder,
  }) {
    final maxCharacterLimit =
        maxLength ?? (maxLines > 1 ? 240 : TextField.noMaxLength);
    return FormFieldWidget(
      formStyle: IsrStyles.primaryText14.copyWith(color: IsrColors.color333333),
      autoFocus: false,
      focusNode: focusNode,
      onChange: onChange,
      inputFormatters: inputFormatter ??
          [
            NoFirstSpaceFormatter(),
          ],
      textInputAction: TextInputAction.next,
      textEditingController: controller,
      hintText: hintText,
      maxLength: maxCharacterLimit,
      maxlines: maxLines,
      showCountBuilder: showCountBuilder,
    );
  }
}
