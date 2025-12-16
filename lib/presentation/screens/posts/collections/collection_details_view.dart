import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// A comprehensive view for displaying and managing collection details
///
/// This widget provides a full-screen interface for viewing collection contents,
/// including posts. It supports editing and deletion operations for self-owned
/// collections.
class CollectionDetailsView extends StatefulWidget {
  CollectionDetailsView({
    Key? key,
    required this.collectionData,
  }) : super(key: key);

  /// The collection model containing all collection details
  CollectionData collectionData;

  @override
  State<CollectionDetailsView> createState() => _CollectionDetailsViewState();
}

class _CollectionDetailsViewState extends State<CollectionDetailsView> {
  /// Bloc for handling collection operations
  late final CollectionBloc _collectionBloc;

  /// Number of items to fetch per page
  static const int _pageSize = 20;

  /// Current page for pagination
  int _currentPage = 1;

  /// The current collection being displayed
  CollectionData? collection;

  /// ID of the current collection
  String? collectionId;

  /// List of posts in the collection
  List<TimeLineData> _posts = [];

  /// Total posts count
  int _totalPosts = 0;

  /// Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _collectionBloc = IsmInjectionUtils.getBloc<CollectionBloc>();
    _initializeCollection();
  }

  /// Initializes the collection data and loads content
  void _initializeCollection() {
    collectionId = widget.collectionData.id;
    collection = widget.collectionData;
    _loadCollectionPosts();
  }

  /// Load posts for the collection
  void _loadCollectionPosts() {
    if (collectionId == null || collectionId!.isEmpty) return;
    _collectionBloc.add(GetCollectionPostsEvent(
      collectionId: collectionId!,
      page: _currentPage,
      pageSize: _pageSize,
    ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CollectionBloc, CollectionState>(
        bloc: _collectionBloc,
        listener: _handleBlocState,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => _handlePopResult(didPop),
          child: Scaffold(
            appBar: _buildCollectionAppBar(),
            body: _buildCollectionBody(),
          ),
        ),
      );

  /// Handles bloc state changes
  void _handleBlocState(BuildContext context, CollectionState state) {
    if (state is GetCollectionPostsLoadingState) {
      setState(() => _isLoading = true);
    } else if (state is GetCollectionPostsSuccessState) {
      setState(() {
        _isLoading = false;
        _posts = state.posts;
        _totalPosts = state.totalPosts;
      });
    } else if (state is GetCollectionPostsErrorState) {
      setState(() => _isLoading = false);
      Utility.showToastMessage(state.error);
    } else if (state is DeleteCollectionLoadingState) {
      Utility.showLoader();
    } else if (state is DeleteCollectionSuccessState) {
      Utility.closeProgressDialog();
      Utility.showToastMessage(state.message);
      _collectionBloc.add(GetUserCollectionEvent(
        limit: 20,
        skip: 1,
      ));
      Future.delayed(const Duration(milliseconds: 500), () {
        context.pop(collection);
      });
    } else if (state is DeleteCollectionErrorState) {
      Utility.closeProgressDialog();
      Utility.showToastMessage(state.error);
    } else if (state is RemovePostFromCollectionSuccessState) {
      Utility.closeProgressDialog();
      Utility.showToastMessage('Post removed successfully');
      setState(() {
        _posts.removeWhere((post) => post.id == state.postId);
        _totalPosts = _posts.length;
      });
    } else if (state is RemovePostFromCollectionErrorState) {
      Utility.closeProgressDialog();
      Utility.showToastMessage(state.error);
    }
  }

  /// Handles pop result and returns collection data
  void _handlePopResult(bool didPop) {
    if (!didPop) {
      context.pop(collection);
    }
  }

  /// Builds the collection body with loading states
  Widget _buildCollectionBody() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: AppLoader(loaderType: LoaderType.normal),
      );
    }
    return _buildBody();
  }

  /// Builds the app bar with collection actions
  PreferredSizeWidget _buildCollectionAppBar() => IsmCustomAppBarWidget(
        backgroundColor: IsrColors.white,
        titleText: collection?.name ?? '',
        isBackButtonVisible: true,
        onTap: () => context.pop(collection),
        showDivider: true,
        centerTitle: false,
        showTitleWidget: false,
        showActions: true,
        actions: [_buildAppBarActions()],
      );

  /// Builds the app bar action buttons
  Widget _buildAppBarActions() => Padding(
        padding:
            IsrDimens.edgeInsetsSymmetric(horizontal: 8.responsiveDimension),
        child: Row(
          spacing: 12.responsiveDimension,
          children: [
            if (!(collection?.isPrivate ?? true)) _buildShareButton(),
            _buildMoreOptionsMenu(),
          ],
        ),
      );

  /// Builds the share button for public collections
  Widget _buildShareButton() => TapHandler(
        onTap: _handleShareCollection,
        child: AppImage.svg(
          AssetConstants.icShareIconSvg,
          width: 24.responsiveDimension,
        ),
      );

  /// Handles collection sharing
  Future<void> _handleShareCollection() async {
    // Implement share functionality
    Utility.showToastMessage('Share functionality');
  }

  /// Builds the more options menu
  Widget _buildMoreOptionsMenu() => PopupMenuButton<String>(
        padding: IsrDimens.edgeInsetsAll(0),
        icon: Icon(
          Icons.more_vert,
          color: IsrColors.black,
          size: 24.responsiveDimension,
        ),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          visualDensity: VisualDensity.compact,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        elevation: 4,
        offset: Offset(0, 30.responsiveDimension),
        itemBuilder: (BuildContext context) => [
          _buildPopupMenuItem(
            label: IsrTranslationFile.editCollection,
            onTap: _handleEditCollection,
          ),
          _buildDividerForMenu(),
          _buildPopupMenuItem(
            label: 'Delete Collection',
            onTap: _handleDeleteCollection,
          ),
        ],
      );

  /// Builds a popup menu item
  PopupMenuItem<String> _buildPopupMenuItem({
    required String label,
    required Function() onTap,
  }) =>
      PopupMenuItem<String>(
        onTap: onTap,
        child: Text(
          label,
          style: IsrStyles.primaryText12.copyWith(
            fontWeight: FontWeight.w500,
            color: IsrColors.color333333,
          ),
        ),
      );

  /// Builds a divider for the popup menu
  PopupMenuItem<String> _buildDividerForMenu() => const PopupMenuItem(
        enabled: false,
        height: 1,
        child: Divider(
          height: 1,
          thickness: 1,
          color: IsrColors.colorDBDBDB,
        ),
      );

  /// Builds the main body of the collection details view
  Widget _buildBody() => Material(
        color: IsrColors.white,
        child: RefreshIndicator(
          backgroundColor: IsrColors.white,
          onRefresh: _refreshPage,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildCollectionHeader()),
              _buildPostsSliverGrid(),
            ],
          ),
        ),
      );

  /// Refreshes the collection details by fetching updated data
  Future<void> _refreshPage() async {
    _currentPage = 1;
    _loadCollectionPosts();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Gets collection cover image
  String _getCollectionCoverImage() {
    if (collection?.image?.isNotEmpty == true) {
      return collection!.image!;
    }
    if (collection?.previewImages?.isNotEmpty == true) {
      return collection!.previewImages!.first.toString();
    }
    if (_posts.isNotEmpty) {
      return _getThumbnailUrl(_posts.first);
    }
    return '';
  }

  /// Builds the header section of the collection
  Widget _buildCollectionHeader() {
    final coverImage = _getCollectionCoverImage();

    return Container(
      padding: IsrDimens.edgeInsetsAll(16.responsiveDimension),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection cover with info overlay - always show this style
          Container(
            height: 200.responsiveDimension,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: IsrDimens.borderRadiusAll(16.responsiveDimension),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.changeOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: IsrDimens.borderRadiusAll(16.responsiveDimension),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background - image or gradient placeholder
                  if (coverImage.isNotEmpty)
                    AppImage.network(
                      coverImage,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.changeOpacity(0.8),
                            Theme.of(context).primaryColor.changeOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: AppImage.svg(
                          AssetConstants.icEmptyCollection,
                          height: 60.responsiveDimension,
                          width: 60.responsiveDimension,
                          color: Colors.white.changeOpacity(0.5),
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.changeOpacity(0.1),
                          Colors.black.changeOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Edit & Delete buttons at top right
                  Positioned(
                    top: 12.responsiveDimension,
                    right: 12.responsiveDimension,
                    child: Row(
                      children: [
                        _buildHeaderActionButton(
                          icon: Icons.edit_outlined,
                          onTap: _handleEditCollection,
                        ),
                        8.responsiveHorizontalSpace,
                        _buildHeaderActionButton(
                          icon: Icons.delete_outline,
                          onTap: _handleDeleteCollection,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  // Info on cover
                  Positioned(
                    left: 16.responsiveDimension,
                    right: 16.responsiveDimension,
                    bottom: 16.responsiveDimension,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collection?.name ?? '',
                          style: IsrStyles.primaryText18.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        8.responsiveVerticalSpace,
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: collection?.isPrivate ?? false
                                  ? Icons.lock_outline
                                  : Icons.public,
                              label: collection?.isPrivate ?? false
                                  ? IsrTranslationFile.private
                                  : IsrTranslationFile.public,
                            ),
                            10.responsiveHorizontalSpace,
                            _buildInfoChip(
                              icon: Icons.grid_view_rounded,
                              label:
                                  '$_totalPosts ${_totalPosts == 1 ? 'Item' : 'Items'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Description section
          if (collection?.description?.isNotEmpty ?? false) ...[
            12.responsiveVerticalSpace,
            Container(
              width: double.infinity,
              padding: IsrDimens.edgeInsetsAll(12.responsiveDimension),
              decoration: BoxDecoration(
                color: 'F8F9FA'.toColor(),
                borderRadius: IsrDimens.borderRadiusAll(12.responsiveDimension),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18.responsiveDimension,
                    color: '9CA3AF'.toColor(),
                  ),
                  8.responsiveHorizontalSpace,
                  Expanded(
                    child: Text(
                      collection?.description ?? '',
                      style: IsrStyles.primaryText12.copyWith(
                        color: '4B5563'.toColor(),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          16.responsiveVerticalSpace,
          // Section title
          Row(
            children: [
              Container(
                width: 4.responsiveDimension,
                height: 20.responsiveDimension,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius:
                      IsrDimens.borderRadiusAll(2.responsiveDimension),
                ),
              ),
              8.responsiveHorizontalSpace,
              Text(
                'Posts',
                style: IsrStyles.primaryText16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: '1F2937'.toColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds action button for header (edit/delete)
  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) =>
      TapHandler(
        onTap: onTap,
        child: Container(
          padding: IsrDimens.edgeInsetsAll(8.responsiveDimension),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.changeOpacity(0.9)
                : Colors.white.changeOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.changeOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18.responsiveDimension,
            color: isDestructive ? Colors.white : IsrColors.color333333,
          ),
        ),
      );

  /// Builds info chip for header
  Widget _buildInfoChip({required IconData icon, required String label}) =>
      Container(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: 10.responsiveDimension,
          vertical: 6.responsiveDimension,
        ),
        decoration: BoxDecoration(
          color: Colors.white.changeOpacity(0.2),
          borderRadius: IsrDimens.borderRadiusAll(20.responsiveDimension),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.responsiveDimension,
              color: Colors.white,
            ),
            4.responsiveHorizontalSpace,
            Text(
              label,
              style: IsrStyles.primaryText12.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  /// Builds the posts sliver grid section
  Widget _buildPostsSliverGrid() {
    if (_posts.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyCollectionPlaceholder());
    }

    return SliverPadding(
      padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: IsrDimens.four,
          mainAxisSpacing: IsrDimens.four,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = _posts[index];
            return TapHandler(
              key: ValueKey('post_${post.id}'),
              onTap: () {
                // Navigate to post detail
              },
              onLongPress: () => _showPostOptions(post),
              child: _buildPostCard(post, index),
            );
          },
          childCount: _posts.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  /// Gets the thumbnail URL from TimeLineData
  String _getThumbnailUrl(TimeLineData post) {
    // Try to get from previews first
    if (post.previews.isEmptyOrNull == false) {
      final previewUrl = post.previews?.first.url ?? '';
      if (previewUrl.isEmptyOrNull == false) {
        return previewUrl;
      }
    }
    // Try to get from media
    if (post.media.isEmptyOrNull == false) {
      return post.media?.first.mediaType?.mediaType == MediaType.video
          ? (post.media?.first.previewUrl.toString() ?? '')
          : post.media?.first.url.toString() ?? '';
    }
    return '';
  }

  /// Builds a post card - same style as tag_details_view
  Widget _buildPostCard(TimeLineData post, int index) => Container(
        decoration: BoxDecoration(
          color: IsrColors.white,
          borderRadius: BorderRadius.circular(8.responsiveDimension),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.responsiveDimension),
          child: Stack(
            children: [
              _buildPostImage(post),
              if (post.tags?.products?.isEmptyOrNull == false)
                _buildProductsOverlay(post),
              if (post.media?.first.mediaType?.mediaType == MediaType.video)
                _buildVideoIcon(),
            ],
          ),
        ),
      );

  /// Builds the post image
  Widget _buildPostImage(TimeLineData post) {
    final coverUrl = _getThumbnailUrl(post);

    if (coverUrl.isEmptyOrNull) {
      return Container(
        color: IsrColors.colorF5F5F5,
        child: Icon(
          Icons.image,
          color: IsrColors.color9B9B9B,
          size: IsrDimens.forty,
        ),
      );
    }

    return AppImage.network(
      coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      showError: true,
    );
  }

  /// Builds the products overlay at the bottom of post card
  Widget _buildProductsOverlay(TimeLineData post) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.eight,
            vertical: IsrDimens.four,
          ),
          decoration: BoxDecoration(
            color: IsrColors.black.applyOpacity(0.7),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8.responsiveDimension),
              bottomRight: Radius.circular(8.responsiveDimension),
            ),
          ),
          child: Text(
            '${post.tags?.products?.length ?? 0} Products',
            style: IsrStyles.primaryText10.copyWith(
              color: IsrColors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

  /// Builds the video play icon overlay
  Widget _buildVideoIcon() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Center(
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            decoration: BoxDecoration(
              color: IsrColors.black.applyOpacity(0.3),
              borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
            ),
            child: Icon(
              Icons.play_arrow,
              color: IsrColors.white,
              size: IsrDimens.twentyFour,
            ),
          ),
        ),
      );

  /// Shows post options (remove from collection)
  void _showPostOptions(TimeLineData post) {
    Utility.showBottomSheet(
      child: Container(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                IsrTranslationFile.removeFromCollection,
                style: IsrStyles.primaryText14.copyWith(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                _removePostFromCollection(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Removes a post from the collection
  void _removePostFromCollection(TimeLineData post) {
    Utility.showLoader();
    _collectionBloc.add(RemovePostFromCollectionEvent(
      collectionId: collectionId ?? '',
      postId: post.id ?? '',
    ));
  }

  /// Builds the empty collection placeholder
  Widget _buildEmptyCollectionPlaceholder() => Container(
        padding: IsrDimens.edgeInsetsAll(40.responsiveDimension),
        margin:
            IsrDimens.edgeInsetsSymmetric(horizontal: 16.responsiveDimension),
        decoration: BoxDecoration(
          color: 'F9FAFB'.toColor(),
          borderRadius: IsrDimens.borderRadiusAll(16.responsiveDimension),
          border: Border.all(
            color: 'E5E7EB'.toColor(),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: IsrDimens.edgeInsetsAll(20.responsiveDimension),
                decoration: BoxDecoration(
                  color: 'EEF2FF'.toColor(),
                  shape: BoxShape.circle,
                ),
                child: AppImage.svg(
                  AssetConstants.icEmptyCollection,
                  height: 48.responsiveDimension,
                  width: 48.responsiveDimension,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              20.responsiveVerticalSpace,
              Text(
                'No posts yet',
                style: IsrStyles.primaryText16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: '1F2937'.toColor(),
                ),
                textAlign: TextAlign.center,
              ),
              8.responsiveVerticalSpace,
              Text(
                'Start adding posts to\nthis collection',
                style: IsrStyles.primaryText14.copyWith(
                  color: '6B7280'.toColor(),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// Handles editing the collection
  Future<void> _handleEditCollection() async {
    await Utility.showCustomizedBottomSheet(
      isRoundedCorners: false,
      isScrollControlled: true,
      child: BlocProvider<CollectionBloc>(
        create: (context) => IsmInjectionUtils.getBloc<CollectionBloc>(),
        child: CreateCollectionView(
          collection: collection,
          defaultCollectionImage: collection?.image ?? '',
        ),
      ),
    );
    await _refreshPage();
  }

  /// Handles deleting the collection
  Future<void> _handleDeleteCollection() async {
    await Utility.showBottomSheet(
      child: Container(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Collection',
              style:
                  IsrStyles.primaryText16.copyWith(fontWeight: FontWeight.w600),
            ),
            12.responsiveVerticalSpace,
            Text(
              'Are you sure you want to delete this collection?',
              style: IsrStyles.primaryText14
                  .copyWith(color: IsrColors.color333333),
            ),
            24.responsiveVerticalSpace,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: IsrTranslationFile.cancel,
                    onPress: () => context.pop(),
                    backgroundColor: IsrColors.colorF5F5F5,
                    textColor: IsrColors.black,
                  ),
                ),
                12.responsiveHorizontalSpace,
                Expanded(
                  child: AppButton(
                    title: 'Delete',
                    onPress: () {
                      context.pop();
                      if (collectionId?.isNotEmpty ?? false) {
                        _collectionBloc.add(
                            DeleteCollectionEvent(collectionId: collectionId!));
                      }
                    },
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
