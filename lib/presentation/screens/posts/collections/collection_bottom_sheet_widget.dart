import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class CollectionBottomSheetWidget extends StatefulWidget {
  const CollectionBottomSheetWidget({
    super.key,
    required this.postId,
    this.isFromPost = false,
    this.isFromProduct = false,
    this.isSaved = false,
    this.isFavoriteProduct = false,
    this.onSavePost,
    this.thumbnailUrl,
  });

  final String postId;
  final bool isFromPost;
  final bool isFromProduct;
  final bool isSaved;
  final bool isFavoriteProduct;
  final Function(bool)? onSavePost;
  final String? thumbnailUrl;

  @override
  State<CollectionBottomSheetWidget> createState() => _CollectionBottomSheetWidgetState();
}

class _CollectionBottomSheetWidgetState extends State<CollectionBottomSheetWidget> {
  late final CollectionBloc _collectionBloc;
  late final ScrollController _scrollController;
  static const int limit = 10;
  static const int skip = 1;

  late final ValueNotifier<String?> selectedCollectionNotifier;
  late final ValueNotifier<bool> btnEnableNotifier;
  late final ValueNotifier<int> totalPostNotifier;
  late final ValueNotifier<int> totalProductNotifier;

  String? _initialSelectedCollectionId;
  final Set<String> _processedSaveActions = {};

  // Cache for collection data to avoid repeated lookups
  final Map<String, CollectionData> _collectionMap = {};

  // Track additional items added to collections (for UI update)
  final Map<String, int> _additionalItemsCount = {};

  var isSaved = false;

  @override
  void initState() {
    super.initState();
    isSaved = widget.isSaved;

    // Initialize notifiers
    selectedCollectionNotifier = ValueNotifier<String?>(null);
    btnEnableNotifier = ValueNotifier<bool>(false);
    totalPostNotifier = ValueNotifier<int>(0);
    totalProductNotifier = ValueNotifier<int>(0);
    _scrollController = ScrollController();

    _collectionBloc = IsmInjectionUtils.getBloc<CollectionBloc>()
      ..add(CollectionInitEvent())
      ..add(GetUserCollectionEvent(limit: limit, skip: skip));
    _collectionBloc.add(GetSavedPostEvent(limit: 10, skip: 1));
  }

  void selectCollection(String id) {
    debugPrint('selectCollection called with id: "$id"');
    debugPrint('Current selection: "${selectedCollectionNotifier.value}"');

    // Skip empty IDs
    if (id.isEmpty) {
      debugPrint('selectCollection: Skipping empty collection ID');
      return;
    }

    // Toggle: if already selected, deselect; otherwise select the new one
    if (selectedCollectionNotifier.value == id) {
      debugPrint('Deselecting collection: $id');
      selectedCollectionNotifier.value = null;
    } else {
      debugPrint('Selecting collection: $id');
      selectedCollectionNotifier.value = id;
    }

    debugPrint('New selection: "${selectedCollectionNotifier.value}"');
    _updateDoneButtonState();
  }

  void _updateDoneButtonState() {
    final currentSelection = selectedCollectionNotifier.value;
    // Enable button if selection differs from initial state
    btnEnableNotifier.value = currentSelection != _initialSelectedCollectionId;
  }

  @override
  void dispose() {
    totalPostNotifier.dispose();
    totalProductNotifier.dispose();
    selectedCollectionNotifier.dispose();
    btnEnableNotifier.dispose();
    _scrollController.dispose();
    _collectionBloc.add(CollectionInitEvent());
    _collectionMap.clear();
    super.dispose();
  }

