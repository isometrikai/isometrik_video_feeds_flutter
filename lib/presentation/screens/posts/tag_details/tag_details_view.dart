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
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more posts when near bottom
        _tagDetailsBloc.add(GetTagDetailsEvent(
          tagValue: widget.tagValue,
          tagType: widget.tagType,
          isFromPagination: true,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header Section
            _buildHeader(),

            // Tag Profile Section
            _buildTagProfile(),

            // Posts Grid
            Expanded(
              child: BlocBuilder<TagDetailsBloc, TagDetailsState>(
                bloc: _tagDetailsBloc,
                builder: (context, state) {
                  if (state is TagDetailsLoadingState && state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is TagDetailsLoadedState) {
                    if (state.posts.isEmpty) {
                      return _buildEmptyState();
                    } else {
                      return _buildPostsGrid(state.posts);
                    }
                  } else if (state is TagDetailsErrorState) {
                    return _buildErrorState(state.error);
                  }
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildHeader() => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10.responsiveDimension,
          left: 16.responsiveDimension,
          right: 16.responsiveDimension,
          bottom: 16.responsiveDimension,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40.responsiveDimension,
                height: 40.responsiveDimension,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.changeOpacity(0.1),
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
          ],
        ),
      );

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
            BlocBuilder<TagDetailsBloc, TagDetailsState>(
              bloc: _tagDetailsBloc,
              builder: (context, state) {
                var postCount = 0;
                if (state is TagDetailsLoadedState) {
                  postCount = state.posts.length;
                }
                return Text(
                  '$postCount Posts',
                  style: TextStyle(
                    fontSize: 16.responsiveDimension,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      );

  Color _getTagColor() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return const Color(0xFF1E3A8A); // Dark blue for hashtags
      case TagType.place:
        return const Color(0xFF059669); // Green for places
      case TagType.product:
        return const Color(0xFFDC2626); // Red for products
      case TagType.mention:
        return const Color(0xFF7C3AED); // Purple for mentions
    }
  }

  Widget _getTagIcon() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return Text(
          '#',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.responsiveDimension,
            fontWeight: FontWeight.bold,
          ),
        );
      case TagType.place:
        return Icon(
          Icons.location_on,
          color: Colors.white,
          size: 32.responsiveDimension,
        );
      case TagType.product:
        return Icon(
          Icons.shopping_bag,
          color: Colors.white,
          size: 32.responsiveDimension,
        );
      case TagType.mention:
        return Icon(
          Icons.alternate_email,
          color: Colors.white,
          size: 32.responsiveDimension,
        );
    }
  }

  String _getTagDisplayText() {
    switch (widget.tagType) {
      case TagType.hashtag:
        return widget.tagValue.startsWith('#')
            ? widget.tagValue
            : '#${widget.tagValue}';
      case TagType.place:
        return widget.tagValue;
      case TagType.product:
        return widget.tagValue;
      case TagType.mention:
        return widget.tagValue.startsWith('@')
            ? widget.tagValue
            : '@${widget.tagValue}';
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

  Widget _buildPostsGrid(List<TimeLineData> postList) => CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
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
                    return const SizedBox.shrink();
                  }

                  final post = postList[index];
                  return TapHandler(
                    onTap: () => {
                      /// TODO need to check
                      // IsmInjectionUtils.getRouteManagement().goToSocialPostView(
                      //   postDataList: postList,
                      //   startingPostIndex: index,
                      //   postTabType: PostTabType.tagPost,
                      //   tagType: widget.tagType,
                      //   tagValue: widget.tagValue,
                      // ),
                    },
                    child: _buildPostCard(post, index),
                  );
                },
                childCount: postList.length,
              ),
            ),
          ),
        ],
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
              if (post.tags?.products?.isListEmptyOrNull == false)
                _buildProductsOverlay(post),
              if (post.media?.first.mediaType?.mediaType == MediaType.video)
                _buildVideoIcon(),
            ],
          ),
        ),
      );

  Widget _buildPostImage(TimeLineData post) {
    var coverUrl = '';
    if (post.previews.isListEmptyOrNull == false) {
      final previewUrl = post.previews?.first.url ?? '';
      if (previewUrl.isStringEmptyOrNull == false) {
        coverUrl = previewUrl;
      }
    }
    if (coverUrl.isStringEmptyOrNull && post.media.isListEmptyOrNull == false) {
      coverUrl = post.media?.first.mediaType?.mediaType == MediaType.video
          ? (post.media?.first.previewUrl.toString() ?? '')
          : post.media?.first.url.toString() ?? '';
    }

    if (coverUrl.isStringEmptyOrNull) {
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
            color: IsrColors.black.changeOpacity(0.7),
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
              color: IsrColors.black.changeOpacity(0.3),
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
