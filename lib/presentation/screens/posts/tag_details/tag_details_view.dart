import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// A view that displays posts for a specific tag (hashtag, place, product, etc.)
class TagDetailsView extends StatefulWidget {
  const TagDetailsView({
    super.key,
    required this.tagValue,
    required this.tagType,
  });

  final String tagValue;
  final TagType tagType;

  @override
  State<TagDetailsView> createState() => _TagDetailsViewState();
}

class _TagDetailsViewState extends State<TagDetailsView> {
  final _tagDetailsBloc = IsmInjectionUtils.getBloc<TagDetailsBloc>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final List<TimeLineData> _postsList = [];
  final ValueNotifier<int> _postCountNotifier = ValueNotifier<int>(0);
  var _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _setupScrollListener();
  }

  void _loadPosts() {
    _tagDetailsBloc.add(GetTagDetailsEvent(
      tagValue: widget.tagValue,
      tagType: widget.tagType,
      isFromPagination: false,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Check if widget is still mounted and has clients
      if (!mounted || !_scrollController.hasClients) return;

      // Check if scrolled to 65% of the content
      final scrollPercentage =
          _scrollController.position.pixels / _scrollController.position.maxScrollExtent;

      // Trigger pagination at 65% scroll
      if (scrollPercentage >= 0.65 && !_isLoadingMore && _hasMoreData) {
        _loadMorePosts();
      }
    });
  }

  void _loadMorePosts() {
    if (!mounted || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _tagDetailsBloc.add(GetTagDetailsEvent(
      tagValue: widget.tagValue,
      tagType: widget.tagType,
      isFromPagination: true,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Scrollable Content
              BlocConsumer<TagDetailsBloc, TagDetailsState>(
                bloc: _tagDetailsBloc,
                listener: (context, state) {
                  // Reset loading flag when pagination completes
                  if (!mounted) return;

                  if (state is TagDetailsLoadedState || state is TagDetailsErrorState) {
                    if (_isLoadingMore) {
                      setState(() {
                        _isLoadingMore = false;
                      });
                    }
                    if (state is TagDetailsLoadedState) {
                      _hasMoreData = state.hasMoreData;
                      _postsList.clear();
                      _postsList.addAll(state.posts);
                      _postCountNotifier.value = _postsList.length;
                    }
                  }
                },
                builder: (context, state) => CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Tag Profile Section as Sliver
                    SliverToBoxAdapter(
                      child: _buildTagProfile(),
                    ),

                    // Posts Grid Section
                    _buildPostsContent(state),
                  ],
                ),
              ),

              // Fixed Back Button - Always visible
              Positioned(
                top: 10.responsiveDimension,
                left: 16.responsiveDimension,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40.responsiveDimension,
                    height: 40.responsiveDimension,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.applyOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20.responsiveDimension,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPostsContent(TagDetailsState state) {
    if (state is TagDetailsLoadingState && state.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (state is TagDetailsErrorState) {
      return SliverFillRemaining(
        child: _buildErrorState(state.error),
      );
    }
    if (_postsList.isEmptyOrNull) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    } else {
      return _buildPostsSliverGrid(_postsList);
    }
  }

  Widget _buildTagProfile() => Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.responsiveDimension,
          vertical: 24.responsiveDimension,
        ),
        child: Column(
          children: [
            // Tag Icon
            const AppImage.svg(AssetConstants.icHashTagIcon),

            SizedBox(height: 16.responsiveDimension),

            // Tag Text
            Text(
              _getTagDisplayText(),
              style: TextStyle(
                fontSize: 24.responsiveDimension,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8.responsiveDimension),

            // Posts Count
            ValueListenableBuilder<int>(
              valueListenable: _postCountNotifier,
              builder: (context, value, child) => Text(
                '$value Posts',
                style: TextStyle(
                  fontSize: 16.responsiveDimension,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  String _getTagDisplayText() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return widget.tagValue.startsWith('#') ? widget.tagValue : '#${widget.tagValue}';
      case TagType.place:
        return widget.tagValue;
      case TagType.product:
        return widget.tagValue;
      case TagType.mention:
        return widget.tagValue.startsWith('@') ? widget.tagValue : '@${widget.tagValue}';
    }
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(),
              size: 64.responsiveDimension,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.responsiveDimension),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16.responsiveDimension,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.responsiveDimension),
            Text(
              _getEmptyStateDescription(),
              style: TextStyle(
                fontSize: 14.responsiveDimension,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  IconData _getEmptyStateIcon() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return Icons.tag;
      case TagType.place:
        return Icons.location_off;
      case TagType.product:
        return Icons.shopping_bag_outlined;
      case TagType.mention:
        return Icons.alternate_email;
    }
  }

  String _getEmptyStateMessage() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return 'No posts found';
      case TagType.place:
        return 'No posts found';
      case TagType.product:
        return 'No posts found';
      case TagType.mention:
        return 'No posts found';
    }
  }

  String _getEmptyStateDescription() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return 'Be the first to post with this hashtag!';
      case TagType.place:
        return 'No posts have been tagged with this location yet.';
      case TagType.product:
        return 'No posts have been tagged with this product yet.';
      case TagType.mention:
        return 'No posts have mentioned this user yet.';
    }
  }

  Widget _buildPostsSliverGrid(List<TimeLineData> postList) => SliverPadding(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns as shown in design
            crossAxisSpacing: IsrDimens.four,
            mainAxisSpacing: IsrDimens.four,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == postList.length) {
                return _isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final post = postList[index];
              return TapHandler(
                key: ValueKey('post_${post.id}'),
                onTap: () {
                  IsrAppNavigator.navigateToReelsPlayer(
                    context,
                    postDataList: postList,
                    startingPostIndex: index,
                    postSectionType: PostSectionType.tagPost,
                    tagValue: widget.tagValue,
                    tagType: widget.tagType,
                  );
                },
                child: _buildPostCard(post, index),
              );
            },
            childCount: postList.length + (_isLoadingMore ? 1 : 0),
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
          ),
        ),
      );

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
              if (post.tags?.products?.isEmptyOrNull == false) _buildProductsOverlay(post),
              if (post.media?.first.mediaType?.mediaType == MediaType.video) _buildVideoIcon(),
            ],
          ),
        ),
      );

  Widget _buildPostImage(TimeLineData post) {
    var coverUrl = '';
    if (post.previews.isEmptyOrNull == false) {
      final previewUrl = post.previews?.first.url ?? '';
      if (previewUrl.isEmptyOrNull == false) {
        coverUrl = previewUrl;
      }
    }
    if (coverUrl.isEmptyOrNull && post.media.isEmptyOrNull == false) {
      coverUrl = post.media?.first.mediaType?.mediaType == MediaType.video
          ? (post.media?.first.previewUrl.toString() ?? '')
          : post.media?.first.url.toString() ?? '';
    }

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

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.responsiveDimension,
              color: Colors.red[400],
            ),
            SizedBox(height: 16.responsiveDimension),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16.responsiveDimension,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.responsiveDimension),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.responsiveDimension,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.responsiveDimension),
            ElevatedButton(
              onPressed: () {
                _tagDetailsBloc.add(RefreshTagDetailsEvent(
                  tagValue: widget.tagValue,
                  tagType: widget.tagType,
                ));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