  void _handleDonePress() {
    final selectedCollectionId = selectedCollectionNotifier.value;

    // Safety check: return early if no collection is selected
    if (selectedCollectionId == null || selectedCollectionId.isEmpty) {
      debugPrint('No collection selected');
      return;
    }

    debugPrint(
        'MoveToCollectionEvent - postId: ${widget.postId}, collectionId: $selectedCollectionId');

    final collectionIdToUpdate = selectedCollectionId;

    _collectionBloc.add(MoveToCollectionEvent(
      postId: widget.postId,
      collectionId: selectedCollectionId,
      onMoveToCollection: () {
        // Deselect checkbox
        selectedCollectionNotifier.value = null;

        // Increase item count for the collection
        _additionalItemsCount[collectionIdToUpdate] =
            (_additionalItemsCount[collectionIdToUpdate] ?? 0) + 1;

        // Update button state
        _updateDoneButtonState();

        debugPrint('Collection $collectionIdToUpdate updated - item added');
      },
    ));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.pop(isSaved);
          }
        },
        child: BlocListener<CollectionBloc, CollectionState>(
          bloc: _collectionBloc,
          listener: (context, state) {
            if (state is ModifyUserCollectionSuccessState) {
              context.pop(isSaved);
              final names = state.collectionNames;
              final isAdd = state.action?.value == 'ADD';

              final message = names.length == 1
                  ? '${state.isPost ? 'Post' : 'Product'} ${isAdd ? 'added to' : 'removed from'} ${names[0]}'
                  : '${state.isPost ? 'Post' : 'Product'} ${isAdd ? 'added to' : 'removed from'} ${names[0]} +${names.length - 1} '
                      '${(names.length - 1) > 1 ? 'collections' : 'collection'}';

              Utility.showToastMessage(message);
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: IsrDimens.fourteen,
              right: IsrDimens.fourteen,
              top: IsrDimens.six,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: IsrDimens.edgeInsetsSymmetric(vertical: 6.responsiveDimension),
                  child: CommonTitleTextWidget(
                    title: IsrTranslationFile.savingPost,
                    showCloseIcon: true,
                    removePadding: true,
                    popFn: () {
                      context.pop(isSaved);
                    },
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.ten),
                if (widget.isFromPost) ...[
                  _buildSavedPost(),
                  20.responsiveVerticalSpace,
                ] /*else if (widget.isFromProduct) ...[
                  _buildFavoriteProducts(),
                  20.responsiveVerticalSpace,
                ]*/
                ,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      IsrTranslationFile.collections,
                      style: IsrStyles.primaryText16.copyWith(
                        fontWeight: FontWeight.w500,
                        color: IsrColors.black,
                      ),
                    ),
                    CustomTextButtonWidget(
                      onPress: () async {
                        await Utility.showCustomizedBottomSheet(
                          isRoundedCorners: false,
                          isScrollControlled: true,
                          child: BlocProvider<CollectionBloc>(
                            create: (context) => IsmInjectionUtils.getBloc<CollectionBloc>(),
                            child: CreateCollectionView(
                              productOrPostId: widget.postId,
                              defaultCollectionImage: widget.thumbnailUrl ?? '',
                            ),
                          ),
                        );
                        _collectionBloc.add(GetUserCollectionEvent(limit: limit, skip: skip));
                      },
                      widget: UnderlinedText(
                        text: IsrTranslationFile.newCollection,
                        textStyle: IsrStyles.primaryText14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: IsrColors.appColor,
                        ),
                      ),
                    ),
                  ],
                ),
                IsrDimens.boxHeight(IsrDimens.six),
                Expanded(
                  child: BlocBuilder<CollectionBloc, CollectionState>(
                    bloc: _collectionBloc,
                    buildWhen: (previous, current) =>
                        current is UserCollectionLoadingState ||
                        current is UserCollectionFetchState ||
                        current is UserCollectionErrorState,
                    builder: (context, state) {
                      if (state is UserCollectionLoadingState) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: _buildShimmerTile(),
                        );
                      } else if (state is UserCollectionFetchState) {
                        if (state.collectionList.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        // Build map once - only on first load
                        if (_collectionMap.isEmpty) {
                          debugPrint('Building collection map...');
                          for (final collection in state.collectionList) {
                            final collectionId = collection.id ?? '';
                            debugPrint('Collection: ${collection.name}, ID: "$collectionId"');
                            // Skip collections with empty ID
                            if (collectionId.isEmpty) {
                              debugPrint('Skipping collection with empty ID: ${collection.name}');
                              continue;
                            }
                            _collectionMap[collectionId] = collection;

                            // Check if post exists in collection (set initial selection)
                            final items = collection.productIds ?? [];
                            if (items.any((item) => item.id == widget.postId)) {
                              // Only set if not already set (first match wins)
                              if (_initialSelectedCollectionId == null) {
                                _initialSelectedCollectionId = collectionId;
                                selectedCollectionNotifier.value = collectionId;
                                debugPrint('Initial selection set to: $collectionId');
                              }
                            }
                          }
                          debugPrint('Collection map built with ${_collectionMap.length} items');
                        }

                        return ValueListenableBuilder<String?>(
                          valueListenable: selectedCollectionNotifier,
                          builder: (context, selectedCollectionId, child) {
                            debugPrint(
                                'ValueListenableBuilder rebuilt with selection: "$selectedCollectionId"');
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: state.collectionList.length,
                              itemBuilder: (context, index) => _buildCollectionTile(
                                state.collectionList[index],
                                selectedCollectionId,
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.eight),
                ValueListenableBuilder<bool>(
                  valueListenable: btnEnableNotifier,
                  builder: (context, isEnable, _) => BlocBuilder<CollectionBloc, CollectionState>(
                    bloc: _collectionBloc,
                    buildWhen: (previous, current) =>
                        current is ModifyUserCollectionLoadingState ||
                        current is ModifyUserCollectionSuccessState ||
                        current is ModifyUserCollectionErrorState,
                    builder: (context, state) => AppButton(
                      borderRadius: 8.responsiveDimension,
                      title: IsrTranslationFile.done,
                      onPress: _handleDonePress,
                      isDisable: !isEnable,
                      isLoading: state is ModifyUserCollectionLoadingState,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildCollectionTile(
    CollectionData collection,
    String? selectedCollectionId,
  ) {
    final collectionId = collection.id ?? '';

    // Skip rendering if collection has no valid ID
    if (collectionId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelected = selectedCollectionId == collectionId;
    final collectionImage = collection.image?.isNotEmpty == true
        ? collection.image!
        : (collection.previewImages ?? [])
            .firstWhere((img) => img.toString().isNotEmpty, orElse: () => '')
            .toString();

    return Theme(
      data: Theme.of(context).copyWith(splashColor: IsrColors.transparent),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.six),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadiusAll(IsrDimens.four),
        ),
        onChanged: (value) {
          debugPrint('CheckboxListTile tapped! collectionId: "$collectionId", value: $value');
          selectCollection(collectionId);
        },
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Theme.of(context).primaryColor
              : IsrColors.white,
        ),
        side: const BorderSide(color: IsrColors.colorDBDBDB),
        value: isSelected,
        title: GestureDetector(
          onTap: () async {
            await IsrAppNavigator.navigateCollectionDetailsView(
              context,
              collectionData: collection,
            );
          },
          child: Row(
            children: [
              Container(
                height: 50.responsiveDimension,
                width: 50.responsiveDimension,
                decoration: BoxDecoration(
                  color: IsrColors.colorF5F5F5,
                  borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
                ),
                child: collectionImage.isNotEmpty
                    ? AppImage.network(
                        collectionImage,
                        fit: BoxFit.cover,
                        borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
                      )
                    : Padding(
                        padding: IsrDimens.edgeInsetsAll(IsrDimens.ten),
                        child: AppImage.svg(
                          AssetConstants.icEmptyCollection,
                          color: '8B8B8B'.toColor(),
                        ),
                      ),
              ),
              10.responsiveHorizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name ?? '',
                      style: IsrStyles.primaryText14.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(
                      builder: (context) {
                        final baseCount = collection.productIds?.length ?? 0;
                        final additionalCount = _additionalItemsCount[collectionId] ?? 0;
                        final totalCount = baseCount + additionalCount;
                        return Text(
                          '${(collection.isPrivate ?? false) ? IsrTranslationFile.private : IsrTranslationFile.public} • $totalCount ${totalCount <= 1 ? "Item" : "Items"}',
                          style: IsrStyles.primaryText12.copyWith(
                            color: '767676'.toColor(),
                          ),
                        );
                      },
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

  Widget _buildShimmerTile() => CheckboxListTile(
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.six),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: IsrDimens.borderRadiusAll(IsrDimens.four),
        ),
        onChanged: null,
        fillColor: WidgetStateProperty.all(IsrColors.white),
        side: BorderSide(color: IsrColors.colorDBDBDB, width: IsrDimens.two),
        value: false,
        title: Row(
          children: [
            Container(
              height: IsrDimens.thirtyTwo,
              width: IsrDimens.thirtyTwo,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: IsrDimens.borderRadiusAll(IsrDimens.eight),
              ),
            ),
            SizedBox(width: IsrDimens.ten),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: IsrDimens.ten,
                  width: IsrDimens.hundred,
                  color: Colors.white,
                ),
                IsrDimens.boxHeight(IsrDimens.four),
                Container(
                  height: IsrDimens.ten,
                  width: IsrDimens.eighty,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSavedPost() {
    final postId = widget.postId;
    return BlocListener<CollectionBloc, CollectionState>(
      bloc: _collectionBloc,
      listenWhen: (previous, current) =>
          current is SavedPostDataSuccessState || current is SavedPostDataErrorState,
      listener: (context, state) {
        if (state is SavedPostDataSuccessState || state is SavedPostDataErrorState) {
          if (!isSaved) {
            _collectionBloc.add(SavePostActionEvent(postId: postId, isSaved: false));
          }
        }
        if (state is SavePostErrorState) {
          Utility.showToastMessage(state.message);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppImage.network(
                widget.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                height: 50.responsiveDimension,
                width: 50.responsiveDimension,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: IsrDimens.borderRadiusAll(8.responsiveDimension),
              ),
              12.responsiveHorizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    IsrTranslationFile.savedPosts,
                    style: IsrStyles.primaryText12.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.responsiveVerticalSpace,
                  Row(
                    spacing: 4.responsiveDimension,
                    children: [
                      Text(
                        'Private',
                        style: IsrStyles.primaryText10.copyWith(
                          color: '767676'.color,
                        ),
                      ),
                      DotCircle(color: '767676'.color, size: 2.responsiveDimension),
                      ValueListenableBuilder<int>(
                        valueListenable: totalPostNotifier,
                        builder: (context, totalPost, child) =>
                            BlocListener<CollectionBloc, CollectionState>(
                          bloc: _collectionBloc,
                          listenWhen: (previous, current) =>
                              current is SavedPostDataSuccessState ||
                              current is SavePostSuccessState ||
                              current is SavedPostDataErrorState,
                          listener: (context, state) {
                            if (state is SavedPostDataSuccessState) {
                              if (totalPostNotifier.value == 0) {
                                totalPostNotifier.value = state.totalPosts.toInt();
                              }
                            } else if (state is SavePostSuccessState &&
                                state.postId == widget.postId) {
                              final actionKey =
                                  '${state.postId}_${state.socialPostAction}_${DateTime.now().millisecondsSinceEpoch}';

                              if (!_processedSaveActions.contains(actionKey)) {
                                _processedSaveActions.add(actionKey);

                                if (state.socialPostAction == SocialPostAction.save) {
                                  totalPostNotifier.value += 1;
                                } else if (state.socialPostAction == SocialPostAction.unSave) {
                                  totalPostNotifier.value = max(0, totalPostNotifier.value - 1);
                                }

                                if (_processedSaveActions.length > 10) {
                                  _processedSaveActions.clear();
                                }
                              }
                            }
                          },
                          child: BlocBuilder<CollectionBloc, CollectionState>(
                            bloc: _collectionBloc,
                            buildWhen: (previous, current) =>
                                current is SavedPostDataSuccessState ||
                                current is SavePostSuccessState ||
                                current is SavedPostDataLoadingState,
                            builder: (context, state) {
                              if (state is SavedPostDataLoadingState) {
                                return SizedBox(
                                  height: 18.responsiveDimension,
                                  width: 18.responsiveDimension,
                                  child: Padding(
                                    padding: IsrDimens.edgeInsetsAll(IsrDimens.four),
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: IsrDimens.two,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        IsrColors.appColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Text(
                                totalPost == 0
                                    ? 'No items'
                                    : '$totalPost ${totalPost > 1 ? 'items' : 'item'}',
                                style: IsrStyles.primaryText10.copyWith(
                                  color: '767676'.color,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              BlocBuilder<CollectionBloc, CollectionState>(
                bloc: _collectionBloc,
                buildWhen: (previous, current) =>
                    current is SavedPostDataLoadingState ||
                    current is SavedPostDataErrorState ||
                    current is SavedPostDataSuccessState ||
                    current is SavePostLoadingState ||
                    current is SavePostSuccessState ||
                    current is SavePostErrorState,
                builder: (context, state) {
                  if (state is SavedPostDataLoadingState) {
                    return const SizedBox.shrink();
                  }

                  Widget iconContent;
                  if (state is SavePostLoadingState && state.postId == widget.postId) {
                    iconContent = Center(
                      child: SizedBox(
                        height: 16.responsiveDimension,
                        width: 16.responsiveDimension,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: IsrDimens.two,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            IsrColors.appColor,
                          ),
                        ),
                      ),
                    );
                  } else {
                    if (state is SavePostSuccessState && state.postId == widget.postId) {
                      isSaved = state.socialPostAction == SocialPostAction.save;
                    }
                    iconContent = AppImage.svg(
                      height: 24.responsiveDimension,
                      width: 24.responsiveDimension,
                      isSaved
                          ? AssetConstants.icSaveSelectedIcon
                          : AssetConstants.icSaveUnSelectedIcon,
                    );
                  }

                  return IconButton(
                    onPressed: () {
                      _collectionBloc.add(
                        SavePostActionEvent(postId: postId, isSaved: isSaved),
                      );
                    },
                    icon: iconContent,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
